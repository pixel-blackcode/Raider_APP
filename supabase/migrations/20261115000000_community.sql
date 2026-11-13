-- =============================================================================
-- Rider Group — Migration 0010 : communauté et messagerie (Mission 07)
-- -----------------------------------------------------------------------------
-- Cahier des charges §9 (Module F), décisions D-41 à D-46 :
--   * publications texte + jusqu'à 4 photos (bucket privé `post-media`),
--     audience « public » (motards connectés) ou « club » (membres) ;
--   * espaces de publication des clubs (club_id) ;
--   * commentaires, réactions (j'aime, en feu, respect) ;
--   * blocage : deux motards qui se bloquent ne voient plus leurs contenus,
--     ne peuvent plus commenter chez l'autre ni s'écrire ;
--   * signalements (publication, commentaire, message, motard) ; 3
--     signalements distincts masquent un contenu en attendant la modération ;
--   * modération : administrateurs de la plateforme partout, modérateurs de
--     club sur le contenu de leur club ;
--   * messagerie : conversations privées, de groupe et discussion de balade
--     (accès dérivé de la participation : un participant retiré perd l'accès).
--   * envois idempotents (client_ref) : un renvoi ne crée pas de doublon.
--
-- Codes d'erreur : not_allowed, invalid_input, rate_limited, blocked,
-- user_not_found, content_hidden, not_participant, conversation_not_found
-- =============================================================================

create type public.post_audience as enum ('public', 'club');
create type public.moderation_state as enum ('visible', 'hidden');
create type public.reaction_kind as enum ('like', 'fire', 'respect');
create type public.report_target as enum ('post', 'comment', 'message', 'user');
create type public.report_reason as enum ('spam', 'harassment', 'hate', 'violence', 'nudity', 'scam', 'other');
create type public.report_status as enum ('open', 'actioned', 'dismissed');
create type public.conversation_kind as enum ('direct', 'group', 'ride');

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------
create table public.posts (
  id               uuid primary key default gen_random_uuid(),
  author_id        uuid not null references public.profiles (id) on delete cascade,
  club_id          uuid references public.clubs (id) on delete cascade,
  audience         public.post_audience not null default 'public',
  body             text not null default '' check (char_length(body) <= 2000),
  client_ref       uuid not null,
  moderation       public.moderation_state not null default 'visible',
  moderation_note  text check (moderation_note is null or char_length(moderation_note) <= 280),
  created_at       timestamptz not null default now(),
  constraint posts_club_audience check (audience = 'public' or club_id is not null),
  unique (author_id, client_ref)
);
create index posts_created_idx on public.posts (created_at desc);
create index posts_club_idx on public.posts (club_id, created_at desc);
create index posts_author_idx on public.posts (author_id, created_at desc);

create table public.post_media (
  post_id   uuid not null references public.posts (id) on delete cascade,
  position  smallint not null check (position between 0 and 3),
  path      text not null unique,
  primary key (post_id, position)
);

create table public.post_comments (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references public.posts (id) on delete cascade,
  author_id   uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 1000),
  client_ref  uuid not null,
  moderation  public.moderation_state not null default 'visible',
  created_at  timestamptz not null default now(),
  unique (author_id, client_ref)
);
create index post_comments_post_idx on public.post_comments (post_id, created_at);
create index post_comments_author_idx on public.post_comments (author_id);

create table public.post_reactions (
  post_id     uuid not null references public.posts (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        public.reaction_kind not null,
  created_at  timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index post_reactions_user_idx on public.post_reactions (user_id);

create table public.user_blocks (
  blocker_id  uuid not null references public.profiles (id) on delete cascade,
  blocked_id  uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index user_blocks_blocked_idx on public.user_blocks (blocked_id);

create table public.content_reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid references public.profiles (id) on delete set null,
  target_type  public.report_target not null,
  target_id    uuid not null,
  -- Club concerné (contenu d'un club) : ses modérateurs traitent le signalement.
  club_id      uuid references public.clubs (id) on delete cascade,
  reason       public.report_reason not null,
  details      text check (details is null or char_length(details) <= 500),
  status       public.report_status not null default 'open',
  handled_by   uuid references public.profiles (id) on delete set null,
  handled_at   timestamptz,
  created_at   timestamptz not null default now()
);
create unique index content_reports_one_open_per_reporter
  on public.content_reports (reporter_id, target_type, target_id) where status = 'open';
create index content_reports_target_idx on public.content_reports (target_type, target_id);
create index content_reports_club_idx on public.content_reports (club_id);
create index content_reports_handled_by_idx on public.content_reports (handled_by);

create table public.conversations (
  id               uuid primary key default gen_random_uuid(),
  kind             public.conversation_kind not null,
  title            text check (title is null or char_length(btrim(title)) between 1 and 60),
  ride_id          uuid unique references public.rides (id) on delete cascade,
  -- Conversation privée : identifiants triés, une seule par paire.
  direct_key       text unique,
  created_by       uuid references public.profiles (id) on delete set null,
  created_at       timestamptz not null default now(),
  last_message_at  timestamptz,
  constraint conversations_kind_shape check (
    (kind = 'ride' and ride_id is not null and direct_key is null)
    or (kind = 'direct' and ride_id is null and direct_key is not null)
    or (kind = 'group' and ride_id is null and direct_key is null and title is not null))
);
create index conversations_created_by_idx on public.conversations (created_by);

create table public.conversation_members (
  conversation_id  uuid not null references public.conversations (id) on delete cascade,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  role             text not null default 'member' check (role in ('owner', 'member')),
  joined_at        timestamptz not null default now(),
  last_read_at     timestamptz,
  primary key (conversation_id, user_id)
);
create index conversation_members_user_idx on public.conversation_members (user_id);

create table public.messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references public.conversations (id) on delete cascade,
  sender_id        uuid references public.profiles (id) on delete set null,
  body             text not null check (char_length(body) <= 2000),
  client_ref       uuid not null,
  moderation       public.moderation_state not null default 'visible',
  created_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  unique (sender_id, client_ref)
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);

-- -----------------------------------------------------------------------------
-- Règles d'accès
-- -----------------------------------------------------------------------------
create or replace function private.is_blocked_between(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_blocks b
     where (b.blocker_id = p_a and b.blocked_id = p_b)
        or (b.blocker_id = p_b and b.blocked_id = p_a)
  );
$$;

create or replace function private.can_moderate_club_content(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_platform_admin()
      or (p_club_id is not null and private.has_club_role(p_club_id, 'moderator'));
$$;

create or replace function private.can_view_post(p_post_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.posts p
     where p.id = p_post_id
       and (select auth.uid()) is not null
       and (p.author_id = (select auth.uid())
            or private.can_moderate_club_content(p.club_id)
            or (p.moderation = 'visible'
                and not private.is_blocked_between(p.author_id, (select auth.uid()))
                and (p.audience = 'public' or private.is_club_member(p.club_id))))
  );
$$;

create or replace function private.can_access_conversation(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
     where c.id = p_conversation_id
       and case c.kind
             when 'ride' then private.is_ride_participant(c.ride_id)
                              or private.can_manage_ride(c.ride_id)
             else exists (select 1 from public.conversation_members m
                           where m.conversation_id = c.id
                             and m.user_id = (select auth.uid()))
           end
  );
$$;

grant execute on function
  private.is_blocked_between(uuid, uuid),
  private.can_moderate_club_content(uuid),
  private.can_view_post(uuid),
  private.can_access_conversation(uuid)
to authenticated;

alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_reactions enable row level security;
alter table public.user_blocks enable row level security;
alter table public.content_reports enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

revoke all on public.posts, public.post_media, public.post_comments, public.post_reactions,
  public.user_blocks, public.content_reports, public.conversations,
  public.conversation_members, public.messages
from anon, authenticated;
grant select on public.posts, public.post_media, public.post_comments, public.post_reactions,
  public.user_blocks, public.content_reports, public.conversations,
  public.conversation_members, public.messages
to authenticated;

create policy "posts: visibles selon l'audience et le blocage"
  on public.posts for select to authenticated
  using (private.can_view_post(id));

create policy "post_media: suivent la publication"
  on public.post_media for select to authenticated
  using (private.can_view_post(post_id));

create policy "post_comments: publication visible, auteur non bloqué"
  on public.post_comments for select to authenticated
  using (
    private.can_view_post(post_id)
    and (author_id = (select auth.uid())
         or (moderation = 'visible'
             and not private.is_blocked_between(author_id, (select auth.uid())))
         or private.can_moderate_club_content(
              (select p.club_id from public.posts p where p.id = post_id)))
  );

create policy "post_reactions: publication visible"
  on public.post_reactions for select to authenticated
  using (private.can_view_post(post_id));

create policy "user_blocks: les siens"
  on public.user_blocks for select to authenticated
  using (blocker_id = (select auth.uid()));

create policy "content_reports: auteur du signalement et modérateurs"
  on public.content_reports for select to authenticated
  using (reporter_id = (select auth.uid())
         or private.is_platform_admin()
         or (club_id is not null and private.has_club_role(club_id, 'moderator')));

create policy "conversations: membres ou participants de la balade"
  on public.conversations for select to authenticated
  using (private.can_access_conversation(id));

create policy "conversation_members: même conversation"
  on public.conversation_members for select to authenticated
  using (private.can_access_conversation(conversation_id));

create policy "messages: membres de la conversation"
  on public.messages for select to authenticated
  using (private.can_access_conversation(conversation_id)
         and (moderation = 'visible' or sender_id = (select auth.uid())
              or private.is_platform_admin()));

-- -----------------------------------------------------------------------------
-- Storage : photos des publications
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('post-media', 'post-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.can_view_post_media(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.post_media m
                  where m.path = p_path and private.can_view_post(m.post_id));
$$;
grant execute on function private.can_view_post_media(text) to authenticated;

create policy "post-media: lecture par l'auteur ou si la publication est visible"
  on storage.objects for select to authenticated
  using (bucket_id = 'post-media'
         and ((storage.foldername(name))[1] = (select auth.uid())::text
              or private.can_view_post_media(name)));

create policy "post-media: ajout dans son dossier"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'post-media'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "post-media: suppression dans son dossier"
  on storage.objects for delete to authenticated
  using (bucket_id = 'post-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- -----------------------------------------------------------------------------
-- Publications
-- -----------------------------------------------------------------------------
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
     or cardinality(v_paths) > 4
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
  -- Chaque photo : dans le dossier de l'auteur, réellement envoyée.
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

-- Supprime sa publication ; retourne les chemins des photos à effacer.
create or replace function public.delete_post(p_post_id uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  paths text[];
begin
  if not exists (select 1 from public.posts where id = p_post_id and author_id = uid) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(path order by position), '{}') into paths
    from public.post_media where post_id = p_post_id;
  delete from public.posts where id = p_post_id;
  return paths;
end;
$$;

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
  my_reaction public.reaction_kind
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
           where r.post_id = p.id and r.user_id = (select auth.uid()))
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

create or replace function public.post_comments_list(p_post_id uuid)
returns table (
  id uuid,
  post_id uuid,
  author_id uuid,
  author_name text,
  author_avatar text,
  body text,
  moderation public.moderation_state,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select k.id, k.post_id, k.author_id, a.display_name, a.avatar_path, k.body, k.moderation, k.created_at
    from public.post_comments k
    join public.profiles a on a.id = k.author_id
    join public.posts p on p.id = k.post_id
   where k.post_id = p_post_id
     and private.can_view_post(p_post_id)
     and (k.author_id = (select auth.uid())
          or (k.moderation = 'visible'
              and not private.is_blocked_between(k.author_id, (select auth.uid())))
          or private.can_moderate_club_content(p.club_id))
   order by k.created_at
   limit 500;
$$;

create or replace function public.add_comment(p_post_id uuid, p_body text, p_client_ref uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing uuid;
  created uuid;
  post public.posts;
  v_body text := btrim(coalesce(p_body, ''));
begin
  if p_client_ref is null or char_length(v_body) not between 1 and 1000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select id into existing from public.post_comments where author_id = uid and client_ref = p_client_ref;
  if found then
    return existing;
  end if;
  select * into post from public.posts where id = p_post_id;
  if not found or not private.can_view_post(p_post_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if post.moderation <> 'visible' then
    raise exception 'content_hidden' using errcode = 'P0001';
  end if;
  if private.is_blocked_between(post.author_id, uid) then
    raise exception 'blocked' using errcode = 'P0001';
  end if;
  if (select count(*) from public.post_comments
       where author_id = uid and created_at > now() - interval '10 minutes') >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.post_comments (post_id, author_id, body, client_ref)
  values (p_post_id, uid, v_body, p_client_ref)
  returning id into created;
  return created;
end;
$$;

-- Supprime un commentaire : son auteur ou l'auteur de la publication.
create or replace function public.delete_comment(p_comment_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not exists (
    select 1 from public.post_comments k join public.posts p on p.id = k.post_id
     where k.id = p_comment_id and (k.author_id = uid or p.author_id = uid)) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.post_comments where id = p_comment_id;
end;
$$;

-- p_kind null : retire sa réaction.
create or replace function public.set_reaction(p_post_id uuid, p_kind public.reaction_kind)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.can_view_post(p_post_id)
     or exists (select 1 from public.posts where id = p_post_id and moderation <> 'visible') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_kind is null then
    delete from public.post_reactions where post_id = p_post_id and user_id = uid;
  else
    insert into public.post_reactions (post_id, user_id, kind) values (p_post_id, uid, p_kind)
    on conflict (post_id, user_id) do update set kind = excluded.kind, created_at = now();
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Blocage
-- -----------------------------------------------------------------------------
create or replace function public.block_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if p_user_id is null or p_user_id = uid
     or not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  insert into public.user_blocks (blocker_id, blocked_id) values (uid, p_user_id)
  on conflict do nothing;
  -- Les réactions croisées disparaissent.
  delete from public.post_reactions r using public.posts p
   where p.id = r.post_id
     and ((r.user_id = uid and p.author_id = p_user_id)
          or (r.user_id = p_user_id and p.author_id = uid));
end;
$$;

create or replace function public.unblock_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  delete from public.user_blocks where blocker_id = uid and blocked_id = p_user_id;
end;
$$;

create or replace function public.my_blocked_users()
returns table (user_id uuid, display_name text, username text, blocked_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select b.blocked_id, p.display_name, p.username, b.created_at
    from public.user_blocks b join public.profiles p on p.id = b.blocked_id
   where b.blocker_id = (select auth.uid())
   order by b.created_at desc;
$$;

-- -----------------------------------------------------------------------------
-- Signalements et modération
-- -----------------------------------------------------------------------------
create or replace function private.report_target_club(p_type public.report_target, p_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select case p_type
    when 'post' then (select club_id from public.posts where id = p_id)
    when 'comment' then (select p.club_id from public.post_comments k
                           join public.posts p on p.id = k.post_id where k.id = p_id)
    else null
  end;
$$;

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
begin
  if p_target is null or p_target_id is null or p_reason is null
     or (p_details is not null and char_length(p_details) > 500) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  visible := case p_target
    when 'post' then private.can_view_post(p_target_id)
    when 'comment' then exists (select 1 from public.post_comments k
                                 where k.id = p_target_id and private.can_view_post(k.post_id))
    when 'message' then exists (select 1 from public.messages m
                                 where m.id = p_target_id
                                   and private.can_access_conversation(m.conversation_id))
    when 'user' then p_target_id <> uid and exists (select 1 from public.profiles where id = p_target_id)
  end;
  if not coalesce(visible, false) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  insert into public.content_reports (reporter_id, target_type, target_id, club_id, reason, details)
  values (uid, p_target, p_target_id, private.report_target_club(p_target, p_target_id),
          p_reason, nullif(btrim(p_details), ''))
  on conflict do nothing;

  -- 3 signalements distincts : contenu masqué en attendant la modération.
  select count(distinct reporter_id) into reporters from public.content_reports
   where target_type = p_target and target_id = p_target_id and status = 'open';
  if reporters >= 3 then
    if p_target = 'post' then
      update public.posts set moderation = 'hidden', moderation_note = 'signalements'
       where id = p_target_id and moderation = 'visible';
    elsif p_target = 'comment' then
      update public.post_comments set moderation = 'hidden' where id = p_target_id;
    elsif p_target = 'message' then
      update public.messages set moderation = 'hidden' where id = p_target_id;
    end if;
  end if;
  perform private.log_action('report.create', p_target::text, p_target_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

create or replace function public.am_i_moderator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_platform_admin()
      or exists (select 1 from public.club_members m
                  where m.user_id = (select auth.uid())
                    and m.role in ('owner', 'admin', 'moderator'));
$$;

-- File de modération : signalements ouverts que l'utilisateur peut traiter.
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
  select r.target_type, r.target_id, r.club_id, count(*)::integer,
         array_agg(distinct r.reason::text), max(r.created_at),
         case r.target_type
           when 'post' then (select left(body, 200) from public.posts where id = r.target_id)
           when 'comment' then (select left(body, 200) from public.post_comments where id = r.target_id)
           when 'message' then (select left(body, 200) from public.messages where id = r.target_id)
           when 'user' then (select display_name from public.profiles where id = r.target_id)
         end,
         case r.target_type
           when 'post' then (select author_id from public.posts where id = r.target_id)
           when 'comment' then (select author_id from public.post_comments where id = r.target_id)
           when 'message' then (select sender_id from public.messages where id = r.target_id)
           when 'user' then r.target_id
         end,
         (select display_name from public.profiles where id = case r.target_type
           when 'post' then (select author_id from public.posts where id = r.target_id)
           when 'comment' then (select author_id from public.post_comments where id = r.target_id)
           when 'message' then (select sender_id from public.messages where id = r.target_id)
           when 'user' then r.target_id end),
         case r.target_type
           when 'post' then (select moderation from public.posts where id = r.target_id)
           when 'comment' then (select moderation from public.post_comments where id = r.target_id)
           when 'message' then (select moderation from public.messages where id = r.target_id)
           else 'visible'::public.moderation_state
         end
    from public.content_reports r
   where r.status = 'open'
     and (private.is_platform_admin()
          or (r.club_id is not null and private.has_club_role(r.club_id, 'moderator')))
   group by r.target_type, r.target_id, r.club_id
   order by max(r.created_at) desc
   limit 200;
$$;

-- p_action : 'hide' (masquer), 'restore' (rétablir), 'dismiss' (classer).
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
begin
  if p_action not in ('hide', 'restore', 'dismiss')
     or (p_note is not null and char_length(p_note) > 280) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if not (private.is_platform_admin()
          or (v_club is not null and private.has_club_role(v_club, 'moderator'))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_target = 'user' and p_action <> 'dismiss' then
    -- La suspension de comptes relève de l'administration (Mission 10).
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  if p_action <> 'dismiss' then
    v_state := case p_action when 'hide' then 'hidden' else 'visible' end;
    if p_target = 'post' then
      update public.posts set moderation = v_state, moderation_note = nullif(btrim(p_note), '')
       where id = p_target_id;
    elsif p_target = 'comment' then
      update public.post_comments set moderation = v_state where id = p_target_id;
    elsif p_target = 'message' then
      update public.messages set moderation = v_state where id = p_target_id;
    end if;
  end if;

  update public.content_reports
     set status = case p_action when 'hide' then 'actioned'::public.report_status
                                else 'dismissed'::public.report_status end,
         handled_by = uid, handled_at = now()
   where target_type = p_target and target_id = p_target_id and status = 'open';
  perform private.log_action('moderation.' || p_action, p_target::text, p_target_id,
    jsonb_build_object('note', p_note));
end;
$$;

-- -----------------------------------------------------------------------------
-- Messagerie
-- -----------------------------------------------------------------------------
create or replace function public.open_direct_conversation(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  v_key text;
  conv uuid;
begin
  if p_user_id is null or p_user_id = uid
     or not exists (select 1 from public.profiles where id = p_user_id)
     or not private.can_view_profile(p_user_id) then
    raise exception 'user_not_found' using errcode = 'P0001';
  end if;
  if private.is_blocked_between(uid, p_user_id) then
    raise exception 'blocked' using errcode = 'P0001';
  end if;
  v_key := least(uid::text, p_user_id::text) || ':' || greatest(uid::text, p_user_id::text);
  select id into conv from public.conversations where direct_key = v_key;
  if not found then
    insert into public.conversations (kind, direct_key, created_by)
    values ('direct', v_key, uid)
    on conflict (direct_key) do nothing
    returning id into conv;
    if conv is null then
      select id into conv from public.conversations where direct_key = v_key;
    end if;
  end if;
  insert into public.conversation_members (conversation_id, user_id)
  values (conv, uid), (conv, p_user_id)
  on conflict do nothing;
  return conv;
end;
$$;

create or replace function public.create_group_conversation(p_title text, p_member_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  conv uuid;
  m uuid;
  v_members uuid[] := array(select distinct x from unnest(coalesce(p_member_ids, '{}')) x
                              where x is not null and x <> uid);
begin
  if char_length(btrim(coalesce(p_title, ''))) not between 1 and 60
     or cardinality(v_members) not between 1 and 49 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  foreach m in array v_members loop
    if not private.can_view_profile(m) then
      raise exception 'user_not_found' using errcode = 'P0001';
    end if;
    if private.is_blocked_between(uid, m) then
      raise exception 'blocked' using errcode = 'P0001';
    end if;
  end loop;
  insert into public.conversations (kind, title, created_by)
  values ('group', btrim(p_title), uid) returning id into conv;
  insert into public.conversation_members (conversation_id, user_id, role) values (conv, uid, 'owner');
  insert into public.conversation_members (conversation_id, user_id)
  select conv, x from unnest(v_members) x;
  return conv;
end;
$$;

create or replace function public.add_conversation_members(p_conversation_id uuid, p_member_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  m uuid;
begin
  if not exists (select 1 from public.conversation_members cm
                   join public.conversations c on c.id = cm.conversation_id
                  where cm.conversation_id = p_conversation_id and cm.user_id = uid
                    and cm.role = 'owner' and c.kind = 'group') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  foreach m in array coalesce(p_member_ids, '{}') loop
    if m is null or not private.can_view_profile(m) then
      raise exception 'user_not_found' using errcode = 'P0001';
    end if;
    if private.is_blocked_between(uid, m) then
      raise exception 'blocked' using errcode = 'P0001';
    end if;
  end loop;
  insert into public.conversation_members (conversation_id, user_id)
  select p_conversation_id, x from unnest(p_member_ids) x on conflict do nothing;
  if (select count(*) from public.conversation_members where conversation_id = p_conversation_id) > 50 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
end;
$$;

-- Retire un membre (propriétaire) ou quitte le groupe (soi-même).
create or replace function public.remove_conversation_member(p_conversation_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  is_owner boolean;
  next_owner uuid;
begin
  if not exists (select 1 from public.conversations where id = p_conversation_id and kind = 'group') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select role = 'owner' into is_owner from public.conversation_members
   where conversation_id = p_conversation_id and user_id = uid;
  if is_owner is null or (p_user_id <> uid and not is_owner) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.conversation_members
   where conversation_id = p_conversation_id and user_id = p_user_id;
  if p_user_id = uid and is_owner then
    select user_id into next_owner from public.conversation_members
     where conversation_id = p_conversation_id order by joined_at limit 1;
    if next_owner is null then
      delete from public.conversations where id = p_conversation_id;
    else
      update public.conversation_members set role = 'owner'
       where conversation_id = p_conversation_id and user_id = next_owner;
    end if;
  end if;
end;
$$;

create or replace function public.open_ride_conversation(p_ride_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  conv uuid;
begin
  if not (private.is_ride_participant(p_ride_id) or private.can_manage_ride(p_ride_id)) then
    raise exception 'not_participant' using errcode = 'P0001';
  end if;
  insert into public.conversations (kind, ride_id, created_by)
  values ('ride', p_ride_id, uid)
  on conflict (ride_id) do nothing;
  select id into conv from public.conversations where ride_id = p_ride_id;
  insert into public.conversation_members (conversation_id, user_id)
  values (conv, uid) on conflict do nothing;
  return conv;
end;
$$;

create or replace function public.send_message(p_conversation_id uuid, p_body text, p_client_ref uuid)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  existing public.messages;
  created public.messages;
  conv public.conversations;
  v_body text := btrim(coalesce(p_body, ''));
begin
  if p_client_ref is null or char_length(v_body) not between 1 and 2000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select * into existing from public.messages where sender_id = uid and client_ref = p_client_ref;
  if found then
    return existing;
  end if;
  select * into conv from public.conversations where id = p_conversation_id;
  if not found or not private.can_access_conversation(p_conversation_id) then
    raise exception 'conversation_not_found' using errcode = 'P0001';
  end if;
  if conv.kind = 'direct' and exists (
       select 1 from public.conversation_members m
        where m.conversation_id = conv.id and m.user_id <> uid
          and private.is_blocked_between(uid, m.user_id)) then
    raise exception 'blocked' using errcode = 'P0001';
  end if;
  if (select count(*) from public.messages
       where sender_id = uid and created_at > now() - interval '1 minute') >= 30 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.messages (conversation_id, sender_id, body, client_ref)
  values (conv.id, uid, v_body, p_client_ref)
  returning * into created;
  update public.conversations set last_message_at = created.created_at where id = conv.id;
  insert into public.conversation_members (conversation_id, user_id, last_read_at)
  values (conv.id, uid, created.created_at)
  on conflict (conversation_id, user_id) do update set last_read_at = excluded.last_read_at;
  return created;
end;
$$;

create or replace function public.delete_message(p_message_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  update public.messages set body = '', deleted_at = now()
   where id = p_message_id and sender_id = uid and deleted_at is null;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if not private.can_access_conversation(p_conversation_id) then
    raise exception 'conversation_not_found' using errcode = 'P0001';
  end if;
  insert into public.conversation_members (conversation_id, user_id, last_read_at)
  values (p_conversation_id, uid, now())
  on conflict (conversation_id, user_id) do update set last_read_at = now();
end;
$$;

-- Boîte de réception : conversations accessibles, aperçu et non-lus.
create or replace function public.my_conversations()
returns table (
  id uuid,
  kind public.conversation_kind,
  title text,
  ride_id uuid,
  other_user_id uuid,
  other_avatar text,
  last_message text,
  last_message_at timestamptz,
  unread_count integer,
  blocked boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with mine as (
    select c.* from public.conversations c
     where exists (select 1 from public.conversation_members m
                    where m.conversation_id = c.id and m.user_id = (select auth.uid()))
       and private.can_access_conversation(c.id)
  ), other as (
    select distinct on (m.conversation_id) m.conversation_id, m.user_id
      from public.conversation_members m
      join mine c on c.id = m.conversation_id and c.kind = 'direct'
     where m.user_id <> (select auth.uid())
  )
  select c.id, c.kind,
         case c.kind
           when 'group' then c.title
           when 'ride' then (select r.title from public.rides r where r.id = c.ride_id)
           else (select p.display_name from public.profiles p where p.id = o.user_id)
         end,
         c.ride_id, o.user_id,
         (select p.avatar_path from public.profiles p where p.id = o.user_id),
         (select case when m.deleted_at is not null then null else left(m.body, 120) end
            from public.messages m
           where m.conversation_id = c.id and m.moderation = 'visible'
             and (m.sender_id is null
                  or not private.is_blocked_between(m.sender_id, (select auth.uid())))
           order by m.created_at desc limit 1),
         c.last_message_at,
         (select count(*)::integer from public.messages m
           where m.conversation_id = c.id
             and m.sender_id is distinct from (select auth.uid())
             and m.moderation = 'visible'
             and m.created_at > coalesce(
               (select cm.last_read_at from public.conversation_members cm
                 where cm.conversation_id = c.id and cm.user_id = (select auth.uid())),
               '-infinity'::timestamptz)),
         coalesce(o.user_id is not null and private.is_blocked_between(o.user_id, (select auth.uid())), false)
    from mine c
    left join other o on o.conversation_id = c.id
   order by coalesce(c.last_message_at, c.created_at) desc
   limit 200;
$$;

-- Messages d'une conversation avec le nom de l'expéditeur.
create or replace function public.conversation_messages(
  p_conversation_id uuid, p_before timestamptz default null, p_limit integer default 50
)
returns table (
  id uuid,
  conversation_id uuid,
  sender_id uuid,
  sender_name text,
  body text,
  client_ref uuid,
  moderation public.moderation_state,
  created_at timestamptz,
  deleted_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select * from (
    select m.id, m.conversation_id, m.sender_id, p.display_name, m.body, m.client_ref,
           m.moderation, m.created_at, m.deleted_at
      from public.messages m
      left join public.profiles p on p.id = m.sender_id
     where m.conversation_id = p_conversation_id
       and private.can_access_conversation(p_conversation_id)
       and (m.sender_id = (select auth.uid())
            or (m.moderation = 'visible'
                and (m.sender_id is null
                     or not private.is_blocked_between(m.sender_id, (select auth.uid())))))
       and (p_before is null or m.created_at < p_before)
     order by m.created_at desc
     limit least(greatest(coalesce(p_limit, 50), 1), 200)
  ) t order by t.created_at;
$$;

-- -----------------------------------------------------------------------------
-- Droits d'exécution et temps réel
-- -----------------------------------------------------------------------------
revoke all on function private.report_target_club(public.report_target, uuid)
  from public, anon, authenticated;

grant execute on function
  public.create_post(uuid, text, public.post_audience, uuid, text[]),
  public.delete_post(uuid),
  public.feed_posts(uuid, uuid, timestamptz, integer, uuid),
  public.post_comments_list(uuid),
  public.add_comment(uuid, text, uuid),
  public.delete_comment(uuid),
  public.set_reaction(uuid, public.reaction_kind),
  public.block_user(uuid),
  public.unblock_user(uuid),
  public.my_blocked_users(),
  public.report_content(public.report_target, uuid, public.report_reason, text),
  public.am_i_moderator(),
  public.moderation_queue(),
  public.moderate_content(public.report_target, uuid, text, text),
  public.open_direct_conversation(uuid),
  public.create_group_conversation(text, uuid[]),
  public.add_conversation_members(uuid, uuid[]),
  public.remove_conversation_member(uuid, uuid),
  public.open_ride_conversation(uuid),
  public.send_message(uuid, text, uuid),
  public.delete_message(uuid),
  public.mark_conversation_read(uuid),
  public.my_conversations(),
  public.conversation_messages(uuid, timestamptz, integer)
to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;
