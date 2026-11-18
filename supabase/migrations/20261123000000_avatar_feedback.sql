-- =============================================================================
-- Rider Group — Migration 0018 : visibilité de la photo de profil et
-- signalements / suggestions envoyés à l'équipe.
-- -----------------------------------------------------------------------------
-- D-59 : chaque motard choisit qui voit sa photo de profil : tout le monde
-- (par défaut), les membres de ses clubs, ou personne. Le contrôle est fait
-- par le stockage : sans droit, l'image ne se charge pas et l'initiale
-- s'affiche. Le motard et l'équipe la voient toujours.
-- D-60 : Paramètres → « Signaler un problème ou une suggestion » : message
-- privé à l'équipe Rider Group (version de l'application jointe), lu dans
-- l'outil de l'équipe.
-- =============================================================================

alter table public.profile_settings
  add column avatar_visibility text not null default 'everyone'
  check (avatar_visibility in ('everyone', 'clubs', 'nobody'));
grant insert (avatar_visibility), update (avatar_visibility)
  on public.profile_settings to authenticated;

create or replace function private.can_view_avatar(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null and (
    p_user_id = (select auth.uid())
    or private.is_platform_admin()
    or (private.can_view_profile(p_user_id)
        and case coalesce((select s.avatar_visibility from public.profile_settings s
                            where s.user_id = p_user_id), 'everyone')
              when 'everyone' then true
              when 'clubs' then exists (
                select 1 from public.club_members a
                  join public.club_members b on b.club_id = a.club_id
                 where a.user_id = p_user_id and b.user_id = (select auth.uid()))
              else false
            end));
$$;
grant execute on function private.can_view_avatar(uuid) to authenticated;

drop policy "avatars: lecture si le profil est visible" on storage.objects;
create policy "avatars: lecture selon le choix du motard"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars'
         and private.can_view_avatar(private.try_uuid((storage.foldername(name))[1])));

-- -----------------------------------------------------------------------------
-- Signalements et suggestions
-- -----------------------------------------------------------------------------
create table public.app_feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles (id) on delete set null,
  kind        text not null check (kind in ('problem', 'suggestion')),
  message     text not null check (char_length(btrim(message)) between 5 and 2000),
  app_version text check (app_version is null or char_length(app_version) <= 40),
  platform    text check (platform is null or char_length(platform) <= 20),
  handled_at  timestamptz,
  handled_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now()
);
create index app_feedback_user_idx on public.app_feedback (user_id);
create index app_feedback_handled_by_idx on public.app_feedback (handled_by);
create index app_feedback_open_idx on public.app_feedback (created_at desc) where handled_at is null;

alter table public.app_feedback enable row level security;
revoke all on public.app_feedback from anon, authenticated;

create or replace function public.send_feedback(
  p_kind text, p_message text, p_app_version text default null, p_platform text default null
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
  if p_kind not in ('problem', 'suggestion')
     or char_length(btrim(coalesce(p_message, ''))) not between 5 and 2000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if (select count(*) from public.app_feedback
       where user_id = uid and created_at > now() - interval '1 day') >= 10 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.app_feedback (user_id, kind, message, app_version, platform)
  values (uid, p_kind, btrim(p_message), left(p_app_version, 40), left(p_platform, 20))
  returning id into created;
  return created;
end;
$$;

create or replace function public.feedback_queue(p_include_handled boolean default false)
returns table (
  id uuid, user_id uuid, username text, display_name text, kind text, message text,
  app_version text, platform text, handled_at timestamptz, created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  return query
    select f.id, f.user_id, p.username, p.display_name, f.kind, f.message, f.app_version,
           f.platform, f.handled_at, f.created_at
      from public.app_feedback f
      left join public.profiles p on p.id = f.user_id
     where p_include_handled or f.handled_at is null
     order by f.created_at desc
     limit 200;
end;
$$;

create or replace function public.mark_feedback_handled(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.app_feedback set handled_at = now(), handled_by = uid
   where id = p_id and handled_at is null;
end;
$$;

grant execute on function
  public.send_feedback(text, text, text, text),
  public.feedback_queue(boolean),
  public.mark_feedback_handled(uuid)
to authenticated;
