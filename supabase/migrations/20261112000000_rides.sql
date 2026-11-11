-- =============================================================================
-- Rider Group — Migration 0005 : balades (Mission 04)
-- -----------------------------------------------------------------------------
-- * Balades publiques, privées ou de club (réservées aux membres ou ouvertes).
-- * Trois modes d'adhésion choisis par l'organisateur : libre, approbation,
--   invitation. Appliqués côté serveur.
-- * Machine à états explicite (private.ride_transition) :
--
--     draft ──publish──► published ──start──► in_progress ──finish──► finished
--                          │  ▲                 │  (lock / unlock :
--                       lock unlock             │   adhésions fermées
--                          ▼  │                 │   pendant la balade)
--                        locked ────start───────┘
--     published / locked / in_progress ──cancel──► cancelled
--
-- * Une balade n'accepte de nouveaux participants que si elle est
--   « published », ou « in_progress » non verrouillée. Cette règle vaut pour
--   les adhésions directes, les approbations ET les invitations : une
--   invitation ne contourne jamais le verrouillage ni la confidentialité.
-- * Le verrouillage ne retire personne ; un participant retiré perd
--   immédiatement l'accès aux données réservées aux participants.
--
-- Coordonnées : latitude / longitude saisies en clair, point PostGIS
-- (geography) calculé par le serveur pour les recherches de proximité.
--
-- Nouveaux codes d'erreur : ride_not_found, ride_not_editable,
-- ride_not_joinable, ride_full, invalid_transition, already_participant,
-- not_participant, removed_from_ride, organizer_cannot_leave,
-- club_members_only, start_in_past, capacity_below_participants
-- (+ codes existants : not_allowed, invalid_input, invitation_required,
-- request_not_found, invitation_not_found, invitations_disabled, rate_limited)
-- =============================================================================

create type public.ride_status as enum
  ('draft', 'published', 'locked', 'in_progress', 'finished', 'cancelled');
create type public.ride_visibility as enum ('public', 'private', 'club');
create type public.ride_join_policy as enum ('open', 'approval', 'invite_only');
create type public.ride_difficulty as enum ('easy', 'moderate', 'hard', 'expert');
create type public.ride_participant_status as enum
  ('pending', 'confirmed', 'rejected', 'cancelled', 'left', 'removed');
create type public.ride_invitation_status as enum ('pending', 'accepted', 'declined', 'revoked');

-- Types de motos recommandés (valeurs autorisées).
create or replace function private.ride_bike_types()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array['any', 'scooter', 'roadster', 'sport', 'trail', 'enduro',
               'custom', 'touring', 'quad']::text[];
$$;

create table public.rides (
  id                      uuid primary key default gen_random_uuid(),
  title                   text not null,
  description             text not null default '',
  organizer_id            uuid not null references public.profiles (id) on delete restrict,
  club_id                 uuid references public.clubs (id) on delete cascade,
  starts_at               timestamptz not null,
  ends_at                 timestamptz,
  timezone                text not null default 'Africa/Kinshasa',
  city                    text not null,
  start_label             text not null,
  start_lat               double precision,
  start_lng               double precision,
  destination_label       text not null,
  destination_lat         double precision,
  destination_lng         double precision,
  start_point             extensions.geography(Point, 4326) generated always as (
    case when start_lat is null or start_lng is null then null
         else extensions.st_setsrid(extensions.st_makepoint(start_lng, start_lat), 4326)::extensions.geography
    end) stored,
  itinerary               text not null default '',
  difficulty              public.ride_difficulty not null default 'moderate',
  recommended_bike_types  text[] not null default array['any']::text[],
  max_participants        integer,
  conditions              text not null default '',
  visibility              public.ride_visibility not null,
  open_to_non_members     boolean not null default false,
  join_policy             public.ride_join_policy not null,
  status                  public.ride_status not null default 'draft',
  joins_locked            boolean not null default false,
  participant_count       integer not null default 0 check (participant_count >= 0),
  cancellation_reason     text,
  published_at            timestamptz,
  started_at              timestamptz,
  finished_at             timestamptz,
  cancelled_at            timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  constraint rides_title_length check (char_length(btrim(title)) between 3 and 100),
  constraint rides_description_length check (char_length(description) <= 3000),
  constraint rides_city_length check (char_length(btrim(city)) between 2 and 80),
  constraint rides_start_label_length check (char_length(btrim(start_label)) between 2 and 120),
  constraint rides_destination_label_length check (char_length(btrim(destination_label)) between 2 and 120),
  constraint rides_itinerary_length check (char_length(itinerary) <= 3000),
  constraint rides_conditions_length check (char_length(conditions) <= 1000),
  constraint rides_cancellation_reason_length check (cancellation_reason is null or char_length(cancellation_reason) <= 500),
  constraint rides_end_after_start check (ends_at is null or ends_at > starts_at),
  constraint rides_max_participants_range check (max_participants is null or max_participants between 2 and 500),
  constraint rides_start_coordinates check (
    (start_lat is null and start_lng is null)
    or (start_lat between -90 and 90 and start_lng between -180 and 180)),
  constraint rides_destination_coordinates check (
    (destination_lat is null and destination_lng is null)
    or (destination_lat between -90 and 90 and destination_lng between -180 and 180)),
  constraint rides_bike_types_allowed check (
    cardinality(recommended_bike_types) between 1 and 9
    and recommended_bike_types <@ private.ride_bike_types()),
  -- Une balade de club est rattachée à un club, et seulement elle.
  constraint rides_club_consistency check ((visibility = 'club') = (club_id is not null)),
  constraint rides_open_to_non_members_club_only check (visibility = 'club' or not open_to_non_members),
  -- joins_locked n'a de sens que pour « locked » (toujours vrai) et « in_progress ».
  constraint rides_lock_consistency check (
    (status = 'locked' and joins_locked)
    or (status = 'in_progress')
    or (status not in ('locked', 'in_progress') and not joins_locked))
);

create index rides_discovery_idx on public.rides (status, starts_at);
create index rides_organizer_idx on public.rides (organizer_id);
create index rides_club_idx on public.rides (club_id) where club_id is not null;
create index rides_city_idx on public.rides (lower(city));
create index rides_start_point_idx on public.rides using gist (start_point);

create trigger rides_set_updated_at
  before update on public.rides
  for each row execute function private.set_updated_at();

create table public.ride_participants (
  ride_id       uuid not null references public.rides (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  status        public.ride_participant_status not null,
  message       text,
  requested_at  timestamptz not null default now(),
  confirmed_at  timestamptz,
  updated_at    timestamptz not null default now(),
  decided_by    uuid references public.profiles (id) on delete set null,
  primary key (ride_id, user_id),
  constraint ride_participants_message_length check (message is null or char_length(message) <= 500)
);
create index ride_participants_user_idx on public.ride_participants (user_id, status);
create index ride_participants_ride_status_idx on public.ride_participants (ride_id, status);

create trigger ride_participants_set_updated_at
  before update on public.ride_participants
  for each row execute function private.set_updated_at();

create table public.ride_invitations (
  id            uuid primary key default gen_random_uuid(),
  ride_id       uuid not null references public.rides (id) on delete cascade,
  invitee_id    uuid not null references public.profiles (id) on delete cascade,
  invited_by    uuid references public.profiles (id) on delete set null,
  status        public.ride_invitation_status not null default 'pending',
  created_at    timestamptz not null default now(),
  responded_at  timestamptz
);
create unique index ride_invitations_one_pending
  on public.ride_invitations (ride_id, invitee_id) where status = 'pending';
create index ride_invitations_invitee_idx on public.ride_invitations (invitee_id, status);

-- Préférence de confidentialité dédiée aux balades.
alter table public.profile_settings
  add column allow_ride_invitations boolean not null default true;
grant insert (allow_ride_invitations), update (allow_ride_invitations)
  on public.profile_settings to authenticated;

-- -----------------------------------------------------------------------------
-- Machine à états (fonction pure, testée)
-- -----------------------------------------------------------------------------
create or replace function private.ride_transition(
  p_status public.ride_status,
  p_joins_locked boolean,
  p_action text,
  out new_status public.ride_status,
  out new_joins_locked boolean
)
language plpgsql
immutable
set search_path = ''
as $$
begin
  case
    when p_action = 'publish' and p_status = 'draft' then
      new_status := 'published'; new_joins_locked := false;
    when p_action = 'lock' and p_status = 'published' then
      new_status := 'locked'; new_joins_locked := true;
    when p_action = 'lock' and p_status = 'in_progress' and not p_joins_locked then
      new_status := 'in_progress'; new_joins_locked := true;
    when p_action = 'unlock' and p_status = 'locked' then
      new_status := 'published'; new_joins_locked := false;
    when p_action = 'unlock' and p_status = 'in_progress' and p_joins_locked then
      new_status := 'in_progress'; new_joins_locked := false;
    when p_action = 'start' and p_status in ('published', 'locked') then
      -- Une balade verrouillée démarre verrouillée.
      new_status := 'in_progress'; new_joins_locked := (p_status = 'locked');
    when p_action = 'finish' and p_status = 'in_progress' then
      new_status := 'finished'; new_joins_locked := false;
    when p_action = 'cancel' and p_status in ('published', 'locked', 'in_progress') then
      new_status := 'cancelled'; new_joins_locked := false;
    else
      raise exception 'invalid_transition' using errcode = 'P0001';
  end case;
end;
$$;

-- La balade accepte-t-elle de nouveaux participants (quelle que soit la voie) ?
create or replace function private.ride_accepts_participants(
  p_status public.ride_status, p_joins_locked boolean
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_status = 'published' or (p_status = 'in_progress' and not p_joins_locked);
$$;

-- -----------------------------------------------------------------------------
-- Fonctions d'autorisation
-- -----------------------------------------------------------------------------

-- Organisateur, ou administrateur du club pour une balade de club.
create or replace function private.can_manage_ride(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.rides r
     where r.id = p_ride_id
       and (r.organizer_id = (select auth.uid())
            or (r.club_id is not null and private.has_club_role(r.club_id, 'admin')))
  );
$$;

create or replace function private.is_ride_participant(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ride_participants p
     where p.ride_id = p_ride_id and p.user_id = (select auth.uid())
       and p.status = 'confirmed'
  );
$$;

-- Accès « grand public » à une balade (hors relation personnelle).
create or replace function private.ride_is_openly_visible(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.rides r
     where r.id = p_ride_id
       and r.status <> 'draft'
       and (r.visibility = 'public'
            or (r.visibility = 'club'
                and (r.open_to_non_members or private.is_club_member(r.club_id))))
  );
$$;

create or replace function private.can_view_ride(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.can_manage_ride(p_ride_id)
      or private.ride_is_openly_visible(p_ride_id)
      or exists (
        select 1 from public.rides r
         where r.id = p_ride_id and r.status <> 'draft'
           and (exists (select 1 from public.ride_participants p
                         where p.ride_id = r.id and p.user_id = (select auth.uid())
                           and p.status in ('pending', 'confirmed'))
                or exists (select 1 from public.ride_invitations i
                            where i.ride_id = r.id and i.invitee_id = (select auth.uid())
                              and i.status = 'pending')));
$$;

-- Liste des participants confirmés : gestionnaires, participants confirmés,
-- ou balade ouvertement visible.
create or replace function private.can_view_ride_participants(p_ride_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.can_manage_ride(p_ride_id)
      or private.is_ride_participant(p_ride_id)
      or private.ride_is_openly_visible(p_ride_id);
$$;

-- Peut-on rejoindre cette balade selon sa visibilité ? (hors invitation)
create or replace function private.can_join_ride_audience(p_ride_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.rides r
     where r.id = p_ride_id
       and (r.visibility = 'public'
            or (r.visibility = 'club'
                and (r.open_to_non_members
                     or exists (select 1 from public.club_members m
                                 where m.club_id = r.club_id and m.user_id = p_user_id))))
  );
$$;

-- Visibilité des profils : ajout des relations de balade.
create or replace function private.can_view_profile(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null and (
    p_user_id = (select auth.uid())
    or coalesce((select s.discoverable from public.profile_settings s
                  where s.user_id = p_user_id), true)
    or exists (
      select 1 from public.club_members a
        join public.club_members b on b.club_id = a.club_id
       where a.user_id = p_user_id and b.user_id = (select auth.uid()))
    or exists (
      select 1 from public.club_join_requests r
        join public.club_members m on m.club_id = r.club_id
       where r.user_id = p_user_id and r.status = 'pending'
         and m.user_id = (select auth.uid()) and m.role in ('owner', 'admin'))
    or exists (
      select 1 from public.club_invitations i
       where i.invited_by = p_user_id and i.invitee_id = (select auth.uid())
         and i.status = 'pending')
    -- participants confirmés d'une même balade
    or exists (
      select 1 from public.ride_participants a
        join public.ride_participants b on b.ride_id = a.ride_id
       where a.user_id = p_user_id and a.status = 'confirmed'
         and b.user_id = (select auth.uid()) and b.status = 'confirmed')
    -- demandeur d'une balade gérée par l'utilisateur
    or exists (
      select 1 from public.ride_participants p
       where p.user_id = p_user_id and p.status = 'pending'
         and private.can_manage_ride(p.ride_id))
    -- auteur d'une invitation de balade reçue
    or exists (
      select 1 from public.ride_invitations i
       where i.invited_by = p_user_id and i.invitee_id = (select auth.uid())
         and i.status = 'pending')
  );
$$;

grant execute on function
  private.ride_bike_types(),
  private.ride_accepts_participants(public.ride_status, boolean),
  private.can_manage_ride(uuid),
  private.is_ride_participant(uuid),
  private.ride_is_openly_visible(uuid),
  private.can_view_ride(uuid),
  private.can_view_ride_participants(uuid)
to authenticated;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

-- Compteur de participants confirmés.
create or replace function private.sync_ride_participant_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  delta integer := 0;
  target uuid := coalesce(new.ride_id, old.ride_id);
begin
  if tg_op in ('UPDATE', 'DELETE') and old.status = 'confirmed' then
    delta := delta - 1;
  end if;
  if tg_op in ('INSERT', 'UPDATE') and new.status = 'confirmed' then
    delta := delta + 1;
  end if;
  if delta <> 0 then
    update public.rides set participant_count = greatest(participant_count + delta, 0)
     where id = target;
  end if;
  return null;
end;
$$;

create trigger ride_participants_count
  after insert or update of status or delete on public.ride_participants
  for each row execute function private.sync_ride_participant_count();

-- Garde des modifications DIRECTES par les gestionnaires (requêtes client).
-- Fonction SECURITY INVOKER : current_user vaut « authenticated » pour une
-- requête client, et le propriétaire des fonctions serveur (postgres) quand
-- la mise à jour vient d'une fonction SECURITY DEFINER (statut, compteur).
create or replace function private.guard_ride_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if old.status in ('in_progress', 'finished', 'cancelled') then
    raise exception 'ride_not_editable' using errcode = 'P0001';
  end if;
  if new.max_participants is not null and new.max_participants < old.participant_count then
    raise exception 'capacity_below_participants' using errcode = 'P0001';
  end if;
  if old.status in ('published', 'locked')
     and new.starts_at is distinct from old.starts_at
     and new.starts_at <= now() then
    raise exception 'start_in_past' using errcode = 'P0001';
  end if;
  if new.timezone is distinct from old.timezone
     and not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger rides_guard_update
  before update on public.rides
  for each row execute function private.guard_ride_update();

revoke all on function private.sync_ride_participant_count() from public, anon, authenticated;
-- La garde s'exécute avec les droits de l'appelant : il doit pouvoir l'invoquer.
revoke all on function private.guard_ride_update() from public, anon;
grant execute on function private.guard_ride_update() to authenticated;

-- -----------------------------------------------------------------------------
-- RLS et privilèges
-- -----------------------------------------------------------------------------
alter table public.rides enable row level security;
alter table public.ride_participants enable row level security;
alter table public.ride_invitations enable row level security;

revoke all on public.rides, public.ride_participants, public.ride_invitations
  from anon, authenticated;
grant select on public.rides, public.ride_participants, public.ride_invitations
  to authenticated;

-- Colonnes modifiables directement par les gestionnaires (avant le départ).
-- Jamais : organizer_id, club_id, status, joins_locked, participant_count,
-- horodatages de statut.
grant update (title, description, starts_at, ends_at, timezone, city,
              start_label, start_lat, start_lng,
              destination_label, destination_lat, destination_lng,
              itinerary, difficulty, recommended_bike_types, max_participants,
              conditions, visibility, open_to_non_members, join_policy)
  on public.rides to authenticated;

create policy "rides: lecture si visible"
  on public.rides for select to authenticated
  using (private.can_view_ride(id));

create policy "rides: modification par les gestionnaires"
  on public.rides for update to authenticated
  using (private.can_manage_ride(id))
  with check (private.can_manage_ride(id));

create policy "ride_participants: soi-même, gestionnaires, ou confirmés visibles"
  on public.ride_participants for select to authenticated
  using (user_id = (select auth.uid())
         or private.can_manage_ride(ride_id)
         or (status = 'confirmed' and private.can_view_ride_participants(ride_id)));

create policy "ride_invitations: invité ou gestionnaires"
  on public.ride_invitations for select to authenticated
  using (invitee_id = (select auth.uid()) or private.can_manage_ride(ride_id));

-- -----------------------------------------------------------------------------
-- Fonctions serveur
-- -----------------------------------------------------------------------------

create or replace function public.create_ride(
  p_title               text,
  p_starts_at           timestamptz,
  p_city                text,
  p_start_label         text,
  p_destination_label   text,
  p_visibility          public.ride_visibility,
  p_join_policy         public.ride_join_policy,
  p_club_id             uuid default null,
  p_open_to_non_members boolean default false,
  p_description         text default '',
  p_ends_at             timestamptz default null,
  p_timezone            text default 'Africa/Kinshasa',
  p_start_lat           double precision default null,
  p_start_lng           double precision default null,
  p_destination_lat     double precision default null,
  p_destination_lng     double precision default null,
  p_itinerary           text default '',
  p_difficulty          public.ride_difficulty default 'moderate',
  p_recommended_bike_types text[] default array['any']::text[],
  p_max_participants    integer default null,
  p_conditions          text default '',
  p_publish             boolean default false
)
returns public.rides
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created public.rides;
begin
  if (select count(*) from public.rides r
       where r.organizer_id = uid and r.created_at > now() - interval '24 hours') >= 10 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  if p_club_id is not null then
    if not private.has_club_role(p_club_id, 'admin') then
      raise exception 'not_allowed' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.clubs where id = p_club_id and suspended_at is not null) then
      raise exception 'club_suspended' using errcode = 'P0001';
    end if;
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_timezone) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if p_publish and p_starts_at <= now() then
    raise exception 'start_in_past' using errcode = 'P0001';
  end if;

  begin
    insert into public.rides (
      title, description, organizer_id, club_id, starts_at, ends_at, timezone, city,
      start_label, start_lat, start_lng, destination_label, destination_lat, destination_lng,
      itinerary, difficulty, recommended_bike_types, max_participants, conditions,
      visibility, open_to_non_members, join_policy, status, published_at)
    values (
      btrim(p_title), coalesce(btrim(p_description), ''), uid, p_club_id, p_starts_at, p_ends_at,
      p_timezone, btrim(p_city), btrim(p_start_label), p_start_lat, p_start_lng,
      btrim(p_destination_label), p_destination_lat, p_destination_lng,
      coalesce(btrim(p_itinerary), ''), coalesce(p_difficulty, 'moderate'),
      coalesce(p_recommended_bike_types, array['any']::text[]), p_max_participants,
      coalesce(btrim(p_conditions), ''), p_visibility, coalesce(p_open_to_non_members, false),
      p_join_policy,
      case when p_publish then 'published'::public.ride_status else 'draft'::public.ride_status end,
      case when p_publish then now() end)
    returning * into created;
  exception
    when check_violation or not_null_violation then
      raise exception 'invalid_input' using errcode = 'P0001';
  end;

  -- L'organisateur est le premier participant confirmé.
  insert into public.ride_participants (ride_id, user_id, status, confirmed_at, decided_by)
  values (created.id, uid, 'confirmed', now(), uid);

  perform private.log_action('ride.create', 'ride', created.id,
    jsonb_build_object('visibility', created.visibility, 'join_policy', created.join_policy,
                       'club_id', created.club_id, 'published', p_publish));

  select * into created from public.rides where id = created.id;
  return created;
end;
$$;

-- Changement de statut : publish | lock | unlock | start | finish | cancel
create or replace function public.set_ride_status(
  p_ride_id uuid, p_action text, p_reason text default null
)
returns public.rides
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ride public.rides;
  nxt record;
begin
  select * into ride from public.rides where id = p_ride_id for update;
  if not found or not private.can_view_ride(p_ride_id) then
    raise exception 'ride_not_found' using errcode = 'P0001';
  end if;
  if not private.can_manage_ride(p_ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_action = 'publish' and ride.starts_at <= now() then
    raise exception 'start_in_past' using errcode = 'P0001';
  end if;
  if p_reason is not null and char_length(p_reason) > 500 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  select * into nxt from private.ride_transition(ride.status, ride.joins_locked, p_action);

  update public.rides
     set status = nxt.new_status,
         joins_locked = nxt.new_joins_locked,
         published_at = case when p_action = 'publish' then now() else published_at end,
         started_at = case when p_action = 'start' then now() else started_at end,
         finished_at = case when p_action = 'finish' then now() else finished_at end,
         cancelled_at = case when p_action = 'cancel' then now() else cancelled_at end,
         cancellation_reason = case when p_action = 'cancel'
                                    then nullif(btrim(p_reason), '') else cancellation_reason end
   where id = p_ride_id
   returning * into ride;

  -- Fin ou annulation : les demandes et invitations en attente deviennent caduques.
  if nxt.new_status in ('finished', 'cancelled') then
    update public.ride_participants set status = 'rejected', decided_by = uid
     where ride_id = p_ride_id and status = 'pending';
    update public.ride_invitations set status = 'revoked', responded_at = now()
     where ride_id = p_ride_id and status = 'pending';
  end if;

  perform private.log_action('ride.' || p_action, 'ride', p_ride_id,
    jsonb_build_object('status', ride.status, 'joins_locked', ride.joins_locked));
  return ride;
end;
$$;

-- Seuls les brouillons peuvent être supprimés (sinon : annuler).
create or replace function public.delete_ride_draft(p_ride_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not exists (select 1 from public.rides where id = p_ride_id and organizer_id = uid) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.rides where id = p_ride_id and status = 'draft') then
    raise exception 'ride_not_editable' using errcode = 'P0001';
  end if;
  delete from public.rides where id = p_ride_id;
  perform private.log_action('ride.delete_draft', 'ride', p_ride_id);
end;
$$;

-- Vérifie qu'une nouvelle place peut être attribuée (balade verrouillée par
-- l'appelant avec FOR UPDATE).
create or replace function private.assert_ride_accepts(p_ride public.rides)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if not private.ride_accepts_participants(p_ride.status, p_ride.joins_locked) then
    raise exception 'ride_not_joinable' using errcode = 'P0001';
  end if;
  if p_ride.max_participants is not null
     and p_ride.participant_count >= p_ride.max_participants then
    raise exception 'ride_full' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function private.confirm_ride_participant(
  p_ride_id uuid, p_user_id uuid, p_decided_by uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.ride_participants (ride_id, user_id, status, confirmed_at, decided_by)
  values (p_ride_id, p_user_id, 'confirmed', now(), p_decided_by)
  on conflict (ride_id, user_id) do update
    set status = 'confirmed', confirmed_at = now(), decided_by = excluded.decided_by;
end;
$$;

revoke all on function
  private.assert_ride_accepts(public.rides),
  private.confirm_ride_participant(uuid, uuid, uuid)
from public, anon, authenticated;

-- Rejoindre : 'joined' (confirmé) ou 'requested' (en attente).
create or replace function public.join_ride(p_ride_id uuid, p_message text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ride public.rides;
  current_status public.ride_participant_status;
  invitation_id uuid;
begin
  select * into ride from public.rides where id = p_ride_id for update;
  if not found or not private.can_view_ride(p_ride_id) or ride.status = 'draft' then
    raise exception 'ride_not_found' using errcode = 'P0001';
  end if;

  select p.status into current_status from public.ride_participants p
   where p.ride_id = p_ride_id and p.user_id = uid;
  if current_status = 'confirmed' then
    raise exception 'already_participant' using errcode = 'P0001';
  end if;
  if current_status = 'removed' then
    raise exception 'removed_from_ride' using errcode = 'P0001';
  end if;

  -- Une invitation en attente vaut acceptation (mêmes contrôles).
  select i.id into invitation_id from public.ride_invitations i
   where i.ride_id = p_ride_id and i.invitee_id = uid and i.status = 'pending';
  if invitation_id is not null then
    perform public.respond_to_ride_invitation(invitation_id, true);
    return 'joined';
  end if;

  if not private.can_join_ride_audience(p_ride_id, uid) then
    raise exception 'club_members_only' using errcode = 'P0001';
  end if;
  if not private.ride_accepts_participants(ride.status, ride.joins_locked) then
    raise exception 'ride_not_joinable' using errcode = 'P0001';
  end if;

  if ride.join_policy = 'open' then
    perform private.assert_ride_accepts(ride);
    perform private.confirm_ride_participant(p_ride_id, uid, uid);
    perform private.log_action('ride.join', 'ride', p_ride_id);
    return 'joined';
  elsif ride.join_policy = 'approval' then
    if p_message is not null and char_length(p_message) > 500 then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
    if current_status = 'pending' then
      return 'requested';
    end if;
    insert into public.ride_participants (ride_id, user_id, status, message, requested_at)
    values (p_ride_id, uid, 'pending', nullif(btrim(p_message), ''), now())
    on conflict (ride_id, user_id) do update
      set status = 'pending', message = excluded.message, requested_at = now(),
          confirmed_at = null, decided_by = null;
    return 'requested';
  else
    raise exception 'invitation_required' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.cancel_ride_request(p_ride_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  update public.ride_participants set status = 'cancelled', decided_by = uid
   where ride_id = p_ride_id and user_id = uid and status = 'pending';
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.leave_ride(p_ride_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if exists (select 1 from public.rides where id = p_ride_id and organizer_id = uid) then
    raise exception 'organizer_cannot_leave' using errcode = 'P0001';
  end if;
  update public.ride_participants set status = 'left', decided_by = uid
   where ride_id = p_ride_id and user_id = uid and status = 'confirmed';
  if not found then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  perform private.log_action('ride.leave', 'ride', p_ride_id);
end;
$$;

create or replace function public.decide_ride_request(
  p_ride_id uuid, p_user_id uuid, p_approve boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ride public.rides;
begin
  select * into ride from public.rides where id = p_ride_id for update;
  if not found then
    raise exception 'ride_not_found' using errcode = 'P0001';
  end if;
  if not private.can_manage_ride(p_ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.ride_participants
                  where ride_id = p_ride_id and user_id = p_user_id and status = 'pending') then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;

  if p_approve then
    -- Le verrouillage et la capacité s'appliquent aussi aux approbations.
    perform private.assert_ride_accepts(ride);
    perform private.confirm_ride_participant(p_ride_id, p_user_id, uid);
  else
    update public.ride_participants set status = 'rejected', decided_by = uid
     where ride_id = p_ride_id and user_id = p_user_id;
  end if;

  perform private.log_action(
    case when p_approve then 'ride.request.approve' else 'ride.request.reject' end,
    'ride', p_ride_id, jsonb_build_object('user_id', p_user_id));
end;
$$;

-- Retrait d'un participant : il perd immédiatement l'accès aux données
-- réservées aux participants et ne peut pas revenir de lui-même.
create or replace function public.remove_ride_participant(p_ride_id uuid, p_user_id uuid)
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
  if exists (select 1 from public.rides where id = p_ride_id and organizer_id = p_user_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.ride_participants set status = 'removed', decided_by = uid
   where ride_id = p_ride_id and user_id = p_user_id and status in ('confirmed', 'pending');
  if not found then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  update public.ride_invitations set status = 'revoked', responded_at = now()
   where ride_id = p_ride_id and invitee_id = p_user_id and status = 'pending';
  perform private.log_action('ride.participant.remove', 'ride', p_ride_id,
    jsonb_build_object('user_id', p_user_id));
end;
$$;

create or replace function public.invite_to_ride(p_ride_id uuid, p_invitee_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ride public.rides;
  existing uuid;
  created uuid;
begin
  select * into ride from public.rides where id = p_ride_id;
  if not found then
    raise exception 'ride_not_found' using errcode = 'P0001';
  end if;
  if not private.can_manage_ride(p_ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if ride.status in ('finished', 'cancelled') then
    raise exception 'ride_not_joinable' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = p_invitee_id) then
    raise exception 'user_not_found' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ride_participants
              where ride_id = p_ride_id and user_id = p_invitee_id and status = 'confirmed') then
    raise exception 'already_participant' using errcode = 'P0001';
  end if;
  -- Confidentialité : une balade réservée aux membres d'un club ne peut
  -- inviter que des membres de ce club.
  if not private.can_join_ride_audience(p_ride_id, p_invitee_id)
     and ride.visibility = 'club' then
    raise exception 'club_members_only' using errcode = 'P0001';
  end if;
  if not coalesce((select s.allow_ride_invitations from public.profile_settings s
                    where s.user_id = p_invitee_id), true) then
    raise exception 'invitations_disabled' using errcode = 'P0001';
  end if;

  select id into existing from public.ride_invitations
   where ride_id = p_ride_id and invitee_id = p_invitee_id and status = 'pending';
  if existing is not null then
    return existing;
  end if;

  insert into public.ride_invitations (ride_id, invitee_id, invited_by)
  values (p_ride_id, p_invitee_id, uid)
  returning id into created;

  perform private.log_action('ride.invite', 'ride', p_ride_id,
    jsonb_build_object('invitee_id', p_invitee_id));
  return created;
end;
$$;

create or replace function public.respond_to_ride_invitation(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  inv public.ride_invitations;
  ride public.rides;
begin
  select * into inv from public.ride_invitations
   where id = p_invitation_id and invitee_id = uid and status = 'pending' for update;
  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;

  if p_accept then
    select * into ride from public.rides where id = inv.ride_id for update;
    -- Une invitation ne contourne ni le verrouillage, ni la capacité, ni la
    -- restriction aux membres du club.
    if ride.visibility = 'club' and not private.can_join_ride_audience(ride.id, uid) then
      raise exception 'club_members_only' using errcode = 'P0001';
    end if;
    perform private.assert_ride_accepts(ride);
    perform private.confirm_ride_participant(ride.id, uid, inv.invited_by);
  end if;

  update public.ride_invitations
     set status = case when p_accept then 'accepted'::public.ride_invitation_status
                       else 'declined'::public.ride_invitation_status end,
         responded_at = now()
   where id = inv.id;

  if p_accept then
    perform private.log_action('ride.invitation.accept', 'ride', inv.ride_id);
  end if;
end;
$$;

create or replace function public.revoke_ride_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.ride_invitations;
begin
  perform private.require_user();
  select * into inv from public.ride_invitations
   where id = p_invitation_id and status = 'pending' for update;
  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;
  if not private.can_manage_ride(inv.ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.ride_invitations set status = 'revoked', responded_at = now()
   where id = inv.id;
end;
$$;

-- Recherche de proximité (PostGIS). Les droits de lecture (RLS) s'appliquent :
-- SECURITY INVOKER.
create or replace function public.rides_near(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 50,
  p_limit integer default 50
)
returns setof public.rides
language plpgsql
stable
security invoker
set search_path = ''
as $$
begin
  if p_lat not between -90 and 90 or p_lng not between -180 and 180
     or p_radius_km <= 0 or p_radius_km > 500 or p_limit not between 1 and 100 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  return query
    select r.* from public.rides r
     where r.start_point is not null
       and r.status in ('published', 'locked', 'in_progress')
       and extensions.st_dwithin(
             r.start_point,
             extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography,
             p_radius_km * 1000)
     order by extensions.st_distance(
             r.start_point,
             extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography),
              r.starts_at
     limit p_limit;
end;
$$;

grant execute on function
  public.create_ride(text, timestamptz, text, text, text, public.ride_visibility,
                     public.ride_join_policy, uuid, boolean, text, timestamptz, text,
                     double precision, double precision, double precision, double precision,
                     text, public.ride_difficulty, text[], integer, text, boolean),
  public.set_ride_status(uuid, text, text),
  public.delete_ride_draft(uuid),
  public.join_ride(uuid, text),
  public.cancel_ride_request(uuid),
  public.leave_ride(uuid),
  public.decide_ride_request(uuid, uuid, boolean),
  public.remove_ride_participant(uuid, uuid),
  public.invite_to_ride(uuid, uuid),
  public.respond_to_ride_invitation(uuid, boolean),
  public.revoke_ride_invitation(uuid),
  public.rides_near(double precision, double precision, double precision, integer)
to authenticated;
