-- =============================================================================
-- Rider Group — Migration 0013 : notifications dans l'application (Mission 08 ter)
-- -----------------------------------------------------------------------------
-- Décision D-52 : cloche + sons dans l'application ; notifications push plus
-- tard. Les notifications sont créées UNIQUEMENT par le serveur (déclencheurs)
-- et ne sont lisibles que par leur destinataire.
--
-- Événements :
--   * balades : demande de participation (aux gestionnaires), nouveau
--     participant, demande acceptée / refusée, retrait, invitation, balade
--     verrouillée / démarrée / terminée / annulée (aux participants) ;
--   * clubs : demande d'adhésion (aux administrateurs), demande acceptée /
--     refusée, invitation ;
--   * communauté : commentaire et réaction sur ses publications.
-- Jamais de notification envers soi-même ni entre motards qui se bloquent.
-- Rétention : 90 jours.
-- =============================================================================

create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        text not null check (kind in (
                'ride_join_request', 'ride_joined', 'ride_request_approved',
                'ride_request_rejected', 'ride_removed', 'ride_invitation',
                'ride_locked', 'ride_started', 'ride_finished', 'ride_cancelled',
                'club_join_request', 'club_request_approved', 'club_request_rejected',
                'club_invitation', 'post_comment', 'post_reaction')),
  actor_id    uuid references public.profiles (id) on delete set null,
  ride_id     uuid references public.rides (id) on delete cascade,
  club_id     uuid references public.clubs (id) on delete cascade,
  post_id     uuid references public.posts (id) on delete cascade,
  -- Demande ou invitation concernée (pour agir depuis la cloche).
  ref_id      uuid,
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  read_at     timestamptz
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;
create index notifications_actor_idx on public.notifications (actor_id);
create index notifications_ride_idx on public.notifications (ride_id);
create index notifications_club_idx on public.notifications (club_id);
create index notifications_post_idx on public.notifications (post_id);

alter table public.notifications enable row level security;
revoke all on public.notifications from anon, authenticated;
grant select on public.notifications to authenticated;
create policy "notifications: les siennes"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function private.notify(
  p_user uuid, p_kind text, p_actor uuid,
  p_ride uuid default null, p_club uuid default null, p_post uuid default null,
  p_ref uuid default null, p_data jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or p_user = p_actor then
    return;
  end if;
  if p_actor is not null and private.is_blocked_between(p_user, p_actor) then
    return;
  end if;
  insert into public.notifications (user_id, kind, actor_id, ride_id, club_id, post_id, ref_id, data)
  values (p_user, p_kind, p_actor, p_ride, p_club, p_post, p_ref, coalesce(p_data, '{}'::jsonb));
end;
$$;

-- Gestionnaires d'une balade : organisateur et administrateurs du club.
create or replace function private.ride_managers(p_ride_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select organizer_id from public.rides where id = p_ride_id and organizer_id is not null
  union
  select m.user_id from public.rides r
    join public.club_members m on m.club_id = r.club_id and m.role in ('owner', 'admin')
   where r.id = p_ride_id;
$$;

-- -----------------------------------------------------------------------------
-- Balades
-- -----------------------------------------------------------------------------
create or replace function private.notify_ride_participants()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  manager uuid;
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    if new.status = 'pending' then
      for manager in select * from private.ride_managers(new.ride_id) loop
        perform private.notify(manager, 'ride_join_request', new.user_id, new.ride_id,
                               p_ref => new.user_id);
      end loop;
    elsif new.status = 'confirmed' and new.user_id = coalesce(actor, new.user_id) then
      -- Adhésion directe (balade libre ou invitation acceptée).
      for manager in select * from private.ride_managers(new.ride_id) loop
        perform private.notify(manager, 'ride_joined', new.user_id, new.ride_id);
      end loop;
    elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'confirmed' then
      perform private.notify(new.user_id, 'ride_request_approved', actor, new.ride_id);
    elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'rejected' then
      perform private.notify(new.user_id, 'ride_request_rejected', actor, new.ride_id);
    elsif tg_op = 'UPDATE' and new.status = 'removed' then
      perform private.notify(new.user_id, 'ride_removed', actor, new.ride_id);
    end if;
  end if;
  return null;
end;
$$;
create trigger ride_participants_notify
  after insert or update of status on public.ride_participants
  for each row execute function private.notify_ride_participants();

create or replace function private.notify_ride_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    perform private.notify(new.invitee_id, 'ride_invitation', new.invited_by, new.ride_id,
                           p_ref => new.id);
  end if;
  return null;
end;
$$;
create trigger ride_invitations_notify
  after insert on public.ride_invitations
  for each row execute function private.notify_ride_invitation();

create or replace function private.notify_ride_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  kind text;
  actor uuid := (select auth.uid());
  participant uuid;
begin
  kind := case
    when new.status = 'in_progress' and old.status <> 'in_progress' then 'ride_started'
    when new.status = 'finished' and old.status <> 'finished' then 'ride_finished'
    when new.status = 'cancelled' and old.status <> 'cancelled' then 'ride_cancelled'
    when new.joins_locked and not old.joins_locked then 'ride_locked'
  end;
  if kind is null then
    return null;
  end if;
  for participant in
    select user_id from public.ride_participants
     where ride_id = new.id and status = 'confirmed'
  loop
    perform private.notify(participant, kind, coalesce(actor, new.organizer_id), new.id,
                           p_data => case when kind = 'ride_cancelled'
                                          then jsonb_build_object('reason', new.cancellation_reason)
                                          else '{}'::jsonb end);
  end loop;
  return null;
end;
$$;
create trigger rides_notify_status
  after update of status, joins_locked on public.rides
  for each row execute function private.notify_ride_status();

-- -----------------------------------------------------------------------------
-- Clubs
-- -----------------------------------------------------------------------------
create or replace function private.notify_club_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  admin uuid;
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    for admin in
      select user_id from public.club_members
       where club_id = new.club_id and role in ('owner', 'admin')
    loop
      perform private.notify(admin, 'club_join_request', new.user_id, p_club => new.club_id,
                             p_ref => new.id);
    end loop;
  elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status in ('approved', 'rejected') then
    perform private.notify(new.user_id,
      case new.status when 'approved' then 'club_request_approved' else 'club_request_rejected' end,
      new.decided_by, p_club => new.club_id);
  end if;
  return null;
end;
$$;
create trigger club_join_requests_notify
  after insert or update of status on public.club_join_requests
  for each row execute function private.notify_club_request();

create or replace function private.notify_club_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    perform private.notify(new.invitee_id, 'club_invitation', new.invited_by,
                           p_club => new.club_id, p_ref => new.id);
  end if;
  return null;
end;
$$;
create trigger club_invitations_notify
  after insert on public.club_invitations
  for each row execute function private.notify_club_invitation();

-- -----------------------------------------------------------------------------
-- Communauté
-- -----------------------------------------------------------------------------
create or replace function private.notify_post_comment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.notify((select author_id from public.posts where id = new.post_id),
                         'post_comment', new.author_id, p_post => new.post_id,
                         p_data => jsonb_build_object('excerpt', left(new.body, 80)));
  return null;
end;
$$;
create trigger post_comments_notify
  after insert on public.post_comments
  for each row execute function private.notify_post_comment();

create or replace function private.notify_post_reaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.notify((select author_id from public.posts where id = new.post_id),
                         'post_reaction', new.user_id, p_post => new.post_id,
                         p_data => jsonb_build_object('reaction', new.kind));
  return null;
end;
$$;
create trigger post_reactions_notify
  after insert on public.post_reactions
  for each row execute function private.notify_post_reaction();

-- -----------------------------------------------------------------------------
-- Lecture
-- -----------------------------------------------------------------------------
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
  -- La demande / l'invitation attend-elle encore une réponse ?
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

-- p_ids null : tout marquer comme lu.
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  update public.notifications set read_at = now()
   where user_id = uid and read_at is null
     and (p_ids is null or id = any (p_ids));
end;
$$;

create or replace function private.purge_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  delete from public.notifications where created_at < now() - interval '90 days';
  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function
  private.notify(uuid, text, uuid, uuid, uuid, uuid, uuid, jsonb),
  private.ride_managers(uuid),
  private.notify_ride_participants(),
  private.notify_ride_invitation(),
  private.notify_ride_status(),
  private.notify_club_request(),
  private.notify_club_invitation(),
  private.notify_post_comment(),
  private.notify_post_reaction(),
  private.purge_notifications()
from public, anon, authenticated;

grant execute on function
  public.my_notifications(integer),
  public.mark_notifications_read(uuid[])
to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-purge-notifications', '41 3 * * *',
                          'select private.purge_notifications()');
  end if;
end;
$$;
