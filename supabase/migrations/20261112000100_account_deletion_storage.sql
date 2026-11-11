-- =============================================================================
-- Rider Group — Migration 0006 : suppression de compte et fichiers Storage
-- -----------------------------------------------------------------------------
-- Supabase refuse de supprimer un utilisateur propriétaire d'objets Storage
-- (clé étrangère storage.objects.owner → auth.users). Un administrateur de
-- club possède les logos / couvertures qu'il a déposés : sans correction, sa
-- suppression de compte échouait.
-- Correction : avant la suppression, les fichiers restants perdent leur
-- propriétaire. Les médias de club restent en place (le club en a besoin) ;
-- leur accès est toujours régi par les politiques du bucket, pas par le
-- propriétaire. La photo de profil est supprimée par l'application avant
-- l'appel (Supabase interdit la suppression directe de fichiers en SQL).
-- Source : https://supabase.com/docs/guides/auth/managing-user-data
--
-- Balades : l'organisateur était en « on delete restrict », ce qui rendait
-- impossible la suppression du compte de toute personne ayant organisé une
-- balade. Désormais :
--   * refus (organizes_active_rides) tant qu'il organise une balade active
--     (publiée, verrouillée, en cours) comptant d'autres inscrits ;
--   * brouillons et balades actives sans autre inscrit : supprimés ;
--   * balades terminées ou annulées : conservées pour l'historique des
--     participants, organisateur remis à NULL (« compte supprimé »).
-- =============================================================================

alter table public.rides alter column organizer_id drop not null;
alter table public.rides drop constraint rides_organizer_id_fkey;
alter table public.rides add constraint rides_organizer_id_fkey
  foreign key (organizer_id) references public.profiles (id) on delete set null;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if exists (select 1 from public.clubs c
              where c.owner_id = uid
                and exists (select 1 from public.club_members m
                             where m.club_id = c.id and m.user_id <> uid)) then
    raise exception 'owns_clubs_with_members' using errcode = 'P0001';
  end if;

  if exists (select 1 from public.rides r
              where r.organizer_id = uid
                and r.status in ('published', 'locked', 'in_progress')
                and exists (select 1 from public.ride_participants p
                             where p.ride_id = r.id and p.user_id <> uid
                               and p.status in ('pending', 'confirmed'))) then
    raise exception 'organizes_active_rides' using errcode = 'P0001';
  end if;

  perform private.log_action('account.delete', 'user', uid,
    jsonb_build_object('deleted_clubs',
      (select coalesce(jsonb_agg(c.id), '[]'::jsonb) from public.clubs c where c.owner_id = uid)));

  -- Brouillons et balades actives sans autre inscrit : supprimés. Les
  -- balades terminées ou annulées passent à organizer_id = NULL (cascade).
  delete from public.rides
   where organizer_id = uid
     and status in ('draft', 'published', 'locked', 'in_progress');

  delete from public.clubs where owner_id = uid;

  update storage.objects
     set owner = null, owner_id = null
   where owner = uid or owner_id = uid::text;

  delete from auth.users where id = uid;
end;
$$;

grant execute on function public.delete_my_account() to authenticated;
