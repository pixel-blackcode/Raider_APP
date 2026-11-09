-- =============================================================================
-- Rider Group — Migration 0004 : médias, confidentialité, suppression de compte
-- -----------------------------------------------------------------------------
--   * Buckets Storage PRIVÉS : les images ne sont lisibles que par les
--     utilisateurs connectés autorisés à voir le profil / le club.
--       avatars/<user_id>/<fichier>      écriture : l'utilisateur lui-même
--       club-media/<club_id>/<fichier>   écriture : owner / admin du club
--   * Préférences de confidentialité (profil découvrable, invitations).
--   * Suppression de compte en libre-service.
--
-- Nouveaux codes d'erreur : invitations_disabled, owns_clubs_with_members
-- =============================================================================

-- Conversion tolérante (un chemin malformé ne doit pas lever d'erreur dans
-- une politique RLS).
create or replace function private.try_uuid(p_value text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return p_value::uuid;
exception when others then
  return null;
end;
$$;
grant execute on function private.try_uuid(text) to authenticated;

-- -----------------------------------------------------------------------------
-- Confidentialité
-- -----------------------------------------------------------------------------
create table public.profile_settings (
  user_id                 uuid primary key references public.profiles (id) on delete cascade,
  -- false : profil visible uniquement par les membres des mêmes clubs
  -- (et par les administrateurs d'un club auquel une demande est adressée).
  discoverable            boolean not null default true,
  -- false : personne ne peut inviter l'utilisateur dans un club.
  allow_club_invitations  boolean not null default true,
  updated_at              timestamptz not null default now()
);
comment on table public.profile_settings is
  'Préférences de confidentialité. Absence de ligne = valeurs par défaut. Lecture/écriture : l''utilisateur seul.';

create trigger profile_settings_set_updated_at
  before update on public.profile_settings
  for each row execute function private.set_updated_at();

alter table public.profile_settings enable row level security;
revoke all on public.profile_settings from anon, authenticated;
grant select on public.profile_settings to authenticated;
grant insert (user_id, discoverable, allow_club_invitations) on public.profile_settings to authenticated;
-- user_id figure dans l'UPDATE car l'upsert PostgREST réécrit toutes les
-- colonnes envoyées ; la politique impose user_id = auth.uid().
grant update (user_id, discoverable, allow_club_invitations) on public.profile_settings to authenticated;

create policy "profile_settings: lecture de ses préférences"
  on public.profile_settings for select to authenticated
  using (user_id = (select auth.uid()));
create policy "profile_settings: création de ses préférences"
  on public.profile_settings for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "profile_settings: modification de ses préférences"
  on public.profile_settings for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Le profil p_user_id est-il visible par l'utilisateur courant ?
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
    -- membres d'un même club
    or exists (
      select 1 from public.club_members a
        join public.club_members b on b.club_id = a.club_id
       where a.user_id = p_user_id and b.user_id = (select auth.uid()))
    -- demande d'adhésion adressée à un club que l'utilisateur administre
    or exists (
      select 1 from public.club_join_requests r
        join public.club_members m on m.club_id = r.club_id
       where r.user_id = p_user_id and r.status = 'pending'
         and m.user_id = (select auth.uid()) and m.role in ('owner', 'admin'))
    -- auteur d'une invitation reçue par l'utilisateur
    or exists (
      select 1 from public.club_invitations i
       where i.invited_by = p_user_id and i.invitee_id = (select auth.uid())
         and i.status = 'pending')
  );
$$;
grant execute on function private.can_view_profile(uuid) to authenticated;

drop policy "profiles: lecture par les utilisateurs connectés" on public.profiles;
create policy "profiles: lecture selon la confidentialité"
  on public.profiles for select to authenticated
  using (private.can_view_profile(id));

-- Invitations : respect de la préférence de l'invité.
create or replace function public.invite_to_club(p_club_id uuid, p_invitee_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing uuid;
  created uuid;
begin
  if not private.has_club_role(p_club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.clubs where id = p_club_id and suspended_at is not null) then
    raise exception 'club_suspended' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = p_invitee_id) then
    raise exception 'user_not_found' using errcode = 'P0001';
  end if;
  if private.club_role_of(p_club_id, p_invitee_id) is not null then
    raise exception 'already_member' using errcode = 'P0001';
  end if;
  if not coalesce((select s.allow_club_invitations from public.profile_settings s
                    where s.user_id = p_invitee_id), true) then
    raise exception 'invitations_disabled' using errcode = 'P0001';
  end if;

  select id into existing from public.club_invitations
   where club_id = p_club_id and invitee_id = p_invitee_id and status = 'pending';
  if existing is not null then
    return existing;
  end if;

  insert into public.club_invitations (club_id, invitee_id, invited_by)
  values (p_club_id, p_invitee_id, uid)
  returning id into created;

  perform private.log_action('club.invite', 'club', p_club_id,
    jsonb_build_object('invitee_id', p_invitee_id));
  return created;
end;
$$;

-- -----------------------------------------------------------------------------
-- Médias : cohérence des chemins stockés
-- -----------------------------------------------------------------------------
alter table public.profiles add constraint profiles_avatar_path_owner
  check (avatar_path is null or avatar_path like id::text || '/%');
alter table public.clubs add constraint clubs_logo_path_owner
  check (logo_path is null or logo_path like id::text || '/%');
alter table public.clubs add constraint clubs_cover_path_owner
  check (cover_path is null or cover_path like id::text || '/%');

-- -----------------------------------------------------------------------------
-- Storage
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('club-media', 'club-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "avatars: lecture si le profil est visible"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars'
         and private.can_view_profile(private.try_uuid((storage.foldername(name))[1])));

create policy "avatars: ajout dans son dossier"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatars: remplacement dans son dossier"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatars: suppression dans son dossier"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "club-media: lecture si le club est visible"
  on storage.objects for select to authenticated
  using (bucket_id = 'club-media'
         and private.can_view_club(private.try_uuid((storage.foldername(name))[1])));

create policy "club-media: ajout par owner/admin"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'club-media'
              and private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin'));

create policy "club-media: remplacement par owner/admin"
  on storage.objects for update to authenticated
  using (bucket_id = 'club-media'
         and private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin'))
  with check (bucket_id = 'club-media'
              and private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin'));

create policy "club-media: suppression par owner/admin"
  on storage.objects for delete to authenticated
  using (bucket_id = 'club-media'
         and private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin'));

-- -----------------------------------------------------------------------------
-- Suppression de compte
-- -----------------------------------------------------------------------------
-- Règles :
--   * un propriétaire de club comptant d'autres membres doit d'abord
--     transférer la propriété (owns_clubs_with_members) ;
--   * ses clubs sans autre membre sont supprimés ;
--   * la suppression de auth.users entraîne en cascade : profil,
--     préférences, adhésions, demandes, invitations reçues ;
--   * le journal d'audit conserve l'identifiant (traçabilité des actions
--     d'administration), sans donnée de profil.
-- Les fichiers Storage doivent être supprimés via l'API Storage AVANT
-- l'appel (Supabase interdit la suppression directe en SQL) : l'application
-- supprime la photo de profil ; voir docs/SECURITY.md pour les médias de club.
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

  perform private.log_action('account.delete', 'user', uid,
    jsonb_build_object('deleted_clubs',
      (select coalesce(jsonb_agg(c.id), '[]'::jsonb) from public.clubs c where c.owner_id = uid)));

  delete from public.clubs where owner_id = uid;
  delete from auth.users where id = uid;
end;
$$;

grant execute on function public.delete_my_account() to authenticated;
