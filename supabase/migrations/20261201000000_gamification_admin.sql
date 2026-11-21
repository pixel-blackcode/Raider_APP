-- =============================================================================
-- Rider Group — Migration 0026 : badges, défis et administration (Mission 11)
-- -----------------------------------------------------------------------------
-- D-71 : badges (participation, sécurité, distance d'une balade), visibles sur
--   le profil de chaque motard ; défis créés par l'équipe sur une période
--   (dont la plus longue balade) ; « Meilleure balade du mois » datée
--   (ex. « octobre 2026 ») ; annonces officielles de l'équipe dans le fil.
--   Jamais de classement entre motards ni de vitesse.
-- D-72 : suspension d'un compte par l'équipe (7 j, 30 j ou sans fin, raison
--   envoyée au motard) : plus de publication, message, annonce, club,
--   balade ; il peut toujours se connecter, lire et utiliser le SOS.
-- Tableau de bord web de l'équipe : fonctions admin_* (administrateurs
-- Rider Group uniquement).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Distance d'une balade terminée
-- -----------------------------------------------------------------------------
alter table public.rides add column distance_km numeric(8, 1);

-- Trajet enregistré du chef de convoi s'il existe, sinon départ → arrivée à
-- vol d'oiseau ; on garde la plus grande des deux (trajet partiel).
create or replace function private.ride_distance_km(p_ride_id uuid)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r public.rides;
  trail double precision;
  straight double precision;
begin
  select * into r from public.rides where id = p_ride_id;
  select sum(extensions.st_distance(
           extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography,
           extensions.st_setsrid(extensions.st_makepoint(plng, plat), 4326)::extensions.geography))
    into trail
    from (select lat, lng,
                 lag(lat) over (order by recorded_at) plat,
                 lag(lng) over (order by recorded_at) plng
            from public.ride_trail_points where ride_id = p_ride_id) s
   where plat is not null;
  if r.start_lat is not null and r.start_lng is not null
     and r.destination_lat is not null and r.destination_lng is not null then
    straight := extensions.st_distance(
      extensions.st_setsrid(extensions.st_makepoint(r.start_lng, r.start_lat), 4326)::extensions.geography,
      extensions.st_setsrid(extensions.st_makepoint(r.destination_lng, r.destination_lat), 4326)::extensions.geography);
  end if;
  return nullif(round((greatest(coalesce(trail, 0), coalesce(straight, 0)) / 1000)::numeric, 1), 0);
end;
$$;
revoke all on function private.ride_distance_km(uuid) from public, anon, authenticated;

create or replace function private.set_ride_distance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'finished' and old.status is distinct from 'finished' then
    new.distance_km := private.ride_distance_km(new.id);
  end if;
  return new;
end;
$$;
revoke all on function private.set_ride_distance() from public, anon, authenticated;
create trigger rides_set_distance
  before update of status on public.rides
  for each row execute function private.set_ride_distance();

-- -----------------------------------------------------------------------------
-- Suspension des comptes
-- -----------------------------------------------------------------------------
create table public.account_suspensions (
  user_id     uuid primary key references public.profiles (id) on delete cascade,
  until       timestamptz,  -- null : sans fin
  reason      text not null check (char_length(btrim(reason)) between 3 and 280),
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);
alter table public.account_suspensions enable row level security;
revoke all on public.account_suspensions from anon, authenticated;
grant select on public.account_suspensions to authenticated;
create policy "account_suspensions: le motard concerné"
  on public.account_suspensions for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function private.is_suspended(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.account_suspensions
                  where user_id = p_user_id and (until is null or until > now()));
$$;
grant execute on function private.is_suspended(uuid) to authenticated;

-- Bloque les écritures d'un compte suspendu (le SOS et la lecture restent possibles).
create or replace function private.block_suspended()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is not null and private.is_suspended(uid) then
    raise exception 'account_suspended' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke all on function private.block_suspended() from public, anon;
grant execute on function private.block_suspended() to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['posts', 'post_comments', 'post_reactions', 'messages', 'listings',
                           'rides', 'ride_participants', 'ride_invitations', 'clubs',
                           'club_join_requests', 'club_invitations', 'events', 'shops'] loop
    execute format('create trigger %I before insert on public.%I
                      for each row execute function private.block_suspended()',
                   t || '_block_suspended', t);
  end loop;
end;
$$;

create or replace function public.my_suspension()
returns table (until timestamptz, reason text)
language sql
stable
security definer
set search_path = ''
as $$
  select until, reason from public.account_suspensions
   where user_id = (select auth.uid()) and (until is null or until > now());
$$;

-- -----------------------------------------------------------------------------
-- Badges
-- -----------------------------------------------------------------------------
create table public.badge_awards (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  code        text not null check (code ~ '^[a-z0-9_]{2,40}$'),
  title       text check (title is null or char_length(title) <= 120),
  period      text check (period is null or period ~ '^[0-9]{4}-[0-9]{2}$'),
  ref_id      uuid,
  awarded_at  timestamptz not null default now()
);
create unique index badge_awards_unique on public.badge_awards
  (user_id, code, coalesce(period, ''), coalesce(ref_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index badge_awards_user_idx on public.badge_awards (user_id, awarded_at desc);
alter table public.badge_awards enable row level security;
revoke all on public.badge_awards from anon, authenticated;
grant select on public.badge_awards to authenticated;
create policy "badge_awards: profil visible"
  on public.badge_awards for select to authenticated
  using (private.can_view_profile(user_id));

-- Catalogue des badges automatiques (jamais la vitesse).
create or replace function private.badge_catalog()
returns table (code text, title text, description text, metric text, target numeric, sort integer)
language sql
immutable
set search_path = ''
as $$
  values
    ('welcome', 'Bienvenue', 'Profil complet (photo, ville, présentation)', 'profile_complete', 1::numeric, 10),
    ('first_ride', 'Première balade', 'Une balade terminée', 'rides_finished', 1, 20),
    ('loyal', 'Fidèle', '10 balades terminées', 'rides_finished', 10, 21),
    ('pillar', 'Pilier', '50 balades terminées', 'rides_finished', 50, 22),
    ('organizer', 'Organisateur', 'Une balade organisée et terminée', 'rides_organized', 1, 30),
    ('convoy_leader', 'Chef de convoi', '5 balades organisées et terminées', 'rides_organized', 5, 31),
    ('road_100', 'Escapade', 'Une balade de 100 km', 'max_ride_km', 100, 40),
    ('road_500', 'Grand voyageur', 'Une balade de 500 km', 'max_ride_km', 500, 41),
    ('road_1000', 'Traversée', 'Une balade de 1 000 km (ex. Kinshasa–Lubumbashi)', 'max_ride_km', 1000, 42),
    ('safe_home', 'Rentré sain', '10 trajets solo jusqu''à « Je suis arrivé »', 'solo_arrived', 10, 50),
    ('guardian', 'Ange gardien', '5 trajets solo suivis comme proche', 'solo_watched', 5, 51),
    ('mechanic', 'Mécano', '5 entretiens notés au garage', 'maintenance', 5, 60),
    ('in_club', 'En club', 'Membre d''un club ou d''un regroupement', 'clubs', 1, 70),
    ('seller', 'Premier vendeur', 'Une annonce publiée', 'listings', 1, 80),
    ('events', 'Habitué des événements', '3 événements « J''y vais »', 'events', 3, 90);
$$;

-- Balades terminées d'un motard (organisateur ou participant confirmé).
create or replace function private.finished_rides_of(p_user_id uuid)
returns setof public.rides
language sql
stable
security definer
set search_path = ''
as $$
  select r.* from public.rides r
   where r.status = 'finished'
     and (r.organizer_id = p_user_id
          or exists (select 1 from public.ride_participants p
                      where p.ride_id = r.id and p.user_id = p_user_id and p.status = 'confirmed'));
$$;
revoke all on function private.finished_rides_of(uuid) from public, anon, authenticated;

create or replace function private.rider_stats(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'rides_finished', (select count(*) from private.finished_rides_of(p_user_id)),
    'rides_organized', (select count(*) from public.rides
                         where organizer_id = p_user_id and status = 'finished'),
    'max_ride_km', (select coalesce(max(distance_km), 0) from private.finished_rides_of(p_user_id)),
    'total_km', (select coalesce(sum(distance_km), 0) from private.finished_rides_of(p_user_id)),
    'solo_arrived', (select count(*) from public.solo_trips
                      where user_id = p_user_id and status = 'arrived'),
    'solo_watched', (select count(*) from public.solo_trip_watchers w
                       join public.solo_trips t on t.id = w.trip_id
                      where w.watcher_id = p_user_id and t.status = 'arrived'),
    'maintenance', (select count(*) from public.maintenance_records m
                      join public.motorcycles c on c.id = m.moto_id where c.owner_id = p_user_id),
    'clubs', (select count(*) from public.club_members where user_id = p_user_id),
    'listings', (select count(*) from public.listings where seller_id = p_user_id),
    'events', (select count(*) from public.event_attendees where user_id = p_user_id),
    'profile_complete', (select case when avatar_path is not null and coalesce(btrim(city), '') <> ''
                                       and coalesce(btrim(bio), '') <> '' then 1 else 0 end
                           from public.profiles where id = p_user_id));
$$;
revoke all on function private.rider_stats(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Défis
-- -----------------------------------------------------------------------------
create table public.challenges (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (char_length(btrim(title)) between 3 and 80),
  description  text not null default '' check (char_length(description) <= 300),
  metric       text not null check (metric in ('rides_finished', 'rides_organized', 'ride_distance',
                                               'distance_total', 'maintenance', 'solo_arrived',
                                               'events', 'posts')),
  target       integer not null check (target between 1 and 100000),
  starts_on    date not null,
  ends_on      date not null,
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now(),
  cancelled_at timestamptz,
  check (ends_on >= starts_on and ends_on - starts_on <= 366)
);
create index challenges_period_idx on public.challenges (ends_on) where cancelled_at is null;
alter table public.challenges enable row level security;
revoke all on public.challenges from anon, authenticated;
grant select on public.challenges to authenticated;
create policy "challenges: lisibles par tous les motards"
  on public.challenges for select to authenticated using (cancelled_at is null);

-- Progression d'un motard sur un défi (dates en heure de Kinshasa).
create or replace function private.challenge_progress(p_challenge public.challenges, p_user_id uuid)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  t0 timestamptz := (p_challenge.starts_on::timestamp) at time zone 'Africa/Kinshasa';
  t1 timestamptz := ((p_challenge.ends_on + 1)::timestamp) at time zone 'Africa/Kinshasa';
begin
  return coalesce(case p_challenge.metric
    when 'rides_finished' then (select count(*) from private.finished_rides_of(p_user_id) r
                                 where r.finished_at >= t0 and r.finished_at < t1)
    when 'rides_organized' then (select count(*) from public.rides r
                                  where r.organizer_id = p_user_id and r.status = 'finished'
                                    and r.finished_at >= t0 and r.finished_at < t1)
    when 'ride_distance' then (select max(r.distance_km) from private.finished_rides_of(p_user_id) r
                                where r.finished_at >= t0 and r.finished_at < t1)
    when 'distance_total' then (select sum(r.distance_km) from private.finished_rides_of(p_user_id) r
                                 where r.finished_at >= t0 and r.finished_at < t1)
    when 'maintenance' then (select count(*) from public.maintenance_records m
                               join public.motorcycles c on c.id = m.moto_id
                              where c.owner_id = p_user_id and m.created_at >= t0 and m.created_at < t1)
    when 'solo_arrived' then (select count(*) from public.solo_trips s
                               where s.user_id = p_user_id and s.status = 'arrived'
                                 and s.ended_at >= t0 and s.ended_at < t1)
    when 'events' then (select count(*) from public.event_attendees a
                         where a.user_id = p_user_id and a.created_at >= t0 and a.created_at < t1)
    when 'posts' then (select count(*) from public.posts p
                        where p.author_id = p_user_id and p.moderation = 'visible'
                          and p.created_at >= t0 and p.created_at < t1)
  end, 0);
end;
$$;
revoke all on function private.challenge_progress(public.challenges, uuid) from public, anon, authenticated;

-- Attribue les badges gagnés (automatiques et défis en cours) ; prévient le motard.
create or replace function private.check_badges(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  stats jsonb;
  b record;
  c public.challenges;
  new_id uuid;
  n integer := 0;
begin
  if p_user_id is null or not exists (select 1 from public.profiles where id = p_user_id) then
    return 0;
  end if;
  stats := private.rider_stats(p_user_id);
  for b in select * from private.badge_catalog() loop
    if coalesce((stats ->> b.metric)::numeric, 0) >= b.target then
      new_id := null;
      insert into public.badge_awards (user_id, code, title)
      values (p_user_id, b.code, b.title)
      on conflict do nothing
      returning id into new_id;
      if new_id is not null then
        perform private.notify(p_user_id, 'badge_awarded', null, p_ref => new_id,
          p_data => jsonb_build_object('code', b.code, 'title', b.title));
        n := n + 1;
      end if;
    end if;
  end loop;
  for c in select * from public.challenges
            where cancelled_at is null
              and starts_on <= (now() at time zone 'Africa/Kinshasa')::date
              and ends_on >= (now() at time zone 'Africa/Kinshasa')::date - 1 loop
    if private.challenge_progress(c, p_user_id) >= c.target then
      new_id := null;
      insert into public.badge_awards (user_id, code, title, period, ref_id)
      values (p_user_id, 'challenge', c.title, to_char(c.ends_on, 'YYYY-MM'), c.id)
      on conflict do nothing
      returning id into new_id;
      if new_id is not null then
        perform private.notify(p_user_id, 'badge_awarded', null, p_ref => new_id,
          p_data => jsonb_build_object('code', 'challenge', 'title', c.title));
        n := n + 1;
      end if;
    end if;
  end loop;
  return n;
end;
$$;
revoke all on function private.check_badges(uuid) from public, anon, authenticated;

-- Déclencheurs : les badges arrivent au moment de l'action.
create or replace function private.badges_after_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid;
begin
  case tg_table_name
    when 'rides' then
      if new.status = 'finished' and old.status is distinct from 'finished' then
        perform private.check_badges(new.organizer_id);
        for u in select user_id from public.ride_participants
                  where ride_id = new.id and status = 'confirmed' and user_id <> new.organizer_id loop
          perform private.check_badges(u);
        end loop;
      end if;
    when 'solo_trips' then
      if new.status = 'arrived' and old.status is distinct from 'arrived' then
        perform private.check_badges(new.user_id);
        for u in select watcher_id from public.solo_trip_watchers where trip_id = new.id loop
          perform private.check_badges(u);
        end loop;
      end if;
    when 'maintenance_records' then
      perform private.check_badges((select owner_id from public.motorcycles where id = new.moto_id));
    when 'profiles' then
      perform private.check_badges(new.id);
    when 'listings' then
      perform private.check_badges(new.seller_id);
    when 'posts' then
      perform private.check_badges(new.author_id);
    else
      perform private.check_badges(new.user_id);  -- club_members, event_attendees
  end case;
  return null;
end;
$$;
revoke all on function private.badges_after_change() from public, anon, authenticated;

create trigger rides_badges after update of status on public.rides
  for each row execute function private.badges_after_change();
create trigger solo_trips_badges after update of status on public.solo_trips
  for each row execute function private.badges_after_change();
create trigger maintenance_records_badges after insert on public.maintenance_records
  for each row execute function private.badges_after_change();
create trigger profiles_badges after update of avatar_path, city, bio on public.profiles
  for each row execute function private.badges_after_change();
create trigger listings_badges after insert on public.listings
  for each row execute function private.badges_after_change();
create trigger posts_badges after insert on public.posts
  for each row execute function private.badges_after_change();
create trigger club_members_badges after insert on public.club_members
  for each row execute function private.badges_after_change();
create trigger event_attendees_badges after insert on public.event_attendees
  for each row execute function private.badges_after_change();

-- Badges d'un motard. Pour soi : tous, avec la progression ; pour un autre :
-- seulement ceux obtenus (si son profil est visible).
create or replace function public.rider_badges(p_user_id uuid default null)
returns table (code text, title text, description text, period text, awarded_at timestamptz,
               earned boolean, progress numeric, target numeric, sort integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  who uuid := coalesce(p_user_id, uid);
  me boolean := who = uid;
  stats jsonb;
begin
  if not me and not private.can_view_profile(who) then
    return;
  end if;
  if me then
    perform private.check_badges(uid);
    stats := private.rider_stats(uid);
  end if;
  return query
    select k.code, k.title, k.description, null::text, a.awarded_at, a.id is not null,
           case when me then least(coalesce((stats ->> k.metric)::numeric, 0), k.target) end,
           k.target, k.sort
      from private.badge_catalog() k
      left join public.badge_awards a on a.user_id = who and a.code = k.code
     where me or a.id is not null
    union all
    select a.code, a.title,
           case a.code when 'ride_of_month' then 'Meilleure balade du mois' else 'Défi réussi' end,
           a.period, a.awarded_at, true, null::numeric, null::numeric,
           case a.code when 'ride_of_month' then 1 else 2 end
      from public.badge_awards a
     where a.user_id = who and a.code in ('challenge', 'ride_of_month')
    order by 6 desc, 9, 5 desc;
end;
$$;

create or replace function public.my_challenges()
returns table (id uuid, title text, description text, metric text, target integer,
               starts_on date, ends_on date, progress numeric, completed boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  perform private.check_badges(uid);
  return query
    select c.id, c.title, c.description, c.metric, c.target, c.starts_on, c.ends_on,
           least(private.challenge_progress(c, uid), c.target::numeric),
           exists (select 1 from public.badge_awards a
                    where a.user_id = uid and a.code = 'challenge' and a.ref_id = c.id)
      from public.challenges c
     where c.cancelled_at is null
       and c.starts_on <= (now() at time zone 'Africa/Kinshasa')::date
       and c.ends_on >= (now() at time zone 'Africa/Kinshasa')::date - 30
     order by (c.ends_on >= (now() at time zone 'Africa/Kinshasa')::date) desc, c.ends_on;
end;
$$;

-- -----------------------------------------------------------------------------
-- Annonces officielles et meilleure balade du mois
-- -----------------------------------------------------------------------------
alter table public.posts add column is_official boolean not null default false;

create table public.monthly_awards (
  id          uuid primary key default gen_random_uuid(),
  kind        text not null default 'ride_of_month' check (kind in ('ride_of_month')),
  period      text not null check (period ~ '^[0-9]{4}-[0-9]{2}$'),
  ride_id     uuid references public.rides (id) on delete set null,
  club_id     uuid references public.clubs (id) on delete set null,
  distance_km numeric(8, 1),
  post_id     uuid references public.posts (id) on delete set null,
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  unique (kind, period)
);
alter table public.monthly_awards enable row level security;
revoke all on public.monthly_awards from anon, authenticated;
grant select on public.monthly_awards to authenticated;
create policy "monthly_awards: lisibles par tous les motards"
  on public.monthly_awards for select to authenticated using (true);

create or replace function private.require_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  return uid;
end;
$$;
revoke all on function private.require_admin() from public, anon;
grant execute on function private.require_admin() to authenticated;

-- « octobre 2026 »
create or replace function private.month_label(p_period text)
returns text
language sql
immutable
set search_path = ''
as $$
  select (array['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
                'septembre', 'octobre', 'novembre', 'décembre'])[split_part(p_period, '-', 2)::int]
         || ' ' || split_part(p_period, '-', 1);
$$;

create or replace function public.admin_publish_announcement(p_body text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  created uuid;
begin
  if char_length(btrim(coalesce(p_body, ''))) not between 5 and 2000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  insert into public.posts (author_id, audience, body, client_ref, is_official)
  values (uid, 'public', btrim(p_body), gen_random_uuid(), true)
  returning id into created;
  perform private.log_action('announcement.publish', 'post', created, '{}'::jsonb);
  return created;
end;
$$;

create or replace function public.admin_ride_of_month_candidates(p_period text)
returns table (ride_id uuid, title text, club_id uuid, club_name text, organizer_name text,
               participant_count integer, distance_km numeric, finished_at timestamptz,
               already_awarded boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  t0 timestamptz;
begin
  perform private.require_admin();
  if p_period !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  t0 := (to_date(p_period || '-01', 'YYYY-MM-DD')::timestamp) at time zone 'Africa/Kinshasa';
  return query
    select r.id, r.title, r.club_id, c.name, o.display_name, r.participant_count, r.distance_km,
           r.finished_at,
           exists (select 1 from public.monthly_awards m
                    where m.kind = 'ride_of_month' and m.period = p_period)
      from public.rides r
      left join public.clubs c on c.id = r.club_id
      join public.profiles o on o.id = r.organizer_id
     where r.status = 'finished'
       and r.finished_at >= t0 and r.finished_at < t0 + interval '1 month'
     order by r.distance_km desc nulls last, r.participant_count desc
     limit 10;
end;
$$;

create or replace function public.admin_award_ride_of_month(
  p_ride_id uuid, p_period text, p_publish boolean default true, p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  r public.rides;
  club_name text;
  label text;
  award uuid;
  post uuid;
  u uuid;
  new_id uuid;
  n integer := 0;
  t0 timestamptz;
begin
  if p_period !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' or char_length(coalesce(p_message, '')) > 2000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  t0 := (to_date(p_period || '-01', 'YYYY-MM-DD')::timestamp) at time zone 'Africa/Kinshasa';
  select * into r from public.rides where id = p_ride_id and status = 'finished'
     and finished_at >= t0 and finished_at < t0 + interval '1 month';
  if not found then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.monthly_awards where kind = 'ride_of_month' and period = p_period) then
    raise exception 'already_exists' using errcode = 'P0001';
  end if;
  select name into club_name from public.clubs where id = r.club_id;
  label := 'Meilleure balade du mois · ' || private.month_label(p_period);
  insert into public.monthly_awards (period, ride_id, club_id, distance_km, created_by)
  values (p_period, r.id, r.club_id, r.distance_km, uid)
  returning id into award;
  for u in select r.organizer_id
           union select user_id from public.ride_participants
                  where ride_id = r.id and status = 'confirmed' loop
    new_id := null;
    insert into public.badge_awards (user_id, code, title, period, ref_id)
    values (u, 'ride_of_month', label, p_period, r.id)
    on conflict do nothing
    returning id into new_id;
    if new_id is not null then
      perform private.notify(u, 'badge_awarded', null, p_ref => new_id,
        p_data => jsonb_build_object('code', 'ride_of_month', 'title', label));
      n := n + 1;
    end if;
  end loop;
  if p_publish then
    insert into public.posts (author_id, audience, body, client_ref, is_official)
    values (uid, 'public',
            coalesce(nullif(btrim(p_message), ''),
                     label || E' : « ' || r.title || ' »'
                     || coalesce(' avec ' || club_name, '')
                     || coalesce(', ' || replace(to_char(r.distance_km, 'FM999G990'), ',', ' ') || ' km', '')
                     || '. Bravo aux ' || n || ' motards de la balade !'),
            gen_random_uuid(), true)
    returning id into post;
    update public.monthly_awards set post_id = post where id = award;
  end if;
  perform private.log_action('award.ride_of_month', 'ride', r.id,
    jsonb_build_object('period', p_period, 'riders', n));
  return award;
end;
$$;

-- -----------------------------------------------------------------------------
-- Défis : gestion par l'équipe
-- -----------------------------------------------------------------------------
create or replace function public.admin_create_challenge(
  p_title text, p_description text, p_metric text, p_target integer,
  p_starts_on date, p_ends_on date, p_notify boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  created uuid;
begin
  begin
    insert into public.challenges (title, description, metric, target, starts_on, ends_on, created_by)
    values (btrim(p_title), coalesce(btrim(p_description), ''), p_metric, p_target,
            p_starts_on, p_ends_on, uid)
    returning id into created;
  exception when check_violation or not_null_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;
  if p_notify then
    insert into public.notifications (user_id, kind, ref_id, data)
    select p.id, 'challenge_started', created, jsonb_build_object('title', btrim(p_title))
      from public.profiles p;
  end if;
  perform private.log_action('challenge.create', 'challenge', created, '{}'::jsonb);
  return created;
end;
$$;

create or replace function public.admin_cancel_challenge(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  update public.challenges set cancelled_at = now() where id = p_id and cancelled_at is null;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  perform private.log_action('challenge.cancel', 'challenge', p_id, '{}'::jsonb);
end;
$$;

create or replace function public.admin_challenges()
returns table (id uuid, title text, description text, metric text, target integer,
               starts_on date, ends_on date, cancelled_at timestamptz, completed_count integer,
               winners text[])
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return query
    select c.id, c.title, c.description, c.metric, c.target, c.starts_on, c.ends_on, c.cancelled_at,
           (select count(*)::integer from public.badge_awards a
             where a.code = 'challenge' and a.ref_id = c.id),
           coalesce((select array_agg(p.display_name order by a.awarded_at)
                       from (select * from public.badge_awards a2
                              where a2.code = 'challenge' and a2.ref_id = c.id
                              order by a2.awarded_at limit 20) a
                       join public.profiles p on p.id = a.user_id), '{}')
      from public.challenges c
     order by c.cancelled_at nulls first, c.ends_on desc
     limit 100;
end;
$$;

-- Vérification quotidienne (défis lancés après l'activité, rattrapage).
create or replace function private.process_challenges()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid;
  n integer := 0;
begin
  if not exists (select 1 from public.challenges
                  where cancelled_at is null
                    and ends_on >= (now() at time zone 'Africa/Kinshasa')::date - 1) then
    return 0;
  end if;
  for u in select id from public.profiles loop
    n := n + private.check_badges(u);
  end loop;
  return n;
end;
$$;
revoke all on function private.process_challenges() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Suspension par l'équipe
-- -----------------------------------------------------------------------------
create or replace function public.admin_suspend_user(p_user_id uuid, p_days integer, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  v_until timestamptz := case when p_days is null then null else now() + make_interval(days => p_days) end;
begin
  if p_user_id is null or p_user_id = uid
     or exists (select 1 from private.platform_admins where user_id = p_user_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if (p_days is not null and p_days not between 1 and 3650)
     or char_length(btrim(coalesce(p_reason, ''))) not between 3 and 280
     or not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  insert into public.account_suspensions (user_id, until, reason, created_by)
  values (p_user_id, v_until, btrim(p_reason), uid)
  on conflict (user_id) do update
    set until = excluded.until, reason = excluded.reason,
        created_by = excluded.created_by, created_at = now();
  perform private.notify(p_user_id, 'account_suspended', null,
    p_data => jsonb_build_object('until', v_until, 'reason', btrim(p_reason)));
  perform private.log_action('account.suspend', 'user', p_user_id,
    jsonb_build_object('days', p_days, 'reason', btrim(p_reason)));
end;
$$;

create or replace function public.admin_unsuspend_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  delete from public.account_suspensions where user_id = p_user_id;
  if found then
    perform private.notify(p_user_id, 'account_restored', null);
    perform private.log_action('account.restore', 'user', p_user_id, '{}'::jsonb);
  end if;
end;
$$;

create or replace function public.admin_suspended_users()
returns table (user_id uuid, username text, display_name text, until timestamptz,
               reason text, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return query
    select s.user_id, p.username, p.display_name, s.until, s.reason, s.created_at
      from public.account_suspensions s
      join public.profiles p on p.id = s.user_id
     where s.until is null or s.until > now()
     order by s.created_at desc;
end;
$$;

-- Recherche d'un compte (même non visible dans l'annuaire).
create or replace function public.admin_search_users(p_query text)
returns table (id uuid, username text, display_name text, city text, created_at timestamptz,
               suspended boolean, verified boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  q text := lower(btrim(coalesce(p_query, '')));
begin
  perform private.require_admin();
  if char_length(q) < 2 then
    return;
  end if;
  q := replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_');
  return query
    select p.id, p.username, p.display_name, p.city, p.created_at, private.is_suspended(p.id),
           p.verified_until is not null and p.verified_until > now()
      from public.profiles p
     where lower(p.username) like '%' || q || '%' or lower(p.display_name) like '%' || q || '%'
     order by p.username
     limit 30;
end;
$$;

-- Chiffres de la vue d'ensemble.
create or replace function public.admin_stats()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  month_start timestamptz := date_trunc('month', now() at time zone 'Africa/Kinshasa') at time zone 'Africa/Kinshasa';
  active bigint;
begin
  perform private.require_admin();
  -- Connexions des 7 derniers jours (colonne fournie par Supabase Auth).
  if exists (select 1 from information_schema.columns
              where table_schema = 'auth' and table_name = 'users' and column_name = 'last_sign_in_at') then
    execute 'select count(*) from auth.users where last_sign_in_at > now() - interval ''7 days'''
       into active;
  end if;
  return jsonb_build_object(
    'riders_total', (select count(*) from public.profiles),
    'riders_new_7d', (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'active_7d', active,
    'rides_month', (select count(*) from public.rides
                     where status <> 'draft' and starts_at >= month_start),
    'rides_finished_month', (select count(*) from public.rides
                              where status = 'finished' and finished_at >= month_start),
    'sos_month', (select count(*) from public.sos_alerts where created_at >= month_start),
    'sos_active', (select count(*) from public.sos_alerts where status = 'active'),
    'open_reports', (select count(distinct (target_type, target_id)) from public.content_reports
                      where status = 'open'),
    'pending_club_verifications', (select count(*) from public.club_verification_requests
                                    where status = 'pending'),
    'pending_rider_verifications', (select count(*) from public.rider_verification_requests
                                     where status = 'pending'),
    'pending_club_deletions', (select count(*) from public.club_deletion_requests
                                where status = 'pending'),
    'open_feedback', (select count(*) from public.app_feedback where handled_at is null),
    'active_challenges', (select count(*) from public.challenges
                           where cancelled_at is null
                             and ends_on >= (now() at time zone 'Africa/Kinshasa')::date),
    'suspended_accounts', (select count(*) from public.account_suspensions
                            where until is null or until > now()));
end;
$$;

-- -----------------------------------------------------------------------------
-- Fil : les annonces officielles sont signalées comme telles
-- -----------------------------------------------------------------------------
drop function public.feed_posts(uuid, uuid, timestamptz, integer, uuid);
create or replace function public.feed_posts(
  p_club_id uuid default null,
  p_author_id uuid default null,
  p_before timestamptz default null,
  p_limit integer default 20,
  p_post_id uuid default null
)
returns table (
  id uuid,
  author_id uuid,
  author_name text,
  author_avatar text,
  club_id uuid,
  club_name text,
  audience public.post_audience,
  body text,
  moderation public.moderation_state,
  created_at timestamptz,
  media_paths text[],
  comment_count integer,
  reactions jsonb,
  my_reaction public.reaction_kind,
  is_official boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.author_id, a.display_name, a.avatar_path, p.club_id, c.name,
         p.audience, p.body, p.moderation, p.created_at,
         coalesce((select array_agg(m.path order by m.position)
                     from public.post_media m where m.post_id = p.id), '{}'),
         (select count(*)::integer from public.post_comments k
           where k.post_id = p.id and k.moderation = 'visible'
             and not private.is_blocked_between(k.author_id, (select auth.uid()))),
         coalesce((select jsonb_object_agg(r.kind, r.n)
                     from (select kind, count(*) n from public.post_reactions
                            where post_id = p.id group by kind) r), '{}'::jsonb),
         (select r.kind from public.post_reactions r
           where r.post_id = p.id and r.user_id = (select auth.uid())),
         p.is_official
    from public.posts p
    join public.profiles a on a.id = p.author_id
    left join public.clubs c on c.id = p.club_id
   where private.can_view_post(p.id)
     and (p_club_id is null or p.club_id = p_club_id)
     and (p_author_id is null or p.author_id = p_author_id)
     and (p_before is null or p.created_at < p_before)
     and (p_post_id is null or p.id = p_post_id)
   order by p.created_at desc
   limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- -----------------------------------------------------------------------------
-- Notifications
-- -----------------------------------------------------------------------------
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in (
  'ride_join_request', 'ride_joined', 'ride_request_approved',
  'ride_request_rejected', 'ride_removed', 'ride_invitation',
  'ride_locked', 'ride_started', 'ride_finished', 'ride_cancelled',
  'club_join_request', 'club_request_approved', 'club_request_rejected',
  'club_invitation', 'post_comment', 'post_reaction',
  'club_verification_approved', 'club_verification_rejected',
  'club_verification_expiring', 'club_verification_expired',
  'rider_verification_approved', 'rider_verification_rejected',
  'rider_verification_expiring', 'rider_verification_expired',
  'event_coorganizer_invitation', 'event_coorganizer_accepted',
  'event_coorganizer_declined', 'event_cancelled',
  'club_deletion_requested', 'club_deletion_approved', 'club_deletion_rejected',
  'club_deletion_auto', 'shop_suspended', 'shop_restored', 'maintenance_reminder',
  'solo_contact_request', 'solo_contact_accepted', 'solo_trip_started', 'solo_trip_arrived',
  'solo_trip_cancelled', 'solo_trip_overdue', 'solo_trip_no_news', 'solo_check_in',
  'solo_news_request', 'solo_position_request', 'solo_position_shared', 'solo_ok',
  'badge_awarded', 'challenge_started', 'account_suspended', 'account_restored'));

grant execute on function
  public.my_suspension(),
  public.rider_badges(uuid),
  public.my_challenges(),
  public.admin_publish_announcement(text),
  public.admin_ride_of_month_candidates(text),
  public.admin_award_ride_of_month(uuid, text, boolean, text),
  public.admin_create_challenge(text, text, text, integer, date, date, boolean),
  public.admin_cancel_challenge(uuid),
  public.admin_challenges(),
  public.admin_suspend_user(uuid, integer, text),
  public.admin_unsuspend_user(uuid),
  public.admin_suspended_users(),
  public.admin_search_users(text),
  public.admin_stats(),
  public.feed_posts(uuid, uuid, timestamptz, integer, uuid)
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-challenges', '43 1 * * *', 'select private.process_challenges()');
  end if;
end;
$$;
