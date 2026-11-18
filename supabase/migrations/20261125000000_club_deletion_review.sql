-- =============================================================================
-- Rider Group — Migration 0020 : suppression encadrée des clubs vérifiés
-- -----------------------------------------------------------------------------
-- D-63 : un club ou regroupement VÉRIFIÉ ne se supprime pas d'un geste. Son
-- propriétaire dépose une demande MOTIVÉE ; l'équipe Rider Group et les
-- responsables du club sont prévenus et voient la raison. L'équipe accepte
-- (suppression immédiate) ou refuse. Sans décision après 15 jours, le club
-- est supprimé automatiquement. Le propriétaire peut annuler tant que la
-- demande est en attente. Objectif : empêcher une personne mal intentionnée
-- de supprimer un groupe établi. Un club non vérifié se supprime comme avant.
-- =============================================================================

create table public.club_deletion_requests (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid references public.clubs (id) on delete set null,
  club_name     text not null,
  requested_by  uuid references public.profiles (id) on delete set null,
  reason        text not null check (char_length(btrim(reason)) between 10 and 1000),
  status        text not null default 'pending'
                check (status in ('pending', 'approved', 'rejected', 'cancelled', 'auto_deleted')),
  review_note   text check (review_note is null or char_length(review_note) <= 1000),
  reviewed_by   uuid references auth.users (id) on delete set null,
  reviewed_at   timestamptz,
  due_at        timestamptz not null default now() + interval '15 days',
  created_at    timestamptz not null default now()
);
create unique index club_deletion_one_pending
  on public.club_deletion_requests (club_id) where status = 'pending';
create index club_deletion_requests_requested_by_idx on public.club_deletion_requests (requested_by);
create index club_deletion_requests_reviewed_by_idx on public.club_deletion_requests (reviewed_by);
create index club_deletion_requests_due_idx on public.club_deletion_requests (due_at) where status = 'pending';

alter table public.club_deletion_requests enable row level security;
revoke all on public.club_deletion_requests from anon, authenticated;
grant select on public.club_deletion_requests to authenticated;
create policy "club_deletion_requests: responsables du club et équipe"
  on public.club_deletion_requests for select to authenticated
  using (private.is_platform_admin()
         or requested_by = (select auth.uid())
         or (club_id is not null and private.has_club_role(club_id, 'admin')));

create or replace function private.club_is_verified(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.clubs
                  where id = p_club_id and verified_at is not null
                    and (verified_until is null or verified_until > now()));
$$;

-- Suppression effective (journalisée), commune aux trois chemins.
create or replace function private.erase_club(p_club_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.log_action('club.delete', 'club', p_club_id,
    (select jsonb_build_object('name', name, 'via', p_reason) from public.clubs where id = p_club_id));
  delete from public.clubs where id = p_club_id;
end;
$$;

create or replace function public.delete_club(p_club_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if private.club_role_of(p_club_id, uid) is distinct from 'owner' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if private.club_is_verified(p_club_id) then
    raise exception 'deletion_review_required' using errcode = 'P0001';
  end if;
  perform private.erase_club(p_club_id, 'owner');
end;
$$;

create or replace function public.request_club_deletion(p_club_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  c public.clubs;
  created uuid;
  r record;
begin
  if private.club_role_of(p_club_id, uid) is distinct from 'owner' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not private.club_is_verified(p_club_id) then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) not between 10 and 1000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select * into c from public.clubs where id = p_club_id;
  begin
    insert into public.club_deletion_requests (club_id, club_name, requested_by, reason)
    values (p_club_id, c.name, uid, btrim(p_reason))
    returning id into created;
  exception when unique_violation then
    raise exception 'deletion_pending' using errcode = 'P0001';
  end;
  -- Prévenir l'équipe et les autres responsables du club, avec la raison.
  for r in
    select user_id from private.platform_admins
    union
    select user_id from public.club_members where club_id = p_club_id and role in ('owner', 'admin')
  loop
    perform private.notify(r.user_id, 'club_deletion_requested', uid, p_club => p_club_id,
                           p_ref => created,
                           p_data => jsonb_build_object('name', c.name, 'reason', btrim(p_reason)));
  end loop;
  perform private.log_action('club.deletion.request', 'club', p_club_id,
    jsonb_build_object('reason', btrim(p_reason)));
  return created;
end;
$$;

create or replace function public.cancel_club_deletion(p_club_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if private.club_role_of(p_club_id, uid) is distinct from 'owner' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.club_deletion_requests set status = 'cancelled', reviewed_at = now()
   where club_id = p_club_id and status = 'pending';
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
  perform private.log_action('club.deletion.cancel', 'club', p_club_id);
end;
$$;

create or replace function public.club_deletion_queue()
returns table (
  request_id uuid, club_id uuid, club_name text, club_city text, member_count integer,
  is_regroupement boolean, requester_id uuid, requester_name text, reason text,
  due_at timestamptz, created_at timestamptz
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
    select d.id, d.club_id, d.club_name, c.city, c.member_count, c.kind = 'regroupement',
           d.requested_by, p.display_name, d.reason, d.due_at, d.created_at
      from public.club_deletion_requests d
      left join public.clubs c on c.id = d.club_id
      left join public.profiles p on p.id = d.requested_by
     where d.status = 'pending'
     order by d.due_at;
end;
$$;

create or replace function public.review_club_deletion(
  p_request_id uuid, p_approve boolean, p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.club_deletion_requests;
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select * into d from public.club_deletion_requests
   where id = p_request_id and status = 'pending' for update;
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
  update public.club_deletion_requests
     set status = case when p_approve then 'approved' else 'rejected' end,
         review_note = nullif(btrim(p_note), ''), reviewed_by = uid, reviewed_at = now()
   where id = d.id;
  perform private.notify(d.requested_by,
    case when p_approve then 'club_deletion_approved' else 'club_deletion_rejected' end,
    null, p_club => case when p_approve then null else d.club_id end,
    p_data => jsonb_build_object('name', d.club_name, 'note', nullif(btrim(p_note), '')));
  if p_approve and d.club_id is not null then
    perform private.erase_club(d.club_id, 'team_review');
  end if;
end;
$$;

-- Tâche quotidienne : demandes sans décision depuis 15 jours.
create or replace function private.process_club_deletions()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  n integer := 0;
begin
  for d in
    select * from public.club_deletion_requests
     where status = 'pending' and due_at <= now()
     for update skip locked
  loop
    update public.club_deletion_requests set status = 'auto_deleted', reviewed_at = now()
     where id = d.id;
    perform private.notify(d.requested_by, 'club_deletion_auto', null,
                           p_data => jsonb_build_object('name', d.club_name));
    if d.club_id is not null then
      perform private.erase_club(d.club_id, 'auto_after_15_days');
    end if;
    n := n + 1;
  end loop;
  return n;
end;
$$;

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
  'club_deletion_auto'));

revoke all on function
  private.erase_club(uuid, text),
  private.process_club_deletions()
from public, anon, authenticated;
revoke all on function private.club_is_verified(uuid) from public, anon;
grant execute on function private.club_is_verified(uuid) to authenticated;

grant execute on function
  public.request_club_deletion(uuid, text),
  public.cancel_club_deletion(uuid),
  public.club_deletion_queue(),
  public.review_club_deletion(uuid, boolean, text)
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-club-deletions', '23 * * * *',
                          'select private.process_club_deletions()');
  end if;
end;
$$;
