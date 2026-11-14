-- =============================================================================
-- Rider Group — Migration 0011 : marketplace et recherche tolérante (Mission 08)
-- -----------------------------------------------------------------------------
-- Cahier des charges §10 (Module G), décisions D-47 à D-50 :
--   * petites annonces entre particuliers, SANS paiement ni transaction dans
--     l'application (critère 14) : prix indicatif, contact par messagerie ;
--   * catégories : motos, pièces, casques, équipements de protection,
--     accessoires, autres ;
--   * jusqu'à 10 photos (bucket privé `listing-media`) ;
--   * statut : disponible, réservé, vendu ; favoris ; signalement ;
--   * recherche tolérante (accents, casse, « ph » = « f », lettres doublées,
--     fautes légères) sur les annonces, les motards et les clubs ;
--   * publications : jusqu'à 10 photos (au lieu de 4).
--
-- Codes d'erreur : not_allowed, invalid_input, rate_limited, listing_not_found
-- =============================================================================

create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- Forme « pliée » d'un texte pour la recherche : minuscules, sans accents,
-- « ph » → « f », lettres répétées réduites (Phoenix ≈ Fenix ≈ phœnix).
create or replace function private.fold(p_text text)
returns text
language sql
immutable
parallel safe
-- Droits du propriétaire : les fonctions d'extension (unaccent, trigrammes)
-- n'ont pas à être exposées aux utilisateurs.
security definer
set search_path = ''
as $$
  select regexp_replace(
           replace(lower(extensions.unaccent('extensions.unaccent'::regdictionary, coalesce(p_text, ''))),
                   'ph', 'f'),
           '(.)\1+', '\1', 'g');
$$;
grant execute on function private.fold(text) to authenticated;

-- Score de correspondance (0 à 1) entre une recherche et un texte.
create or replace function private.match_score(p_query text, p_text text)
returns real
language sql
immutable
parallel safe
security definer
set search_path = ''
as $$
  select case
    when private.fold(p_query) = '' then 0
    when private.fold(p_text) like '%' || private.fold(p_query) || '%' then 1
    else greatest(extensions.similarity(private.fold(p_text), private.fold(p_query)),
                  extensions.word_similarity(private.fold(p_query), private.fold(p_text)))
  end;
$$;
grant execute on function private.match_score(text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Recherche tolérante : motards et clubs
-- -----------------------------------------------------------------------------
create index profiles_search_idx on public.profiles
  using gin ((private.fold(display_name || ' ' || username)) extensions.gin_trgm_ops);
create index clubs_search_idx on public.clubs
  using gin ((private.fold(name || ' ' || city)) extensions.gin_trgm_ops);

create or replace function public.search_riders(p_query text, p_limit integer default 20)
returns table (id uuid, username text, display_name text, city text, avatar_path text, score real)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.username, p.display_name, p.city, p.avatar_path,
         greatest(private.match_score(p_query, p.display_name),
                  private.match_score(replace(p_query, '@', ''), p.username)) as score
    from public.profiles p
   where char_length(btrim(coalesce(p_query, ''))) >= 2
     and p.id <> (select auth.uid())
     and private.can_view_profile(p.id)
     and not exists (select 1 from public.user_blocks b
                      where (b.blocker_id = p.id and b.blocked_id = (select auth.uid()))
                         or (b.blocker_id = (select auth.uid()) and b.blocked_id = p.id))
     and greatest(private.match_score(p_query, p.display_name),
                  private.match_score(replace(p_query, '@', ''), p.username)) >= 0.3
   order by score desc, p.display_name
   limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- Clubs référencés (comme la découverte) trouvés malgré les fautes.
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
                               private.match_score(p_query, c.city)) end desc,
            c.member_count desc, c.name
   limit least(greatest(coalesce(p_limit, 50), 1), 50);
$$;

-- -----------------------------------------------------------------------------
-- Publications : jusqu'à 10 photos
-- -----------------------------------------------------------------------------
alter table public.post_media drop constraint post_media_position_check;
alter table public.post_media add constraint post_media_position_check check (position between 0 and 9);

create or replace function public.create_post(
  p_client_ref uuid,
  p_body text default '',
  p_audience public.post_audience default 'public',
  p_club_id uuid default null,
  p_media_paths text[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing uuid;
  created uuid;
  v_body text := btrim(coalesce(p_body, ''));
  v_paths text[] := coalesce(p_media_paths, '{}');
  i integer;
begin
  if p_client_ref is null then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select id into existing from public.posts where author_id = uid and client_ref = p_client_ref;
  if found then
    return existing;
  end if;

  if (v_body = '' and cardinality(v_paths) = 0) or char_length(v_body) > 2000
     or cardinality(v_paths) > 10
     or (p_audience = 'club' and p_club_id is null) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if p_club_id is not null and not (
       private.is_club_member(p_club_id)
       and exists (select 1 from public.clubs where id = p_club_id and suspended_at is null)) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if (select count(*) from public.posts
       where author_id = uid and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  for i in 1 .. cardinality(v_paths) loop
    if v_paths[i] is null
       or v_paths[i] not like uid::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'post-media' and o.name = v_paths[i])
       or exists (select 1 from public.post_media m where m.path = v_paths[i]) then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
  end loop;

  insert into public.posts (author_id, club_id, audience, body, client_ref)
  values (uid, p_club_id, p_audience, v_body, p_client_ref)
  returning id into created;
  for i in 1 .. cardinality(v_paths) loop
    insert into public.post_media (post_id, position, path) values (created, i - 1, v_paths[i]);
  end loop;
  return created;
end;
$$;

-- -----------------------------------------------------------------------------
-- Marketplace : tables
-- -----------------------------------------------------------------------------
create type public.listing_category as enum
  ('motorcycle', 'parts', 'helmet', 'protection', 'accessories', 'other');
create type public.listing_condition as enum ('new', 'like_new', 'good', 'fair', 'for_parts');
create type public.listing_status as enum ('available', 'reserved', 'sold');
create type public.currency_code as enum ('USD', 'CDF');

create table public.listings (
  id           uuid primary key default gen_random_uuid(),
  seller_id    uuid not null references public.profiles (id) on delete cascade,
  client_ref   uuid not null,
  category     public.listing_category not null,
  title        text not null check (char_length(btrim(title)) between 3 and 100),
  description  text not null default '' check (char_length(description) <= 3000),
  -- Prix INDICATIF : aucune transaction n'a lieu dans l'application.
  price        numeric(12, 2) check (price is null or price between 0 and 1000000000),
  currency     public.currency_code not null default 'USD',
  condition    public.listing_condition not null,
  city         text not null check (char_length(btrim(city)) between 2 and 80),
  -- Localisation approximative (quartier, commune) : jamais d'adresse exacte.
  area         text check (area is null or char_length(area) <= 80),
  status       public.listing_status not null default 'available',
  moderation   public.moderation_state not null default 'visible',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  -- Date de mise en avant (création ; plus tard « réactualisation »).
  bumped_at    timestamptz not null default now(),
  search_text  text generated always as (private.fold(title || ' ' || description || ' ' || city)) stored,
  unique (seller_id, client_ref)
);
create index listings_bumped_idx on public.listings (bumped_at desc);
create index listings_seller_idx on public.listings (seller_id);
create index listings_search_idx on public.listings using gin (search_text extensions.gin_trgm_ops);

create table public.listing_media (
  listing_id  uuid not null references public.listings (id) on delete cascade,
  position    smallint not null check (position between 0 and 9),
  path        text not null unique,
  primary key (listing_id, position)
);

create table public.listing_favorites (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  listing_id  uuid not null references public.listings (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index listing_favorites_listing_idx on public.listing_favorites (listing_id);

-- -----------------------------------------------------------------------------
-- Accès
-- -----------------------------------------------------------------------------
create or replace function private.can_view_listing(p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.listings l
     where l.id = p_listing_id
       and (select auth.uid()) is not null
       and (l.seller_id = (select auth.uid())
            or private.is_platform_admin()
            or (l.moderation = 'visible'
                and not private.is_blocked_between(l.seller_id, (select auth.uid()))))
  );
$$;
grant execute on function private.can_view_listing(uuid) to authenticated;

alter table public.listings enable row level security;
alter table public.listing_media enable row level security;
alter table public.listing_favorites enable row level security;
revoke all on public.listings, public.listing_media, public.listing_favorites from anon, authenticated;
grant select on public.listings, public.listing_media, public.listing_favorites to authenticated;

create policy "listings: visibles par les motards connectés"
  on public.listings for select to authenticated
  using (private.can_view_listing(id));
create policy "listing_media: suivent l'annonce"
  on public.listing_media for select to authenticated
  using (private.can_view_listing(listing_id));
create policy "listing_favorites: les siens"
  on public.listing_favorites for select to authenticated
  using (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-media', 'listing-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.can_view_listing_media(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.listing_media m
                  where m.path = p_path and private.can_view_listing(m.listing_id));
$$;
grant execute on function private.can_view_listing_media(text) to authenticated;

create policy "listing-media: lecture si l'annonce est visible"
  on storage.objects for select to authenticated
  using (bucket_id = 'listing-media'
         and ((storage.foldername(name))[1] = (select auth.uid())::text
              or private.can_view_listing_media(name)));
create policy "listing-media: ajout dans son dossier"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'listing-media'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "listing-media: suppression dans son dossier"
  on storage.objects for delete to authenticated
  using (bucket_id = 'listing-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- -----------------------------------------------------------------------------
-- Fonctions serveur
-- -----------------------------------------------------------------------------
create or replace function private.check_listing_media(p_uid uuid, p_paths text[], p_listing_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  i integer;
begin
  if cardinality(p_paths) > 10 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  for i in 1 .. cardinality(p_paths) loop
    if p_paths[i] is null
       or p_paths[i] not like p_uid::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'listing-media' and o.name = p_paths[i])
       or exists (select 1 from public.listing_media m
                   where m.path = p_paths[i] and m.listing_id is distinct from p_listing_id) then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
  end loop;
end;
$$;

create or replace function public.create_listing(
  p_client_ref uuid,
  p_category public.listing_category,
  p_title text,
  p_condition public.listing_condition,
  p_city text,
  p_description text default '',
  p_price numeric default null,
  p_currency public.currency_code default 'USD',
  p_area text default null,
  p_media_paths text[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing uuid;
  created uuid;
  v_paths text[] := coalesce(p_media_paths, '{}');
  i integer;
begin
  if p_client_ref is null then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select id into existing from public.listings where seller_id = uid and client_ref = p_client_ref;
  if found then
    return existing;
  end if;
  if (select count(*) from public.listings
       where seller_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  perform private.check_listing_media(uid, v_paths, null);
  begin
    insert into public.listings
      (seller_id, client_ref, category, title, description, price, currency, condition, city, area)
    values (uid, p_client_ref, p_category, btrim(p_title), btrim(coalesce(p_description, '')),
            p_price, coalesce(p_currency, 'USD'), p_condition, btrim(p_city), nullif(btrim(p_area), ''))
    returning id into created;
  exception when check_violation or not_null_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;
  for i in 1 .. cardinality(v_paths) loop
    insert into public.listing_media (listing_id, position, path) values (created, i - 1, v_paths[i]);
  end loop;
  perform private.log_action('listing.create', 'listing', created, '{}'::jsonb);
  return created;
end;
$$;

-- Modification par le vendeur ; retourne les chemins des photos retirées.
create or replace function public.update_listing(
  p_listing_id uuid,
  p_category public.listing_category,
  p_title text,
  p_condition public.listing_condition,
  p_city text,
  p_description text default '',
  p_price numeric default null,
  p_currency public.currency_code default 'USD',
  p_area text default null,
  p_media_paths text[] default '{}'
)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  v_paths text[] := coalesce(p_media_paths, '{}');
  removed text[];
  i integer;
begin
  if not exists (select 1 from public.listings where id = p_listing_id and seller_id = uid) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  perform private.check_listing_media(uid, v_paths, p_listing_id);
  begin
    update public.listings
       set category = p_category, title = btrim(p_title),
           description = btrim(coalesce(p_description, '')), price = p_price,
           currency = coalesce(p_currency, 'USD'), condition = p_condition,
           city = btrim(p_city), area = nullif(btrim(p_area), ''), updated_at = now()
     where id = p_listing_id;
  exception when check_violation or not_null_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;
  select coalesce(array_agg(path), '{}') into removed
    from public.listing_media where listing_id = p_listing_id and not (path = any (v_paths));
  delete from public.listing_media where listing_id = p_listing_id;
  for i in 1 .. cardinality(v_paths) loop
    insert into public.listing_media (listing_id, position, path) values (p_listing_id, i - 1, v_paths[i]);
  end loop;
  return removed;
end;
$$;

create or replace function public.set_listing_status(p_listing_id uuid, p_status public.listing_status)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if p_status is null then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  update public.listings set status = p_status, updated_at = now()
   where id = p_listing_id and seller_id = uid;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.delete_listing(p_listing_id uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  paths text[];
begin
  if not exists (select 1 from public.listings where id = p_listing_id and seller_id = uid) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(path order by position), '{}') into paths
    from public.listing_media where listing_id = p_listing_id;
  delete from public.listings where id = p_listing_id;
  return paths;
end;
$$;

create or replace function public.set_listing_favorite(p_listing_id uuid, p_favorite boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.can_view_listing(p_listing_id) then
    raise exception 'listing_not_found' using errcode = 'P0001';
  end if;
  if p_favorite then
    insert into public.listing_favorites (user_id, listing_id) values (uid, p_listing_id)
    on conflict do nothing;
  else
    delete from public.listing_favorites where user_id = uid and listing_id = p_listing_id;
  end if;
end;
$$;

-- Recherche d'annonces : texte tolérant, filtres, favoris, vendeur.
create or replace function public.search_listings(
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
  favorite_count integer
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
         (select count(*)::integer from public.listing_favorites f where f.listing_id = l.id)
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

-- -----------------------------------------------------------------------------
-- Signalements et modération : les annonces rejoignent le dispositif existant
-- -----------------------------------------------------------------------------
alter type public.report_target add value if not exists 'listing';

create or replace function public.report_content(
  p_target public.report_target,
  p_target_id uuid,
  p_reason public.report_reason,
  p_details text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  visible boolean;
  reporters integer;
  t text := p_target::text;
begin
  if p_target is null or p_target_id is null or p_reason is null
     or (p_details is not null and char_length(p_details) > 500) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  visible := case t
    when 'post' then private.can_view_post(p_target_id)
    when 'comment' then exists (select 1 from public.post_comments k
                                 where k.id = p_target_id and private.can_view_post(k.post_id))
    when 'message' then exists (select 1 from public.messages m
                                 where m.id = p_target_id
                                   and private.can_access_conversation(m.conversation_id))
    when 'user' then p_target_id <> uid and exists (select 1 from public.profiles where id = p_target_id)
    when 'listing' then private.can_view_listing(p_target_id)
                        and not exists (select 1 from public.listings
                                         where id = p_target_id and seller_id = uid)
  end;
  if not coalesce(visible, false) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  insert into public.content_reports (reporter_id, target_type, target_id, club_id, reason, details)
  values (uid, p_target, p_target_id, private.report_target_club(p_target, p_target_id),
          p_reason, nullif(btrim(p_details), ''))
  on conflict do nothing;

  select count(distinct reporter_id) into reporters from public.content_reports
   where target_type = p_target and target_id = p_target_id and status = 'open';
  if reporters >= 3 then
    if t = 'post' then
      update public.posts set moderation = 'hidden', moderation_note = 'signalements'
       where id = p_target_id and moderation = 'visible';
    elsif t = 'comment' then
      update public.post_comments set moderation = 'hidden' where id = p_target_id;
    elsif t = 'message' then
      update public.messages set moderation = 'hidden' where id = p_target_id;
    elsif t = 'listing' then
      update public.listings set moderation = 'hidden' where id = p_target_id;
    end if;
  end if;
  perform private.log_action('report.create', t, p_target_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

create or replace function private.report_target_info(p_type text, p_id uuid,
  out preview text, out author_id uuid, out state public.moderation_state)
language sql
stable
security definer
set search_path = ''
as $$
  select case p_type
           when 'post' then (select left(body, 200) from public.posts where id = p_id)
           when 'comment' then (select left(body, 200) from public.post_comments where id = p_id)
           when 'message' then (select left(body, 200) from public.messages where id = p_id)
           when 'listing' then (select title from public.listings where id = p_id)
           when 'user' then (select display_name from public.profiles where id = p_id)
         end,
         case p_type
           when 'post' then (select l.author_id from public.posts l where l.id = p_id)
           when 'comment' then (select l.author_id from public.post_comments l where l.id = p_id)
           when 'message' then (select l.sender_id from public.messages l where l.id = p_id)
           when 'listing' then (select l.seller_id from public.listings l where l.id = p_id)
           when 'user' then p_id
         end,
         coalesce(case p_type
           when 'post' then (select moderation from public.posts where id = p_id)
           when 'comment' then (select moderation from public.post_comments where id = p_id)
           when 'message' then (select moderation from public.messages where id = p_id)
           when 'listing' then (select moderation from public.listings where id = p_id)
         end, 'visible');
$$;
revoke all on function private.report_target_info(text, uuid) from public, anon, authenticated;

create or replace function public.moderation_queue()
returns table (
  target_type public.report_target,
  target_id uuid,
  club_id uuid,
  report_count integer,
  reasons text[],
  last_reported_at timestamptz,
  preview text,
  author_id uuid,
  author_name text,
  moderation public.moderation_state
)
language sql
stable
security definer
set search_path = ''
as $$
  select q.target_type, q.target_id, q.club_id, q.n, q.reasons, q.last_at,
         i.preview, i.author_id,
         (select display_name from public.profiles where id = i.author_id),
         i.state
    from (select r.target_type, r.target_id, r.club_id, count(*)::integer n,
                 array_agg(distinct r.reason::text) reasons, max(r.created_at) last_at
            from public.content_reports r
           where r.status = 'open'
             and (private.is_platform_admin()
                  or (r.club_id is not null and private.has_club_role(r.club_id, 'moderator')))
           group by r.target_type, r.target_id, r.club_id) q
    cross join lateral private.report_target_info(q.target_type::text, q.target_id) i
   order by q.last_at desc
   limit 200;
$$;

create or replace function public.moderate_content(
  p_target public.report_target, p_target_id uuid, p_action text, p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  v_club uuid := private.report_target_club(p_target, p_target_id);
  v_state public.moderation_state;
  t text := p_target::text;
begin
  if p_action not in ('hide', 'restore', 'dismiss')
     or (p_note is not null and char_length(p_note) > 280) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if not (private.is_platform_admin()
          or (v_club is not null and private.has_club_role(v_club, 'moderator'))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if t = 'user' and p_action <> 'dismiss' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  if p_action <> 'dismiss' then
    v_state := case p_action when 'hide' then 'hidden' else 'visible' end;
    if t = 'post' then
      update public.posts set moderation = v_state, moderation_note = nullif(btrim(p_note), '')
       where id = p_target_id;
    elsif t = 'comment' then
      update public.post_comments set moderation = v_state where id = p_target_id;
    elsif t = 'message' then
      update public.messages set moderation = v_state where id = p_target_id;
    elsif t = 'listing' then
      update public.listings set moderation = v_state where id = p_target_id;
    end if;
  end if;

  update public.content_reports
     set status = case p_action when 'hide' then 'actioned'::public.report_status
                                else 'dismissed'::public.report_status end,
         handled_by = uid, handled_at = now()
   where target_type = p_target and target_id = p_target_id and status = 'open';
  perform private.log_action('moderation.' || p_action, t, p_target_id,
    jsonb_build_object('note', p_note));
end;
$$;

-- -----------------------------------------------------------------------------
-- Droits
-- -----------------------------------------------------------------------------
revoke all on function private.check_listing_media(uuid, text[], uuid) from public, anon, authenticated;

grant execute on function
  public.search_riders(text, integer),
  public.search_clubs(text, integer),
  public.create_post(uuid, text, public.post_audience, uuid, text[]),
  public.create_listing(uuid, public.listing_category, text, public.listing_condition, text,
                        text, numeric, public.currency_code, text, text[]),
  public.update_listing(uuid, public.listing_category, text, public.listing_condition, text,
                        text, numeric, public.currency_code, text, text[]),
  public.set_listing_status(uuid, public.listing_status),
  public.delete_listing(uuid),
  public.set_listing_favorite(uuid, boolean),
  public.search_listings(text, public.listing_category, text, numeric, public.currency_code,
                         boolean, boolean, uuid, uuid, timestamptz, integer),
  public.report_content(public.report_target, uuid, public.report_reason, text),
  public.moderation_queue(),
  public.moderate_content(public.report_target, uuid, text, text)
to authenticated;
