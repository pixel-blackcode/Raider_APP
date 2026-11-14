-- =============================================================================
-- Rider Group — Migration 0016 : événements moto et mise en avant
-- -----------------------------------------------------------------------------
-- D-56 : un ÉVÉNEMENT MOTO (rassemblement, salon, sortie officielle...) est
-- organisé par un club ou un regroupement VÉRIFIÉ, par ses responsables
-- (propriétaire, administrateurs). D'autres clubs ou regroupements vérifiés
-- peuvent être invités comme co-organisateurs ; ils acceptent ou refusent.
-- Les événements sont visibles de tous les motards connectés ; chacun peut
-- indiquer « J'y vais ».
-- D-57 : RÉACTUALISER une annonce (la remonter en tête du marketplace) est
-- réservé aux motards vérifiés, une fois par 24 h par annonce. Les clubs et
-- regroupements vérifiés passent en tête de la découverte.
-- =============================================================================

create table public.events (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null references public.clubs (id) on delete cascade,
  created_by    uuid references public.profiles (id) on delete set null,
  client_ref    uuid not null,
  title         text not null check (char_length(btrim(title)) between 3 and 120),
  description   text not null default '' check (char_length(description) <= 3000),
  starts_at     timestamptz not null,
  ends_at       timestamptz,
  place_name    text not null check (char_length(btrim(place_name)) between 2 and 160),
  city          text not null check (char_length(btrim(city)) between 2 and 80),
  lat           double precision check (lat is null or lat between -90 and 90),
  lng           double precision check (lng is null or lng between -180 and 180),
  cover_path    text check (cover_path is null or cover_path like id::text || '/%'),
  cancelled_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at),
  check ((lat is null) = (lng is null)),
  unique (club_id, client_ref)
);
create index events_starts_idx on public.events (starts_at);
create index events_club_idx on public.events (club_id);
create index events_created_by_idx on public.events (created_by);

create table public.event_coorganizers (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references public.events (id) on delete cascade,
  club_id     uuid not null references public.clubs (id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  invited_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  responded_at timestamptz,
  unique (event_id, club_id)
);
create index event_coorganizers_club_idx on public.event_coorganizers (club_id);
create index event_coorganizers_invited_by_idx on public.event_coorganizers (invited_by);

create table public.event_attendees (
  event_id   uuid not null references public.events (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);
create index event_attendees_user_idx on public.event_attendees (user_id);

alter table public.events enable row level security;
alter table public.event_coorganizers enable row level security;
alter table public.event_attendees enable row level security;
revoke all on public.events, public.event_coorganizers, public.event_attendees
  from anon, authenticated;
grant select on public.events, public.event_coorganizers to authenticated;

-- Club ou regroupement vérifié et non suspendu ?
create or replace function private.is_verified_club(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.clubs
                  where id = p_club_id and suspended_at is null and verified_at is not null
                    and (verified_until is null or verified_until > now()));
$$;

-- Gestion : responsables du club organisateur ou d'un co-organisateur accepté.
create or replace function private.can_manage_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.events e
     where e.id = p_event_id
       and (private.has_club_role(e.club_id, 'admin')
            or exists (select 1 from public.event_coorganizers o
                        where o.event_id = e.id and o.status = 'accepted'
                          and private.has_club_role(o.club_id, 'admin'))));
$$;

create policy "events: visibles des motards connectés"
  on public.events for select to authenticated
  using (exists (select 1 from public.clubs c where c.id = club_id and c.suspended_at is null));
create policy "event_coorganizers: visibles des motards connectés"
  on public.event_coorganizers for select to authenticated
  using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-media', 'event-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "event-media: lecture par les motards connectés"
  on storage.objects for select to authenticated
  using (bucket_id = 'event-media');
create policy "event-media: ajout par les gestionnaires"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'event-media'
              and private.can_manage_event(private.try_uuid((storage.foldername(name))[1])));
create policy "event-media: suppression par les gestionnaires"
  on storage.objects for delete to authenticated
  using (bucket_id = 'event-media'
         and private.can_manage_event(private.try_uuid((storage.foldername(name))[1])));

create or replace function private.check_event_input(
  p_title text, p_description text, p_starts_at timestamptz, p_ends_at timestamptz,
  p_place_name text, p_city text, p_lat double precision, p_lng double precision
)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if char_length(btrim(coalesce(p_title, ''))) not between 3 and 120
     or char_length(coalesce(p_description, '')) > 3000
     or p_starts_at is null
     or (p_ends_at is not null and p_ends_at <= p_starts_at)
     or char_length(btrim(coalesce(p_place_name, ''))) not between 2 and 160
     or char_length(btrim(coalesce(p_city, ''))) not between 2 and 80
     or ((p_lat is null) <> (p_lng is null))
     or (p_lat is not null and (p_lat not between -90 and 90 or p_lng not between -180 and 180)) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.create_event(
  p_club_id uuid,
  p_client_ref uuid,
  p_title text,
  p_starts_at timestamptz,
  p_place_name text,
  p_city text,
  p_description text default '',
  p_ends_at timestamptz default null,
  p_lat double precision default null,
  p_lng double precision default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created uuid;
begin
  if not private.has_club_role(p_club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not private.is_verified_club(p_club_id) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  perform private.check_event_input(p_title, p_description, p_starts_at, p_ends_at,
                                    p_place_name, p_city, p_lat, p_lng);
  if p_starts_at < now() - interval '1 hour' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select id into created from public.events where club_id = p_club_id and client_ref = p_client_ref;
  if found then
    return created;
  end if;
  insert into public.events (club_id, created_by, client_ref, title, description, starts_at,
                             ends_at, place_name, city, lat, lng)
  values (p_club_id, uid, p_client_ref, btrim(p_title), coalesce(btrim(p_description), ''),
          p_starts_at, p_ends_at, btrim(p_place_name), btrim(p_city), p_lat, p_lng)
  returning id into created;
  perform private.log_action('event.create', 'event', created);
  return created;
end;
$$;

create or replace function public.update_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_place_name text,
  p_city text,
  p_description text default '',
  p_ends_at timestamptz default null,
  p_lat double precision default null,
  p_lng double precision default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_user();
  if not private.can_manage_event(p_event_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  perform private.check_event_input(p_title, p_description, p_starts_at, p_ends_at,
                                    p_place_name, p_city, p_lat, p_lng);
  update public.events
     set title = btrim(p_title), description = coalesce(btrim(p_description), ''),
         starts_at = p_starts_at, ends_at = p_ends_at, place_name = btrim(p_place_name),
         city = btrim(p_city), lat = p_lat, lng = p_lng, updated_at = now()
   where id = p_event_id and cancelled_at is null;
  if not found then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.set_event_cover(p_event_id uuid, p_path text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  old text;
begin
  perform private.require_user();
  if not private.can_manage_event(p_event_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_path is not null and (
       p_path not like p_event_id::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'event-media' and o.name = p_path)) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select cover_path into old from public.events where id = p_event_id;
  update public.events set cover_path = p_path, updated_at = now() where id = p_event_id;
  return old;
end;
$$;

create or replace function public.cancel_event(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ev public.events;
  a record;
begin
  if not private.can_manage_event(p_event_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.events set cancelled_at = now(), updated_at = now()
   where id = p_event_id and cancelled_at is null
  returning * into ev;
  if not found then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  for a in select user_id from public.event_attendees where event_id = p_event_id loop
    perform private.notify(a.user_id, 'event_cancelled', uid, p_club => ev.club_id,
                           p_ref => ev.id, p_data => jsonb_build_object('title', ev.title));
  end loop;
  perform private.log_action('event.cancel', 'event', p_event_id);
end;
$$;

-- Invitation d'un club ou regroupement vérifié comme co-organisateur.
create or replace function public.invite_event_coorganizer(p_event_id uuid, p_club_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ev public.events;
  created uuid;
  m record;
begin
  if not private.can_manage_event(p_event_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select * into ev from public.events where id = p_event_id;
  if ev.cancelled_at is not null or p_club_id = ev.club_id then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if not private.is_verified_club(p_club_id) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  insert into public.event_coorganizers (event_id, club_id, invited_by)
  values (p_event_id, p_club_id, uid)
  on conflict (event_id, club_id) do update
    set status = 'pending', invited_by = excluded.invited_by, responded_at = null,
        created_at = now()
    where public.event_coorganizers.status = 'declined'
  returning id into created;
  if created is null then
    raise exception 'already_invited' using errcode = 'P0001';
  end if;
  for m in select user_id from public.club_members
            where club_id = p_club_id and role in ('owner', 'admin') loop
    perform private.notify(m.user_id, 'event_coorganizer_invitation', uid, p_club => p_club_id,
                           p_ref => created,
                           p_data => jsonb_build_object('event_id', ev.id, 'title', ev.title));
  end loop;
  return created;
end;
$$;

create or replace function public.respond_event_coorganizer(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  inv public.event_coorganizers;
  ev public.events;
begin
  select * into inv from public.event_coorganizers where id = p_invitation_id for update;
  if not found or not private.has_club_role(inv.club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if inv.status <> 'pending' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  update public.event_coorganizers
     set status = case when p_accept then 'accepted' else 'declined' end, responded_at = now()
   where id = inv.id;
  select * into ev from public.events where id = inv.event_id;
  perform private.notify(inv.invited_by,
    case when p_accept then 'event_coorganizer_accepted' else 'event_coorganizer_declined' end,
    uid, p_club => inv.club_id, p_ref => ev.id,
    p_data => jsonb_build_object('event_id', ev.id, 'title', ev.title));
end;
$$;

-- Un co-organisateur se retire, ou les organisateurs retirent un co-organisateur.
create or replace function public.remove_event_coorganizer(p_event_id uuid, p_club_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_user();
  if not (private.has_club_role(p_club_id, 'admin')
          or exists (select 1 from public.events e
                      where e.id = p_event_id and private.has_club_role(e.club_id, 'admin'))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.event_coorganizers where event_id = p_event_id and club_id = p_club_id;
end;
$$;

create or replace function public.set_event_attendance(p_event_id uuid, p_going boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not exists (select 1 from public.events e
                  join public.clubs c on c.id = e.club_id and c.suspended_at is null
                 where e.id = p_event_id and e.cancelled_at is null
                   and coalesce(e.ends_at, e.starts_at + interval '1 day') > now()) then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if p_going then
    insert into public.event_attendees (event_id, user_id) values (p_event_id, uid)
    on conflict do nothing;
  else
    delete from public.event_attendees where event_id = p_event_id and user_id = uid;
  end if;
end;
$$;

-- Liste des événements : à venir (par date) ou passés, ou un seul.
create or replace function public.list_events(
  p_event_id uuid default null,
  p_club_id uuid default null,
  p_include_past boolean default false,
  p_limit integer default 50
)
returns table (
  id uuid,
  club_id uuid,
  club_name text,
  club_is_regroupement boolean,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  place_name text,
  city text,
  lat double precision,
  lng double precision,
  cover_path text,
  cancelled_at timestamptz,
  attendee_count integer,
  i_am_going boolean,
  can_manage boolean,
  coorganizers jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id, e.club_id, c.name, c.kind = 'regroupement', e.title, e.description,
         e.starts_at, e.ends_at, e.place_name, e.city, e.lat, e.lng, e.cover_path,
         e.cancelled_at,
         (select count(*)::integer from public.event_attendees a where a.event_id = e.id),
         exists (select 1 from public.event_attendees a
                  where a.event_id = e.id and a.user_id = (select auth.uid())),
         private.can_manage_event(e.id),
         coalesce((select jsonb_agg(jsonb_build_object(
                     'invitation_id', o.id, 'club_id', o.club_id, 'name', oc.name,
                     'status', o.status) order by oc.name)
                     from public.event_coorganizers o
                     join public.clubs oc on oc.id = o.club_id
                    where o.event_id = e.id
                      and (o.status = 'accepted' or private.can_manage_event(e.id))),
                  '[]'::jsonb)
    from public.events e
    join public.clubs c on c.id = e.club_id and c.suspended_at is null
   where (select auth.uid()) is not null
     and (p_event_id is null or e.id = p_event_id)
     and (p_club_id is null or e.club_id = p_club_id
          or exists (select 1 from public.event_coorganizers o
                      where o.event_id = e.id and o.club_id = p_club_id and o.status = 'accepted'))
     and (p_event_id is not null or p_include_past
          or (e.cancelled_at is null and coalesce(e.ends_at, e.starts_at + interval '1 day') > now()))
   order by e.starts_at
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
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
  'event_coorganizer_declined', 'event_cancelled'));

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
-- Réactualisation des annonces (motards vérifiés) et badge du vendeur
-- -----------------------------------------------------------------------------
create or replace function public.bump_listing(p_listing_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  l public.listings;
begin
  select * into l from public.listings where id = p_listing_id for update;
  if not found or l.seller_id <> uid then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles p where p.id = uid and p.verified_at is not null
                   and (p.verified_until is null or p.verified_until > now())) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  if l.status = 'sold' or l.moderation <> 'visible' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if l.bumped_at > now() - interval '24 hours' then
    raise exception 'too_frequent' using errcode = 'P0001';
  end if;
  update public.listings set bumped_at = now() where id = l.id;
  perform private.log_action('listing.bump', 'listing', l.id);
  return now();
end;
$$;

drop function public.search_listings(text, public.listing_category, text, numeric,
  public.currency_code, boolean, boolean, uuid, uuid, timestamptz, integer);
create function public.search_listings(
  p_query text default null,
  p_category public.listing_category default null,
  p_city text default null,
  p_max_price numeric default null,
  p_currency public.currency_code default null,
  p_include_sold boolean default false,
  p_favorites_only boolean default false,
  p_seller_id uuid default null,
  p_listing_id uuid default null,
  p_before timestamptz default null,
  p_limit integer default 30
)
returns table (
  id uuid,
  seller_id uuid,
  seller_name text,
  seller_avatar text,
  category public.listing_category,
  title text,
  description text,
  price numeric,
  currency public.currency_code,
  condition public.listing_condition,
  city text,
  area text,
  status public.listing_status,
  moderation public.moderation_state,
  created_at timestamptz,
  bumped_at timestamptz,
  media_paths text[],
  is_favorite boolean,
  favorite_count integer,
  seller_verified boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select l.id, l.seller_id, p.display_name, p.avatar_path, l.category, l.title, l.description,
         l.price, l.currency, l.condition, l.city, l.area, l.status, l.moderation,
         l.created_at, l.bumped_at,
         coalesce((select array_agg(m.path order by m.position)
                     from public.listing_media m where m.listing_id = l.id), '{}'),
         exists (select 1 from public.listing_favorites f
                  where f.listing_id = l.id and f.user_id = (select auth.uid())),
         (select count(*)::integer from public.listing_favorites f where f.listing_id = l.id),
         p.verified_at is not null and (p.verified_until is null or p.verified_until > now())
    from public.listings l
    join public.profiles p on p.id = l.seller_id
   where private.can_view_listing(l.id)
     and (p_listing_id is null or l.id = p_listing_id)
     and (p_category is null or l.category = p_category)
     and (p_currency is null or l.currency = p_currency)
     and (p_max_price is null or (l.price is not null and l.price <= p_max_price))
     and (p_city is null or btrim(p_city) = '' or private.match_score(p_city, l.city) >= 0.4)
     and (p_seller_id is null or l.seller_id = p_seller_id)
     and (p_include_sold or l.status <> 'sold' or l.seller_id = (select auth.uid())
          or p_listing_id is not null)
     and (not p_favorites_only or exists (select 1 from public.listing_favorites f
                                           where f.listing_id = l.id and f.user_id = (select auth.uid())))
     and (p_before is null or l.bumped_at < p_before)
     and (p_query is null or char_length(btrim(p_query)) < 2
          or private.match_score(p_query, l.title || ' ' || l.description || ' ' || l.city) >= 0.3)
   order by case when p_query is null or char_length(btrim(p_query)) < 2 then 0
                 else private.match_score(p_query, l.title) end desc,
            l.bumped_at desc
   limit least(greatest(coalesce(p_limit, 30), 1), 50);
$$;

-- Découverte : clubs et regroupements vérifiés en tête.
create or replace function public.search_clubs(p_query text, p_limit integer default 50)
returns setof public.clubs
language sql
stable
security definer
set search_path = ''
as $$
  select c.* from public.clubs c
   where c.is_listed and c.suspended_at is null
     and (char_length(btrim(coalesce(p_query, ''))) < 2
          or greatest(private.match_score(p_query, c.name),
                      private.match_score(p_query, c.city)) >= 0.3)
   order by case when char_length(btrim(coalesce(p_query, ''))) < 2 then 0
                 else greatest(private.match_score(p_query, c.name),
                               private.match_score(p_query, c.city)) end
              + case when private.is_verified_club(c.id) then 0.15 else 0 end desc,
            c.member_count desc, c.name
   limit least(greatest(coalesce(p_limit, 50), 1), 50);
$$;

revoke all on function
  private.is_verified_club(uuid),
  private.check_event_input(text, text, timestamptz, timestamptz, text, text, double precision, double precision)
from public, anon;
grant execute on function private.is_verified_club(uuid), private.can_manage_event(uuid)
  to authenticated;

grant execute on function
  public.create_event(uuid, uuid, text, timestamptz, text, text, text, timestamptz, double precision, double precision),
  public.update_event(uuid, text, timestamptz, text, text, text, timestamptz, double precision, double precision),
  public.set_event_cover(uuid, text),
  public.cancel_event(uuid),
  public.invite_event_coorganizer(uuid, uuid),
  public.respond_event_coorganizer(uuid, boolean),
  public.remove_event_coorganizer(uuid, uuid),
  public.set_event_attendance(uuid, boolean),
  public.list_events(uuid, uuid, boolean, integer),
  public.bump_listing(uuid),
  public.search_listings(text, public.listing_category, text, numeric, public.currency_code,
                         boolean, boolean, uuid, uuid, timestamptz, integer)
to authenticated;
