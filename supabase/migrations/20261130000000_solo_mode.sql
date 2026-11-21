-- =============================================================================
-- Rider Group — Migration 0025 : Mode solo (Mission 10 bis)
-- -----------------------------------------------------------------------------
-- D-70 : un motard qui rentre seul choisit 1 ou 2 « proches » (des motards qui
-- ont accepté de suivre ses trajets), une heure d'arrivée prévue, et partage
-- sa position s'il le veut. « Je suis arrivé » prévient les proches. À l'heure
-- prévue sans confirmation : on lui demande s'il est bien arrivé et les proches
-- sont prévenus ; ils peuvent demander de ses nouvelles ou sa position. Sans
-- nouvelles 45 minutes après l'heure prévue : simple rappel aux proches.
-- La position n'est visible que du motard et de ses proches, pendant le trajet,
-- puis effacée à la fin.
-- =============================================================================

-- Proches : contact_id accepte de suivre les trajets de owner_id.
create table public.solo_contacts (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references public.profiles (id) on delete cascade,
  contact_id   uuid not null references public.profiles (id) on delete cascade,
  status       text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  unique (owner_id, contact_id),
  check (owner_id <> contact_id)
);
create index solo_contacts_contact_idx on public.solo_contacts (contact_id);

create table public.solo_trips (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.profiles (id) on delete cascade,
  destination           text check (destination is null or char_length(destination) <= 60),
  status                text not null default 'active'
                          check (status in ('active', 'arrived', 'cancelled', 'expired')),
  started_at            timestamptz not null default now(),
  expected_at           timestamptz not null,
  share_location        boolean not null default false,
  last_lat              double precision check (last_lat is null or last_lat between -90 and 90),
  last_lng              double precision check (last_lng is null or last_lng between -180 and 180),
  last_accuracy_m       real,
  last_position_at      timestamptz,
  last_position_sent_at timestamptz,
  last_ok_at            timestamptz,
  overdue_at            timestamptz,
  no_news_notified_at   timestamptz,
  ended_at              timestamptz
);
create unique index solo_trips_one_active on public.solo_trips (user_id) where status = 'active';
create index solo_trips_active_idx on public.solo_trips (expected_at) where status = 'active';

create table public.solo_trip_watchers (
  trip_id       uuid not null references public.solo_trips (id) on delete cascade,
  watcher_id    uuid not null references public.profiles (id) on delete cascade,
  last_asked_at timestamptz,
  primary key (trip_id, watcher_id)
);
create index solo_trip_watchers_watcher_idx on public.solo_trip_watchers (watcher_id);

alter table public.solo_contacts enable row level security;
alter table public.solo_trips enable row level security;
alter table public.solo_trip_watchers enable row level security;
revoke all on public.solo_contacts, public.solo_trips, public.solo_trip_watchers from anon, authenticated;
grant select on public.solo_contacts, public.solo_trips, public.solo_trip_watchers to authenticated;

create or replace function private.watches_solo_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.solo_trip_watchers
                  where trip_id = p_trip_id and watcher_id = (select auth.uid()));
$$;
grant execute on function private.watches_solo_trip(uuid) to authenticated;

create or replace function private.owns_solo_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.solo_trips
                  where id = p_trip_id and user_id = (select auth.uid()));
$$;
grant execute on function private.owns_solo_trip(uuid) to authenticated;

create policy "solo_contacts: les deux motards"
  on public.solo_contacts for select to authenticated
  using (owner_id = (select auth.uid()) or contact_id = (select auth.uid()));
create policy "solo_trips: le motard et ses proches"
  on public.solo_trips for select to authenticated
  using (user_id = (select auth.uid()) or private.watches_solo_trip(id));
create policy "solo_trip_watchers: le motard et le proche"
  on public.solo_trip_watchers for select to authenticated
  using (watcher_id = (select auth.uid()) or private.owns_solo_trip(trip_id));

-- Prévient tous les proches d'un trajet.
create or replace function private.notify_solo_watchers(p_trip_id uuid, p_kind text, p_data jsonb default '{}')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips;
  w uuid;
begin
  select * into t from public.solo_trips where id = p_trip_id;
  for w in select watcher_id from public.solo_trip_watchers where trip_id = p_trip_id loop
    perform private.notify(w, p_kind, t.user_id, p_ref => t.id,
      p_data => jsonb_build_object('destination', t.destination, 'expected_at', t.expected_at)
                || coalesce(p_data, '{}'));
  end loop;
end;
$$;
revoke all on function private.notify_solo_watchers(uuid, text, jsonb) from public, anon, authenticated;

-- Trajet actif du motard connecté (verrouillé), sinon erreur.
create or replace function private.my_active_solo_trip(p_trip_id uuid)
returns public.solo_trips
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips;
begin
  select * into t from public.solo_trips
   where id = p_trip_id and user_id = (select auth.uid()) and status = 'active'
   for update;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  return t;
end;
$$;
revoke all on function private.my_active_solo_trip(uuid) from public, anon;
grant execute on function private.my_active_solo_trip(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Proches
-- -----------------------------------------------------------------------------
create or replace function public.request_solo_contact(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created uuid;
begin
  if p_user_id is null or p_user_id = uid
     or not exists (select 1 from public.profiles where id = p_user_id)
     or private.is_blocked_between(uid, p_user_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.solo_contacts where owner_id = uid and contact_id = p_user_id) then
    return;  -- déjà demandé ou déjà accepté
  end if;
  if (select count(*) from public.solo_contacts
       where owner_id = uid and created_at > now() - interval '24 hours') >= 10
     or (select count(*) from public.solo_contacts where owner_id = uid) >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.solo_contacts (owner_id, contact_id) values (uid, p_user_id)
  returning id into created;
  perform private.notify(p_user_id, 'solo_contact_request', uid, p_ref => created);
end;
$$;

create or replace function public.respond_solo_contact(p_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  c public.solo_contacts;
begin
  select * into c from public.solo_contacts
   where id = p_id and contact_id = uid and status = 'pending' for update;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_accept then
    update public.solo_contacts set status = 'accepted', responded_at = now() where id = p_id;
    perform private.notify(c.owner_id, 'solo_contact_accepted', uid, p_ref => p_id);
  else
    delete from public.solo_contacts where id = p_id;
  end if;
end;
$$;

-- L'un ou l'autre peut mettre fin au lien ; le proche quitte aussi le trajet en cours.
create or replace function public.remove_solo_contact(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  c public.solo_contacts;
begin
  select * into c from public.solo_contacts
   where id = p_id and (owner_id = uid or contact_id = uid);
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.solo_trip_watchers w
   using public.solo_trips t
   where w.trip_id = t.id and t.user_id = c.owner_id and t.status = 'active'
     and w.watcher_id = c.contact_id;
  delete from public.solo_contacts where id = p_id;
end;
$$;

create or replace function public.my_solo_contacts()
returns table (id uuid, user_id uuid, display_name text, avatar_path text,
               status text, incoming boolean, created_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, p.id, p.display_name,
         case when private.can_view_avatar(p.id) then p.avatar_path end,
         c.status, c.contact_id = (select auth.uid()), c.created_at
    from public.solo_contacts c
    join public.profiles p
      on p.id = case when c.owner_id = (select auth.uid()) then c.contact_id else c.owner_id end
   where c.owner_id = (select auth.uid()) or c.contact_id = (select auth.uid())
   order by c.status desc, p.display_name;
$$;

-- -----------------------------------------------------------------------------
-- Trajets
-- -----------------------------------------------------------------------------
create or replace function public.start_solo_trip(
  p_watchers uuid[],
  p_minutes integer,
  p_share_location boolean default false,
  p_destination text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ws uuid[];
  created uuid;
begin
  select array_agg(distinct w) into ws from unnest(p_watchers) w where w is not null;
  if coalesce(cardinality(ws), 0) not between 1 and 2
     or p_minutes is null or p_minutes not between 5 and 720
     or char_length(coalesce(p_destination, '')) > 60 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if (select count(*) from public.solo_contacts
       where owner_id = uid and status = 'accepted' and contact_id = any (ws)) <> cardinality(ws) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.solo_trips where user_id = uid and status = 'active') then
    raise exception 'already_active' using errcode = 'P0001';
  end if;
  if (select count(*) from public.solo_trips
       where user_id = uid and started_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.solo_trips (user_id, destination, expected_at, share_location)
  values (uid, nullif(btrim(p_destination), ''), now() + make_interval(mins => p_minutes),
          coalesce(p_share_location, false))
  returning id into created;
  insert into public.solo_trip_watchers (trip_id, watcher_id) select created, unnest(ws);
  perform private.notify_solo_watchers(created, 'solo_trip_started');
  return created;
end;
$$;

-- Position en continu (seulement si le motard a choisi de la partager).
create or replace function public.update_solo_location(
  p_trip_id uuid, p_lat double precision, p_lng double precision, p_accuracy_m real default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
begin
  if not t.share_location then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  update public.solo_trips
     set last_lat = p_lat, last_lng = p_lng, last_accuracy_m = p_accuracy_m, last_position_at = now()
   where id = t.id;
end;
$$;

create or replace function public.set_solo_sharing(p_trip_id uuid, p_share boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
begin
  update public.solo_trips
     set share_location = coalesce(p_share, false),
         last_lat = case when p_share then last_lat end,
         last_lng = case when p_share then last_lng end,
         last_accuracy_m = case when p_share then last_accuracy_m end,
         last_position_at = case when p_share then last_position_at end
   where id = t.id;
end;
$$;

-- Envoi ponctuel de la position aux proches (réponse à « Demander sa position »).
create or replace function public.send_solo_position(
  p_trip_id uuid, p_lat double precision, p_lng double precision, p_accuracy_m real default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
begin
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if t.last_position_sent_at > now() - interval '1 minute' then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  update public.solo_trips
     set last_lat = p_lat, last_lng = p_lng, last_accuracy_m = p_accuracy_m,
         last_position_at = now(), last_position_sent_at = now(), last_ok_at = now()
   where id = t.id;
  perform private.notify_solo_watchers(t.id, 'solo_position_shared');
end;
$$;

-- « Je vais bien » (avec, au besoin, du temps en plus).
create or replace function public.solo_im_ok(p_trip_id uuid, p_extra_minutes integer default 0)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
  next_at timestamptz := t.expected_at;
begin
  if coalesce(p_extra_minutes, 0) not between 0 and 240 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if coalesce(p_extra_minutes, 0) > 0 then
    next_at := greatest(t.expected_at, now()) + make_interval(mins => p_extra_minutes);
  end if;
  update public.solo_trips
     set expected_at = next_at, last_ok_at = now(),
         overdue_at = case when next_at > now() then null else overdue_at end,
         no_news_notified_at = case when next_at > now() then null else no_news_notified_at end
   where id = t.id;
  perform private.notify_solo_watchers(t.id, 'solo_ok');
  return next_at;
end;
$$;

create or replace function public.arrive_solo_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
begin
  update public.solo_trips
     set status = 'arrived', ended_at = now(), share_location = false,
         last_lat = null, last_lng = null, last_accuracy_m = null, last_position_at = null
   where id = t.id;
  perform private.notify_solo_watchers(t.id, 'solo_trip_arrived');
end;
$$;

create or replace function public.cancel_solo_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips := private.my_active_solo_trip(p_trip_id);
begin
  update public.solo_trips
     set status = 'cancelled', ended_at = now(), share_location = false,
         last_lat = null, last_lng = null, last_accuracy_m = null, last_position_at = null
   where id = t.id;
  perform private.notify_solo_watchers(t.id, 'solo_trip_cancelled');
end;
$$;

-- Un proche demande des nouvelles ou la position (une fois toutes les 5 minutes).
create or replace function public.ask_solo_news(p_trip_id uuid, p_what text default 'news')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  t public.solo_trips;
  w public.solo_trip_watchers;
begin
  if p_what not in ('news', 'position') then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select * into w from public.solo_trip_watchers
   where trip_id = p_trip_id and watcher_id = uid for update;
  select * into t from public.solo_trips where id = p_trip_id and status = 'active';
  if w.trip_id is null or t.id is null then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if w.last_asked_at > now() - interval '5 minutes' then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  update public.solo_trip_watchers set last_asked_at = now()
   where trip_id = p_trip_id and watcher_id = uid;
  perform private.notify(t.user_id,
    case p_what when 'position' then 'solo_position_request' else 'solo_news_request' end,
    uid, p_ref => t.id);
end;
$$;

-- Trajets en cours (les miens et ceux que je suis), et ceux finis depuis moins de 12 h.
create or replace function public.my_solo_trips()
returns table (
  id uuid, user_id uuid, display_name text, avatar_path text, mine boolean,
  destination text, status text, started_at timestamptz, expected_at timestamptz,
  share_location boolean, last_lat double precision, last_lng double precision,
  last_accuracy_m real, last_position_at timestamptz, last_ok_at timestamptz,
  overdue_at timestamptz, ended_at timestamptz, watchers jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select t.id, t.user_id, p.display_name,
         case when private.can_view_avatar(p.id) then p.avatar_path end,
         t.user_id = (select auth.uid()),
         t.destination, t.status, t.started_at, t.expected_at, t.share_location,
         t.last_lat, t.last_lng, t.last_accuracy_m, t.last_position_at, t.last_ok_at,
         t.overdue_at, t.ended_at,
         (select coalesce(jsonb_agg(jsonb_build_object('user_id', q.id, 'display_name', q.display_name)
                                    order by q.display_name), '[]')
            from public.solo_trip_watchers w join public.profiles q on q.id = w.watcher_id
           where w.trip_id = t.id)
    from public.solo_trips t
    join public.profiles p on p.id = t.user_id
   where (t.user_id = (select auth.uid())
          or exists (select 1 from public.solo_trip_watchers w
                      where w.trip_id = t.id and w.watcher_id = (select auth.uid())))
     and (t.status = 'active' or t.ended_at > now() - interval '12 hours')
   order by (t.status = 'active') desc, t.started_at desc
   limit 20;
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
  'solo_news_request', 'solo_position_request', 'solo_position_shared', 'solo_ok'));

-- La demande « suivre mes trajets » se traite depuis la cloche.
create or replace function public.my_notifications(p_limit integer default 50)
returns table (
  id uuid,
  kind text,
  actor_id uuid,
  actor_name text,
  actor_avatar text,
  ride_id uuid,
  ride_title text,
  club_id uuid,
  club_name text,
  post_id uuid,
  ref_id uuid,
  data jsonb,
  created_at timestamptz,
  read_at timestamptz,
  actionable boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select n.id, n.kind, n.actor_id, a.display_name, a.avatar_path,
         n.ride_id, r.title, n.club_id, c.name, n.post_id, n.ref_id, n.data,
         n.created_at, n.read_at,
         case n.kind
           when 'ride_join_request' then exists (
             select 1 from public.ride_participants p
              where p.ride_id = n.ride_id and p.user_id = n.ref_id and p.status = 'pending')
           when 'ride_invitation' then exists (
             select 1 from public.ride_invitations i where i.id = n.ref_id and i.status = 'pending')
           when 'club_join_request' then exists (
             select 1 from public.club_join_requests q where q.id = n.ref_id and q.status = 'pending')
           when 'club_invitation' then exists (
             select 1 from public.club_invitations i where i.id = n.ref_id and i.status = 'pending')
           when 'event_coorganizer_invitation' then exists (
             select 1 from public.event_coorganizers o where o.id = n.ref_id and o.status = 'pending')
           when 'solo_contact_request' then exists (
             select 1 from public.solo_contacts s where s.id = n.ref_id and s.status = 'pending')
           else false
         end
    from public.notifications n
    left join public.profiles a on a.id = n.actor_id
    left join public.rides r on r.id = n.ride_id
    left join public.clubs c on c.id = n.club_id
   where n.user_id = (select auth.uid())
   order by n.created_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

-- -----------------------------------------------------------------------------
-- Surveillance (toutes les 5 minutes)
-- -----------------------------------------------------------------------------
create or replace function private.process_solo_trips()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.solo_trips;
  n integer := 0;
begin
  -- Heure prévue dépassée : on demande au motard, on prévient les proches.
  for t in select * from public.solo_trips
            where status = 'active' and overdue_at is null and expected_at <= now()
            for update skip locked loop
    update public.solo_trips set overdue_at = now() where id = t.id;
    perform private.notify(t.user_id, 'solo_check_in', null, p_ref => t.id,
      p_data => jsonb_build_object('destination', t.destination, 'expected_at', t.expected_at));
    perform private.notify_solo_watchers(t.id, 'solo_trip_overdue');
    n := n + 1;
  end loop;
  -- Toujours sans nouvelles 45 minutes après : simple rappel aux proches.
  for t in select * from public.solo_trips
            where status = 'active' and overdue_at <= now() - interval '45 minutes'
              and no_news_notified_at is null
              and (last_ok_at is null or last_ok_at < overdue_at)
            for update skip locked loop
    update public.solo_trips set no_news_notified_at = now() where id = t.id;
    perform private.notify_solo_watchers(t.id, 'solo_trip_no_news');
    n := n + 1;
  end loop;
  -- Trajet oublié : clos 12 h après l'heure prévue, position effacée.
  update public.solo_trips
     set status = 'expired', ended_at = now(), share_location = false,
         last_lat = null, last_lng = null, last_accuracy_m = null, last_position_at = null
   where status = 'active' and expected_at < now() - interval '12 hours';
  -- Historique conservé 30 jours.
  delete from public.solo_trips where status <> 'active' and ended_at < now() - interval '30 days';
  return n;
end;
$$;
revoke all on function private.process_solo_trips() from public, anon, authenticated;

grant execute on function
  public.request_solo_contact(uuid),
  public.respond_solo_contact(uuid, boolean),
  public.remove_solo_contact(uuid),
  public.my_solo_contacts(),
  public.start_solo_trip(uuid[], integer, boolean, text),
  public.update_solo_location(uuid, double precision, double precision, real),
  public.set_solo_sharing(uuid, boolean),
  public.send_solo_position(uuid, double precision, double precision, real),
  public.solo_im_ok(uuid, integer),
  public.arrive_solo_trip(uuid),
  public.cancel_solo_trip(uuid),
  public.ask_solo_news(uuid, text),
  public.my_solo_trips()
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-solo-trips', '*/5 * * * *', 'select private.process_solo_trips()');
  end if;
end;
$$;
