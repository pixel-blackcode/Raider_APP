-- =============================================================================
-- Rider Group — Migration 0012 : balades enrichies (Mission 08 bis)
-- -----------------------------------------------------------------------------
--   * photo de couverture de la balade (bucket privé `ride-media`, dossier
--     <ride_id>/), gérée par les gestionnaires de la balade ;
--   * départ et arrivée pointés sur une carte : colonnes déjà présentes
--     (start_lat/lng, destination_lat/lng) ; distance calculée à vol d'oiseau ;
--   * itinéraire du chef de convoi pour les retardataires (D-51) : seul le
--     trajet du chef de convoi (à défaut : de l'organisateur) est enregistré,
--     à partir des positions qu'il partage déjà ; visible des participants
--     pendant la balade ; supprimé 72 h après la fin (comme D-35).
-- =============================================================================

alter table public.rides add column cover_path text
  check (cover_path is null or cover_path like id::text || '/%');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ride-media', 'ride-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "ride-media: lecture si la balade est visible"
  on storage.objects for select to authenticated
  using (bucket_id = 'ride-media'
         and private.can_view_ride(private.try_uuid((storage.foldername(name))[1])));
create policy "ride-media: ajout par les gestionnaires"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'ride-media'
              and private.can_manage_ride(private.try_uuid((storage.foldername(name))[1])));
create policy "ride-media: suppression par les gestionnaires"
  on storage.objects for delete to authenticated
  using (bucket_id = 'ride-media'
         and private.can_manage_ride(private.try_uuid((storage.foldername(name))[1])));

-- Enregistre (ou retire avec null) la photo de couverture ; retourne l'ancienne.
create or replace function public.set_ride_cover(p_ride_id uuid, p_path text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  old text;
begin
  perform private.require_user();
  if not private.can_manage_ride(p_ride_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_path is not null and (
       p_path not like p_ride_id::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'ride-media' and o.name = p_path)) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select cover_path into old from public.rides where id = p_ride_id;
  update public.rides set cover_path = p_path, updated_at = now() where id = p_ride_id;
  return old;
end;
$$;

-- -----------------------------------------------------------------------------
-- Itinéraire du chef de convoi
-- -----------------------------------------------------------------------------
create table public.ride_trail_points (
  id           bigint generated always as identity primary key,
  ride_id      uuid not null references public.rides (id) on delete cascade,
  user_id      uuid references public.profiles (id) on delete set null,
  lat          double precision not null check (lat between -90 and 90),
  lng          double precision not null check (lng between -180 and 180),
  recorded_at  timestamptz not null
);
create index ride_trail_points_ride_idx on public.ride_trail_points (ride_id, recorded_at);
create index ride_trail_points_user_idx on public.ride_trail_points (user_id);

alter table public.ride_trail_points enable row level security;
revoke all on public.ride_trail_points from anon, authenticated;
grant select on public.ride_trail_points to authenticated;
create policy "ride_trail_points: participants pendant la balade"
  on public.ride_trail_points for select to authenticated
  using (private.can_view_ride_positions(ride_id));

-- Qui trace l'itinéraire : le chef de convoi, sinon l'organisateur.
create or replace function private.ride_guide(p_ride_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select user_id from public.ride_role_assignments
      where ride_id = p_ride_id and role = 'leader'),
    (select organizer_id from public.rides where id = p_ride_id));
$$;

-- Ajoute un point quand le guide a parcouru au moins 25 m (au plus 5 000).
create or replace function private.record_trail_point()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  last record;
begin
  if new.user_id is distinct from private.ride_guide(new.ride_id) then
    return null;
  end if;
  select lat, lng into last from public.ride_trail_points
   where ride_id = new.ride_id order by recorded_at desc, id desc limit 1;
  if found and extensions.st_distance(
       extensions.st_makepoint(last.lng, last.lat)::extensions.geography,
       extensions.st_makepoint(new.lng, new.lat)::extensions.geography) < 25 then
    return null;
  end if;
  if (select count(*) from public.ride_trail_points where ride_id = new.ride_id) >= 5000 then
    return null;
  end if;
  insert into public.ride_trail_points (ride_id, user_id, lat, lng, recorded_at)
  values (new.ride_id, new.user_id, new.lat, new.lng, new.recorded_at);
  return null;
end;
$$;
create trigger ride_positions_trail
  after insert or update of lat, lng on public.ride_positions
  for each row execute function private.record_trail_point();

-- Purge 72 h après la fin : positions ET itinéraire (retourne le nombre de
-- positions supprimées, comme avant).
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
  delete from public.ride_trail_points t
   using public.rides r
   where r.id = t.ride_id
     and r.status in ('finished', 'cancelled')
     and coalesce(r.finished_at, r.cancelled_at, r.updated_at) < now() - interval '72 hours';
  return n;
end;
$$;

revoke all on function
  private.record_trail_point(),
  private.purge_ride_positions(),
  private.ride_guide(uuid)
from public, anon, authenticated;

grant execute on function public.set_ride_cover(uuid, text) to authenticated;
