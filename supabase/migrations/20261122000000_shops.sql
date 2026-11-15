-- =============================================================================
-- Rider Group — Migration 0017 : boutiques des motards vérifiés
-- -----------------------------------------------------------------------------
-- D-58 : un motard VÉRIFIÉ peut ouvrir UNE boutique : nom, description,
-- ville, quartier, numéro WhatsApp, logo. La boutique regroupe ses annonces
-- du marketplace (aucune transaction dans l'application : prix indicatifs,
-- contact direct). Elle n'est visible que tant que son propriétaire est
-- vérifié et qu'elle n'est pas suspendue par l'équipe. Aucun paiement.
-- =============================================================================

create table public.shops (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null unique references public.profiles (id) on delete cascade,
  name         text not null check (char_length(btrim(name)) between 3 and 80),
  description  text not null default '' check (char_length(description) <= 2000),
  city         text not null check (char_length(btrim(city)) between 2 and 80),
  area         text check (area is null or char_length(area) <= 80),
  phone        text check (phone is null or phone ~ '^\+?[0-9]{8,15}$'),
  logo_path    text check (logo_path is null or logo_path like owner_id::text || '/%'),
  suspended_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create unique index shops_name_unique on public.shops (lower(btrim(name)));

alter table public.shops enable row level security;
revoke all on public.shops from anon, authenticated;
grant select on public.shops to authenticated;

-- Motard vérifié (badge en cours de validité) ?
create or replace function private.is_verified_rider(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles
                  where id = p_user_id and verified_at is not null
                    and (verified_until is null or verified_until > now()));
$$;

create or replace function private.can_view_shop(p_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.shops s
     where s.id = p_shop_id and (select auth.uid()) is not null
       and (s.owner_id = (select auth.uid())
            or private.is_platform_admin()
            or (s.suspended_at is null and private.is_verified_rider(s.owner_id)
                and not private.is_blocked_between(s.owner_id, (select auth.uid())))));
$$;

create policy "shops: boutiques actives, la sienne, l'équipe"
  on public.shops for select to authenticated
  using (private.can_view_shop(id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('shop-media', 'shop-media', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Dossier = identifiant du propriétaire (supprimé avec le compte).
create policy "shop-media: lecture par les motards connectés"
  on storage.objects for select to authenticated
  using (bucket_id = 'shop-media');
create policy "shop-media: ajout par le propriétaire"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'shop-media'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "shop-media: suppression par le propriétaire"
  on storage.objects for delete to authenticated
  using (bucket_id = 'shop-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Crée ou modifie la boutique de l'utilisateur (vérifié uniquement).
create or replace function public.save_my_shop(
  p_name text,
  p_city text,
  p_description text default '',
  p_area text default null,
  p_phone text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '[\s.\-()]', '', 'g'), '');
  saved uuid;
begin
  if not private.is_verified_rider(uid) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_name, ''))) not between 3 and 80
     or char_length(btrim(coalesce(p_city, ''))) not between 2 and 80
     or char_length(coalesce(p_description, '')) > 2000
     or (p_area is not null and char_length(p_area) > 80)
     or (v_phone is not null and v_phone !~ '^\+?[0-9]{8,15}$') then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  begin
    insert into public.shops (owner_id, name, description, city, area, phone)
    values (uid, btrim(p_name), coalesce(btrim(p_description), ''), btrim(p_city),
            nullif(btrim(p_area), ''), v_phone)
    on conflict (owner_id) do update
      set name = excluded.name, description = excluded.description, city = excluded.city,
          area = excluded.area, phone = excluded.phone, updated_at = now()
    returning id into saved;
  exception when unique_violation then
    raise exception 'shop_name_taken' using errcode = 'P0001';
  end;
  perform private.log_action('shop.save', 'shop', saved);
  return saved;
end;
$$;

create or replace function public.set_my_shop_logo(p_path text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  old text;
begin
  if p_path is not null and (
       p_path not like uid::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'shop-media' and o.name = p_path)) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select logo_path into old from public.shops where owner_id = uid;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.shops set logo_path = p_path, updated_at = now() where owner_id = uid;
  return old;
end;
$$;

create or replace function public.delete_my_shop()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  delete from public.shops where owner_id = uid;
end;
$$;

-- L'équipe suspend ou rétablit une boutique (abus).
create or replace function public.set_shop_suspended(p_shop_id uuid, p_suspended boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_user();
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.shops set suspended_at = case when p_suspended then now() end
   where id = p_shop_id;
  perform private.log_action(case when p_suspended then 'shop.suspend' else 'shop.restore' end,
                             'shop', p_shop_id);
end;
$$;

-- Boutiques visibles, avec recherche tolérante, ou une seule (par id ou
-- propriétaire).
create or replace function public.list_shops(
  p_query text default null,
  p_shop_id uuid default null,
  p_owner_id uuid default null,
  p_limit integer default 50
)
returns table (
  id uuid,
  owner_id uuid,
  owner_name text,
  name text,
  description text,
  city text,
  area text,
  phone text,
  logo_path text,
  active boolean,
  listing_count integer
)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id, s.owner_id, p.display_name, s.name, s.description, s.city, s.area, s.phone,
         s.logo_path,
         s.suspended_at is null and private.is_verified_rider(s.owner_id),
         (select count(*)::integer from public.listings l
           where l.seller_id = s.owner_id and l.status <> 'sold' and l.moderation = 'visible')
    from public.shops s
    join public.profiles p on p.id = s.owner_id
   where private.can_view_shop(s.id)
     and (p_shop_id is null or s.id = p_shop_id)
     and (p_owner_id is null or s.owner_id = p_owner_id)
     and (p_query is null or char_length(btrim(p_query)) < 2
          or greatest(private.match_score(p_query, s.name),
                      private.match_score(p_query, s.city)) >= 0.3)
   order by case when p_query is null or char_length(btrim(p_query)) < 2 then 0
                 else private.match_score(p_query, s.name) end desc,
            s.updated_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

revoke all on function private.is_verified_rider(uuid), private.can_view_shop(uuid)
  from public, anon;
grant execute on function private.is_verified_rider(uuid), private.can_view_shop(uuid)
  to authenticated;

grant execute on function
  public.save_my_shop(text, text, text, text, text),
  public.set_my_shop_logo(text),
  public.delete_my_shop(),
  public.set_shop_suspended(uuid, boolean),
  public.list_shops(text, uuid, uuid, integer)
to authenticated;
