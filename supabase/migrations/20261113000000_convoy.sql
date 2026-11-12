-- =============================================================================
-- Rider Group — Migration 0008 : mode Convoi et positions GPS (Mission 05)
-- -----------------------------------------------------------------------------
-- Règles (cahier des charges §7.3, décision D-35) :
--   * partage GPS VOLONTAIRE, par balade (ride_location_shares) ;
--   * seuls les participants confirmés et les gestionnaires voient les
--     positions, uniquement pendant la balade (statut in_progress) ;
--   * la fin ou l'annulation arrête toute publication (refus serveur) ;
--   * un participant retiré perd l'accès immédiatement (RLS sur son statut) ;
--   * une seule position par personne et par balade (la dernière) :
--     pas d'historique de trajet conservé ;
--   * positions supprimées 72 h après la fin / l'annulation
--     (private.purge_ride_positions, planifiée par pg_cron si disponible) ;
--   * rôles de convoi : chef de convoi (leader) et serre-file (sweeper),
--     désignés par les gestionnaires parmi les participants confirmés.
--
-- Codes d'erreur : ride_not_in_progress, sharing_disabled, not_participant,
-- not_allowed, invalid_input, too_frequent
-- =============================================================================

create type public.convoy_role as enum ('leader', 'sweeper');

create table public.ride_role_assignments (
  ride_id     uuid not null references public.rides (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  role        public.convoy_role not null,
  assigned_by uuid references public.profiles (id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (ride_id, role)
);
create index ride_role_assignments_user_idx on public.ride_role_assignments (user_id);
create index ride_role_assignments_assigned_by_idx on public.ride_role_assignments (assigned_by);

create table public.ride_location_shares (
  ride_id     uuid not null references public.rides (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  enabled     boolean not null,
  updated_at  timestamptz not null default now(),
  primary key (ride_id, user_id)
);
create index ride_location_shares_user_idx on public.ride_location_shares (user_id);

create table public.ride_positions (
  ride_id      uuid not null references public.rides (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  lat          double precision not null check (lat between -90 and 90),
  lng          double precision not null check (lng between -180 and 180),
  accuracy_m   real check (accuracy_m is null or accuracy_m between 0 and 10000),
  heading_deg  real check (heading_deg is null or heading_deg between 0 and 360),
  speed_mps    real check (speed_mps is null or speed_mps between 0 and 120),
  recorded_at  timestamptz not null,
  received_at  timestamptz not null default now(),
  primary key (ride_id, user_id)
);
create index ride_positions_user_idx on public.ride_positions (user_id);

-- -----------------------------------------------------------------------------
-- Accès
-- -----------------------------------------------------------------------------
create or replace function private.can_view_ride_positions(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.rides r
                  where r.id = p_ride_id and r.status = 'in_progress')
     and (private.is_ride_participant(p_ride_id) or private.can_manage_ride(p_ride_id));
$$;
grant execute on function private.can_view_ride_positions(uuid) to authenticated;

alter table public.ride_role_assignments enable row level security;
alter table public.ride_location_shares enable row level security;
alter table public.ride_positions enable row level security;
revoke all on public.ride_role_assignments, public.ride_location_shares, public.ride_positions
  from anon, authenticated;
grant select on public.ride_role_assignments, public.ride_location_shares, public.ride_positions
  to authenticated;

create policy "ride_role_assignments: visibles par qui voit les participants"
  on public.ride_role_assignments for select to authenticated
  using (private.can_view_ride_participants(ride_id));

create policy "ride_location_shares: soi-même"
  on public.ride_location_shares for select to authenticated
  using (user_id = (select auth.uid()));

create policy "ride_positions: participants confirmés pendant la balade"
  on public.ride_positions for select to authenticated
  using (private.can_view_ride_positions(ride_id));

-- -----------------------------------------------------------------------------
-- Fonctions serveur
-- -----------------------------------------------------------------------------
create or replace function public.set_location_sharing(p_ride_id uuid, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.is_ride_participant(p_ride_id) then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  insert into public.ride_location_shares (ride_id, user_id, enabled, updated_at)
  values (p_ride_id, uid, p_enabled, now())
  on conflict (ride_id, user_id) do update set enabled = excluded.enabled, updated_at = now();
  if not p_enabled then
    -- Arrêt du partage : la dernière position disparaît immédiatement.
    delete from public.ride_positions where ride_id = p_ride_id and user_id = uid;
  end if;
end;
$$;

create or replace function public.publish_position(
  p_ride_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_recorded_at timestamptz,
  p_accuracy_m real default null,
  p_heading_deg real default null,
  p_speed_mps real default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  last_received timestamptz;
begin
  if not exists (select 1 from public.rides where id = p_ride_id and status = 'in_progress') then
    raise exception 'ride_not_in_progress' using errcode = 'P0001';
  end if;
  if not private.is_ride_participant(p_ride_id) then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  if not coalesce((select enabled from public.ride_location_shares
                    where ride_id = p_ride_id and user_id = uid), false) then
    raise exception 'sharing_disabled' using errcode = 'P0001';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90
     or p_lng not between -180 and 180 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  -- Horodatage plausible : ni futur, ni plus vieux que 10 minutes.
  if p_recorded_at > now() + interval '1 minute' or p_recorded_at < now() - interval '10 minutes' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  -- Fréquence maîtrisée : au plus une écriture toutes les 3 secondes.
  select received_at into last_received from public.ride_positions
   where ride_id = p_ride_id and user_id = uid;
  if last_received is not null and last_received > now() - interval '3 seconds' then
    raise exception 'too_frequent' using errcode = 'P0001';
  end if;

  begin
    insert into public.ride_positions
      (ride_id, user_id, lat, lng, accuracy_m, heading_deg, speed_mps, recorded_at, received_at)
    values (p_ride_id, uid, p_lat, p_lng, p_accuracy_m, p_heading_deg, p_speed_mps, p_recorded_at, now())
    on conflict (ride_id, user_id) do update
      set lat = excluded.lat, lng = excluded.lng, accuracy_m = excluded.accuracy_m,
          heading_deg = excluded.heading_deg, speed_mps = excluded.speed_mps,
          recorded_at = excluded.recorded_at, received_at = now()
      where public.ride_positions.recorded_at <= excluded.recorded_at;
  exception when check_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;
end;
$$;

create or replace function public.set_convoy_role(
  p_ride_id uuid, p_role public.convoy_role, p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.can_manage_ride(p_ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.rides where id = p_ride_id and status in ('finished', 'cancelled')) then
    raise exception 'ride_not_editable' using errcode = 'P0001';
  end if;
  if p_user_id is null then
    delete from public.ride_role_assignments where ride_id = p_ride_id and role = p_role;
  else
    if not exists (select 1 from public.ride_participants
                    where ride_id = p_ride_id and user_id = p_user_id and status = 'confirmed') then
      raise exception 'not_participant' using errcode = 'P0001';
    end if;
    insert into public.ride_role_assignments (ride_id, user_id, role, assigned_by)
    values (p_ride_id, p_user_id, p_role, uid)
    on conflict (ride_id, role) do update
      set user_id = excluded.user_id, assigned_by = uid, assigned_at = now();
  end if;
  perform private.log_action('ride.convoy_role', 'ride', p_ride_id,
    jsonb_build_object('role', p_role, 'user_id', p_user_id));
end;
$$;

-- Un participant retiré ou parti perd son rôle et sa position.
create or replace function private.cleanup_convoy_on_leave()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status <> 'confirmed' and old.status = 'confirmed' then
    delete from public.ride_role_assignments where ride_id = new.ride_id and user_id = new.user_id;
    delete from public.ride_positions where ride_id = new.ride_id and user_id = new.user_id;
    update public.ride_location_shares set enabled = false, updated_at = now()
     where ride_id = new.ride_id and user_id = new.user_id;
  end if;
  return null;
end;
$$;
create trigger ride_participants_convoy_cleanup
  after update of status on public.ride_participants
  for each row execute function private.cleanup_convoy_on_leave();

-- Rétention (D-35) : 72 h après la fin ou l'annulation.
create or replace function private.purge_ride_positions()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  delete from public.ride_positions p
   using public.rides r
   where r.id = p.ride_id
     and r.status in ('finished', 'cancelled')
     and coalesce(r.finished_at, r.cancelled_at, r.updated_at) < now() - interval '72 hours';
  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function
  private.cleanup_convoy_on_leave(),
  private.purge_ride_positions()
from public, anon, authenticated;

grant execute on function
  public.set_location_sharing(uuid, boolean),
  public.publish_position(uuid, double precision, double precision, timestamptz, real, real, real),
  public.set_convoy_role(uuid, public.convoy_role, uuid)
to authenticated;

-- Temps réel (Supabase Realtime applique la RLS ci-dessus) et purge planifiée,
-- seulement si l'environnement les fournit (projet Supabase réel).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.ride_positions;
  end if;
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('rider-purge-ride-positions', '17 * * * *',
                          'select private.purge_ride_positions()');
  end if;
end;
$$;
