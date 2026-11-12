-- =============================================================================
-- Rider Group — Migration 0009 : assistance et SOS (Mission 06)
-- -----------------------------------------------------------------------------
-- Cahier des charges §8, décisions D-38 à D-40 :
--   * alerte MANUELLE : panne, accident, demande d'assistance, retard ;
--   * pendant une balade en cours, par un participant confirmé ou un
--     gestionnaire ; destinataires : participants confirmés et gestionnaires
--     de cette balade (D-39) ;
--   * envoi idempotent (client_ref) : l'application peut renvoyer sans
--     créer de doublon ; une alerte n'existe que si le serveur l'a acceptée
--     (critère 12 : jamais « envoyée » sans transmission réelle) ;
--   * dernière position : celle de l'appareil, sinon la dernière position
--     du mode Convoi ;
--   * accusés de réception par les destinataires ;
--   * clôture : l'auteur annule ou résout ; un gestionnaire peut résoudre ;
--   * coordonnées effacées 72 h après la fin de la balade (comme D-35),
--     l'alerte elle-même reste dans l'historique de la balade.
--
-- Codes d'erreur : ride_not_in_progress, not_participant, not_allowed,
-- invalid_input, rate_limited, alert_closed, own_alert
-- =============================================================================

create type public.sos_kind as enum ('breakdown', 'accident', 'assistance', 'delay');
create type public.sos_status as enum ('active', 'resolved', 'cancelled');

create table public.sos_alerts (
  id                   uuid primary key default gen_random_uuid(),
  ride_id              uuid not null references public.rides (id) on delete cascade,
  user_id              uuid not null references public.profiles (id) on delete cascade,
  client_ref           uuid not null,
  kind                 public.sos_kind not null,
  status               public.sos_status not null default 'active',
  message              text check (message is null or char_length(message) <= 280),
  lat                  double precision check (lat is null or lat between -90 and 90),
  lng                  double precision check (lng is null or lng between -180 and 180),
  accuracy_m           real check (accuracy_m is null or accuracy_m between 0 and 10000),
  position_recorded_at timestamptz,
  position_source      text check (position_source in ('device', 'convoy')),
  created_at           timestamptz not null default now(),
  closed_at            timestamptz,
  closed_by            uuid references public.profiles (id) on delete set null,
  close_note           text check (close_note is null or char_length(close_note) <= 280),
  constraint sos_alerts_position_pair check ((lat is null) = (lng is null)),
  constraint sos_alerts_closed_consistency check ((status = 'active') = (closed_at is null)),
  unique (user_id, client_ref)
);
create index sos_alerts_ride_idx on public.sos_alerts (ride_id, created_at desc);
create index sos_alerts_active_idx on public.sos_alerts (status) where status = 'active';
create index sos_alerts_closed_by_idx on public.sos_alerts (closed_by);

create table public.sos_acknowledgements (
  alert_id   uuid not null references public.sos_alerts (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  -- Copie de la balade : permet le filtre temps réel par balade.
  ride_id    uuid not null references public.rides (id) on delete cascade,
  acked_at   timestamptz not null default now(),
  primary key (alert_id, user_id)
);
create index sos_acknowledgements_user_idx on public.sos_acknowledgements (user_id);
create index sos_acknowledgements_ride_idx on public.sos_acknowledgements (ride_id);

-- -----------------------------------------------------------------------------
-- Accès
-- -----------------------------------------------------------------------------
create or replace function private.can_view_ride_sos(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_ride_participant(p_ride_id) or private.can_manage_ride(p_ride_id);
$$;
grant execute on function private.can_view_ride_sos(uuid) to authenticated;

alter table public.sos_alerts enable row level security;
alter table public.sos_acknowledgements enable row level security;
revoke all on public.sos_alerts, public.sos_acknowledgements from anon, authenticated;
grant select on public.sos_alerts, public.sos_acknowledgements to authenticated;

create policy "sos_alerts: auteur et participants de la balade"
  on public.sos_alerts for select to authenticated
  using (user_id = (select auth.uid()) or private.can_view_ride_sos(ride_id));

create policy "sos_acknowledgements: participants de la balade"
  on public.sos_acknowledgements for select to authenticated
  using (user_id = (select auth.uid()) or private.can_view_ride_sos(ride_id));

-- -----------------------------------------------------------------------------
-- Fonctions serveur
-- -----------------------------------------------------------------------------
create or replace function public.raise_sos(
  p_ride_id uuid,
  p_kind public.sos_kind,
  p_client_ref uuid,
  p_message text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_recorded_at timestamptz default null,
  p_accuracy_m real default null
)
returns public.sos_alerts
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing public.sos_alerts;
  created public.sos_alerts;
  pos record;
  v_lat double precision := p_lat;
  v_lng double precision := p_lng;
  v_acc real := p_accuracy_m;
  v_at timestamptz := p_recorded_at;
  v_source text;
begin
  if p_client_ref is null or p_kind is null then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  -- Renvoi d'une alerte déjà reçue (réseau instable) : même réponse.
  select * into existing from public.sos_alerts
   where user_id = uid and client_ref = p_client_ref;
  if found then
    if existing.ride_id <> p_ride_id then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
    return existing;
  end if;

  if not exists (select 1 from public.rides where id = p_ride_id and status = 'in_progress') then
    raise exception 'ride_not_in_progress' using errcode = 'P0001';
  end if;
  if not (private.is_ride_participant(p_ride_id) or private.can_manage_ride(p_ride_id)) then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  if (select count(*) from public.sos_alerts
       where user_id = uid and created_at > now() - interval '10 minutes') >= 5 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  if (v_lat is null) <> (v_lng is null)
     or (v_lat is not null and (v_lat not between -90 and 90 or v_lng not between -180 and 180))
     or (v_at is not null and v_at > now() + interval '1 minute') then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  if v_lat is not null then
    v_source := 'device';
  else
    -- Repli : dernière position partagée en mode Convoi.
    select lat, lng, accuracy_m, recorded_at into pos
      from public.ride_positions where ride_id = p_ride_id and user_id = uid;
    if found then
      v_lat := pos.lat; v_lng := pos.lng; v_acc := pos.accuracy_m;
      v_at := pos.recorded_at; v_source := 'convoy';
    else
      v_acc := null; v_at := null;
    end if;
  end if;

  begin
    insert into public.sos_alerts
      (ride_id, user_id, client_ref, kind, message, lat, lng, accuracy_m,
       position_recorded_at, position_source)
    values
      (p_ride_id, uid, p_client_ref, p_kind, nullif(btrim(p_message), ''), v_lat, v_lng, v_acc,
       v_at, v_source)
    returning * into created;
  exception when check_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;

  perform private.log_action('sos.raise', 'sos_alert', created.id,
    jsonb_build_object('ride_id', p_ride_id, 'kind', p_kind));
  return created;
end;
$$;

create or replace function public.acknowledge_sos(p_alert_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  alert public.sos_alerts;
begin
  select * into alert from public.sos_alerts where id = p_alert_id;
  if not found or not private.can_view_ride_sos(alert.ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if alert.user_id = uid then
    raise exception 'own_alert' using errcode = 'P0001';
  end if;
  if alert.status <> 'active' then
    raise exception 'alert_closed' using errcode = 'P0001';
  end if;
  insert into public.sos_acknowledgements (alert_id, user_id, ride_id)
  values (alert.id, uid, alert.ride_id)
  on conflict (alert_id, user_id) do nothing;
end;
$$;

create or replace function public.close_sos(
  p_alert_id uuid, p_status public.sos_status, p_note text default null
)
returns public.sos_alerts
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  alert public.sos_alerts;
begin
  if p_status is null or p_status = 'active'
     or (p_note is not null and char_length(p_note) > 280) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select * into alert from public.sos_alerts where id = p_alert_id for update;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  -- L'auteur annule ou résout ; un gestionnaire de la balade peut résoudre.
  if not (alert.user_id = uid
          or (p_status = 'resolved' and private.can_manage_ride(alert.ride_id))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if alert.status <> 'active' then
    raise exception 'alert_closed' using errcode = 'P0001';
  end if;
  update public.sos_alerts
     set status = p_status, closed_at = now(), closed_by = uid,
         close_note = nullif(btrim(p_note), '')
   where id = p_alert_id
   returning * into alert;
  perform private.log_action('sos.' || p_status::text, 'sos_alert', alert.id,
    jsonb_build_object('ride_id', alert.ride_id));
  return alert;
end;
$$;

-- Rétention : coordonnées effacées 72 h après la fin / l'annulation.
create or replace function private.purge_sos_locations()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  update public.sos_alerts a
     set lat = null, lng = null, accuracy_m = null
    from public.rides r
   where r.id = a.ride_id
     and a.lat is not null
     and r.status in ('finished', 'cancelled')
     and coalesce(r.finished_at, r.cancelled_at, r.updated_at) < now() - interval '72 hours';
  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function private.purge_sos_locations() from public, anon, authenticated;

grant execute on function
  public.raise_sos(uuid, public.sos_kind, uuid, text, double precision, double precision, timestamptz, real),
  public.acknowledge_sos(uuid),
  public.close_sos(uuid, public.sos_status, text)
to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.sos_alerts, public.sos_acknowledgements;
  end if;
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-purge-sos-locations', '23 * * * *',
                          'select private.purge_sos_locations()');
  end if;
end;
$$;
