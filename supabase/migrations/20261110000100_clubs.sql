-- =============================================================================
-- Rider Group — Migration 0003 : clubs de motards (Mission 03)
-- -----------------------------------------------------------------------------
-- Principes :
--   * Création libre : tout utilisateur connecté peut créer un club.
--   * Clubs publics (adhésion libre ou sur approbation, toujours découvrables)
--     et privés (sur approbation ou sur invitation, référencés ou masqués).
--   * Rôles par club : owner > admin > moderator > member.
--   * Toutes les écritures sensibles passent par des fonctions serveur
--     (SECURITY DEFINER) qui vérifient les permissions ; les tables ne sont
--     qu'en lecture côté client, sauf les colonnes éditables de `clubs`.
--   * Le badge « Vérifié » ne peut être accordé que par l'administration
--     Rider Group (private.platform_admins) ; un club ne peut pas se
--     l'attribuer. Il ne donne aucun accès aux données privées.
--
-- Codes d'erreur (message de l'exception, repris par l'application) :
--   not_authenticated, not_allowed, invalid_input, club_not_found,
--   club_name_taken, club_suspended, already_member, not_member,
--   invitation_required, request_not_found, invitation_not_found,
--   owner_cannot_leave, use_transfer_ownership, user_not_found,
--   already_verified, verification_pending, rate_limited
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Types
-- -----------------------------------------------------------------------------
create type public.club_visibility as enum ('public', 'private');
create type public.club_join_policy as enum ('open', 'approval', 'invite_only');
create type public.club_role as enum ('owner', 'admin', 'moderator', 'member');
create type public.club_request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
create type public.club_invitation_status as enum ('pending', 'accepted', 'declined', 'revoked');
create type public.club_verification_status as enum ('pending', 'approved', 'rejected');

-- -----------------------------------------------------------------------------
-- Administration de la plateforme et journal d'audit (schéma privé)
-- -----------------------------------------------------------------------------
create table private.platform_admins (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  granted_at  timestamptz not null default now(),
  note        text
);
comment on table private.platform_admins is
  'Administrateurs Rider Group. Attribution manuelle (SQL / service_role) uniquement.';

create table private.audit_logs (
  id           bigint generated always as identity primary key,
  actor_id     uuid,
  action       text        not null,
  entity_type  text        not null,
  entity_id    uuid,
  details      jsonb       not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);
create index audit_logs_entity_idx on private.audit_logs (entity_type, entity_id);
create index audit_logs_actor_idx on private.audit_logs (actor_id, created_at desc);

revoke all on private.platform_admins, private.audit_logs from public, anon, authenticated;

create or replace function private.log_action(
  p_action text, p_entity_type text, p_entity_id uuid, p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (auth.uid(), p_action, p_entity_type, p_entity_id, coalesce(p_details, '{}'::jsonb));
$$;

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------
create table public.clubs (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  description   text not null default '',
  rules         text not null default '',
  city          text not null,
  country_code  text not null default 'CD',
  logo_path     text,
  cover_path    text,
  visibility    public.club_visibility  not null,
  is_listed     boolean                 not null default true,
  join_policy   public.club_join_policy not null,
  owner_id      uuid not null references public.profiles (id) on delete restrict,
  member_count  integer not null default 0 check (member_count >= 0),
  verified_at   timestamptz,
  suspended_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint clubs_name_length check (char_length(btrim(name)) between 3 and 80),
  constraint clubs_description_length check (char_length(description) <= 2000),
  constraint clubs_rules_length check (char_length(rules) <= 5000),
  constraint clubs_city_length check (char_length(btrim(city)) between 2 and 80),
  constraint clubs_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  -- Public : toujours référencé, adhésion libre ou sur approbation.
  -- Privé : adhésion sur approbation ou sur invitation, référencé ou masqué.
  constraint clubs_policy_consistency check (
    (visibility = 'public' and is_listed and join_policy in ('open', 'approval'))
    or (visibility = 'private' and join_policy in ('approval', 'invite_only'))
  )
);

-- Nom unique (insensible à la casse) pour limiter l'usurpation d'identité.
create unique index clubs_name_unique on public.clubs (lower(btrim(name)));
create index clubs_discovery_idx on public.clubs (visibility, is_listed) where suspended_at is null;
create index clubs_owner_idx on public.clubs (owner_id);
create index clubs_city_idx on public.clubs (lower(city));

create trigger clubs_set_updated_at
  before update on public.clubs
  for each row execute function private.set_updated_at();

create table public.club_members (
  club_id    uuid not null references public.clubs (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       public.club_role not null default 'member',
  joined_at  timestamptz not null default now(),
  primary key (club_id, user_id)
);
create unique index club_members_one_owner on public.club_members (club_id) where role = 'owner';
create index club_members_user_idx on public.club_members (user_id);

create table public.club_join_requests (
  id          uuid primary key default gen_random_uuid(),
  club_id     uuid not null references public.clubs (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  message     text,
  status      public.club_request_status not null default 'pending',
  created_at  timestamptz not null default now(),
  decided_at  timestamptz,
  decided_by  uuid references public.profiles (id) on delete set null,
  constraint club_join_requests_message_length check (message is null or char_length(message) <= 500)
);
create unique index club_join_requests_one_pending
  on public.club_join_requests (club_id, user_id) where status = 'pending';
create index club_join_requests_user_idx on public.club_join_requests (user_id);

create table public.club_invitations (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null references public.clubs (id) on delete cascade,
  invitee_id    uuid not null references public.profiles (id) on delete cascade,
  invited_by    uuid references public.profiles (id) on delete set null,
  status        public.club_invitation_status not null default 'pending',
  created_at    timestamptz not null default now(),
  responded_at  timestamptz
);
create unique index club_invitations_one_pending
  on public.club_invitations (club_id, invitee_id) where status = 'pending';
create index club_invitations_invitee_idx on public.club_invitations (invitee_id);

create table public.club_verification_requests (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null references public.clubs (id) on delete cascade,
  requested_by  uuid references public.profiles (id) on delete set null,
  message       text,
  status        public.club_verification_status not null default 'pending',
  review_note   text,
  reviewed_by   uuid references auth.users (id) on delete set null,
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now(),
  constraint club_verification_message_length check (message is null or char_length(message) <= 1000),
  constraint club_verification_note_length check (review_note is null or char_length(review_note) <= 1000)
);
create unique index club_verification_one_pending
  on public.club_verification_requests (club_id) where status = 'pending';

-- -----------------------------------------------------------------------------
-- Fonctions d'autorisation (utilisées par les politiques RLS)
-- SECURITY DEFINER pour éviter la récursion RLS ; aucune donnée n'est
-- renvoyée hormis un booléen / un rôle concernant l'utilisateur courant.
-- -----------------------------------------------------------------------------
create or replace function private.club_role_rank(p_role public.club_role)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'owner' then 4
    when 'admin' then 3
    when 'moderator' then 2
    when 'member' then 1
    else 0
  end;
$$;

create or replace function private.club_role_of(p_club_id uuid, p_user_id uuid)
returns public.club_role
language sql
stable
security definer
set search_path = ''
as $$
  select m.role from public.club_members m
   where m.club_id = p_club_id and m.user_id = p_user_id;
$$;

create or replace function private.is_club_member(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.club_members m
     where m.club_id = p_club_id and m.user_id = (select auth.uid())
  );
$$;

create or replace function private.has_club_role(p_club_id uuid, p_min_role public.club_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    private.club_role_rank(private.club_role_of(p_club_id, (select auth.uid())))
      >= private.club_role_rank(p_min_role),
    false
  );
$$;

-- Le club est-il visible par l'utilisateur courant ?
create or replace function private.can_view_club(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clubs c
     where c.id = p_club_id
       and (
         (c.suspended_at is null and (c.visibility = 'public' or c.is_listed))
         or exists (select 1 from public.club_members m
                     where m.club_id = c.id and m.user_id = (select auth.uid()))
         or exists (select 1 from public.club_invitations i
                     where i.club_id = c.id and i.invitee_id = (select auth.uid())
                       and i.status = 'pending')
         or exists (select 1 from public.club_join_requests r
                     where r.club_id = c.id and r.user_id = (select auth.uid())
                       and r.status = 'pending')
       )
  );
$$;

-- La liste des membres est-elle visible ? (public actif, ou membre)
create or replace function private.can_view_club_members(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clubs c
     where c.id = p_club_id
       and ((c.visibility = 'public' and c.suspended_at is null)
            or private.is_club_member(c.id))
  );
$$;

create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.platform_admins a where a.user_id = (select auth.uid())
  );
$$;

-- Les politiques RLS s'exécutent avec les droits de l'appelant : il doit
-- pouvoir résoudre ces fonctions. Le schéma private n'est pas exposé par
-- l'API REST ; ses tables restent inaccessibles (aucun GRANT).
grant usage on schema private to authenticated;
grant execute on function
  private.club_role_rank(public.club_role),
  private.club_role_of(uuid, uuid),
  private.is_club_member(uuid),
  private.has_club_role(uuid, public.club_role),
  private.can_view_club(uuid),
  private.can_view_club_members(uuid),
  private.is_platform_admin()
to authenticated;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

-- Compteur de membres maintenu côté serveur.
create or replace function private.sync_club_member_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.clubs set member_count = member_count + 1 where id = new.club_id;
  elsif tg_op = 'DELETE' then
    update public.clubs set member_count = greatest(member_count - 1, 0) where id = old.club_id;
  end if;
  return null;
end;
$$;

create trigger club_members_count
  after insert or delete on public.club_members
  for each row execute function private.sync_club_member_count();

-- Seul le propriétaire modifie visibilité, référencement et mode d'adhésion.
create or replace function private.guard_club_settings()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and (new.visibility is distinct from old.visibility
          or new.is_listed is distinct from old.is_listed
          or new.join_policy is distinct from old.join_policy)
     and private.club_role_of(old.id, auth.uid()) is distinct from 'owner' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger clubs_guard_settings
  before update on public.clubs
  for each row execute function private.guard_club_settings();

revoke all on function
  private.log_action(text, text, uuid, jsonb),
  private.sync_club_member_count(),
  private.guard_club_settings()
from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Row Level Security et privilèges
-- -----------------------------------------------------------------------------
alter table public.clubs enable row level security;
alter table public.club_members enable row level security;
alter table public.club_join_requests enable row level security;
alter table public.club_invitations enable row level security;
alter table public.club_verification_requests enable row level security;

revoke all on public.clubs, public.club_members, public.club_join_requests,
  public.club_invitations, public.club_verification_requests
from anon, authenticated;

grant select on public.clubs, public.club_members, public.club_join_requests,
  public.club_invitations, public.club_verification_requests
to authenticated;

-- Colonnes éditables directement (propriétaire / administrateurs du club).
-- owner_id, member_count, verified_at, suspended_at : jamais modifiables
-- par le client.
grant update (name, description, rules, city, country_code, logo_path, cover_path,
              visibility, is_listed, join_policy)
  on public.clubs to authenticated;

create policy "clubs: lecture si visible"
  on public.clubs for select to authenticated
  using (private.can_view_club(id));

create policy "clubs: modification par owner/admin"
  on public.clubs for update to authenticated
  using (private.has_club_role(id, 'admin'))
  with check (private.has_club_role(id, 'admin'));

create policy "club_members: lecture si club public ou membre"
  on public.club_members for select to authenticated
  using (private.can_view_club_members(club_id));

create policy "club_join_requests: demandeur ou owner/admin"
  on public.club_join_requests for select to authenticated
  using (user_id = (select auth.uid()) or private.has_club_role(club_id, 'admin'));

create policy "club_invitations: invité ou owner/admin"
  on public.club_invitations for select to authenticated
  using (invitee_id = (select auth.uid()) or private.has_club_role(club_id, 'admin'));

create policy "club_verification_requests: owner/admin du club ou plateforme"
  on public.club_verification_requests for select to authenticated
  using (private.has_club_role(club_id, 'admin') or private.is_platform_admin());

-- -----------------------------------------------------------------------------
-- Fonctions serveur (RPC)
-- -----------------------------------------------------------------------------

create or replace function private.require_user()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  return uid;
end;
$$;
grant execute on function private.require_user() to authenticated;

-- Création d'un club : libre, sans approbation préalable.
create or replace function public.create_club(
  p_name         text,
  p_city         text,
  p_visibility   public.club_visibility,
  p_join_policy  public.club_join_policy,
  p_is_listed    boolean default true,
  p_description  text default '',
  p_rules        text default '',
  p_country_code text default 'CD'
)
returns public.clubs
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created public.clubs;
begin
  -- Limitation des abus : 3 créations par 24 h et par utilisateur.
  if (select count(*) from public.clubs c
       where c.owner_id = uid and c.created_at > now() - interval '24 hours') >= 3 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  begin
    insert into public.clubs (name, city, visibility, join_policy, is_listed,
                              description, rules, country_code, owner_id)
    values (btrim(p_name), btrim(p_city), p_visibility, p_join_policy,
            case when p_visibility = 'public' then true else coalesce(p_is_listed, true) end,
            coalesce(btrim(p_description), ''), coalesce(btrim(p_rules), ''),
            upper(coalesce(p_country_code, 'CD')), uid)
    returning * into created;
  exception
    when unique_violation then
      raise exception 'club_name_taken' using errcode = 'P0001';
    when check_violation or not_null_violation then
      raise exception 'invalid_input' using errcode = 'P0001';
  end;

  insert into public.club_members (club_id, user_id, role)
  values (created.id, uid, 'owner');

  perform private.log_action('club.create', 'club', created.id,
    jsonb_build_object('visibility', created.visibility, 'join_policy', created.join_policy));

  select * into created from public.clubs where id = created.id;
  return created;
end;
$$;

-- Rejoindre un club : 'joined' (adhésion immédiate) ou 'requested'.
create or replace function public.join_club(p_club_id uuid, p_message text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  club public.clubs;
  invitation_id uuid;
begin
  select * into club from public.clubs where id = p_club_id for update;
  if not found or not private.can_view_club(p_club_id) then
    raise exception 'club_not_found' using errcode = 'P0001';
  end if;
  if club.suspended_at is not null then
    raise exception 'club_suspended' using errcode = 'P0001';
  end if;
  if private.is_club_member(p_club_id) then
    raise exception 'already_member' using errcode = 'P0001';
  end if;

  -- Une invitation en attente vaut acceptation.
  select i.id into invitation_id from public.club_invitations i
   where i.club_id = p_club_id and i.invitee_id = uid and i.status = 'pending';
  if invitation_id is not null then
    perform public.respond_to_club_invitation(invitation_id, true);
    return 'joined';
  end if;

  if club.join_policy = 'open' then
    insert into public.club_members (club_id, user_id) values (p_club_id, uid);
    perform private.log_action('club.join', 'club', p_club_id);
    return 'joined';
  elsif club.join_policy = 'approval' then
    if p_message is not null and char_length(p_message) > 500 then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
    insert into public.club_join_requests (club_id, user_id, message)
    values (p_club_id, uid, nullif(btrim(p_message), ''))
    on conflict (club_id, user_id) where status = 'pending' do nothing;
    return 'requested';
  else
    raise exception 'invitation_required' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.cancel_club_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  update public.club_join_requests
     set status = 'cancelled', decided_at = now(), decided_by = uid
   where id = p_request_id and user_id = uid and status = 'pending';
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.decide_club_join_request(p_request_id uuid, p_approve boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  req public.club_join_requests;
begin
  select * into req from public.club_join_requests
   where id = p_request_id and status = 'pending' for update;
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
  if not private.has_club_role(req.club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  update public.club_join_requests
     set status = case when p_approve then 'approved'::public.club_request_status
                       else 'rejected'::public.club_request_status end,
         decided_at = now(), decided_by = uid
   where id = req.id;

  if p_approve then
    insert into public.club_members (club_id, user_id)
    values (req.club_id, req.user_id)
    on conflict do nothing;
  end if;

  perform private.log_action(
    case when p_approve then 'club.request.approve' else 'club.request.reject' end,
    'club', req.club_id, jsonb_build_object('user_id', req.user_id));
end;
$$;

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

create or replace function public.respond_to_club_invitation(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  inv public.club_invitations;
begin
  select * into inv from public.club_invitations
   where id = p_invitation_id and invitee_id = uid and status = 'pending' for update;
  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;

  if p_accept and exists (select 1 from public.clubs
                           where id = inv.club_id and suspended_at is not null) then
    raise exception 'club_suspended' using errcode = 'P0001';
  end if;

  update public.club_invitations
     set status = case when p_accept then 'accepted'::public.club_invitation_status
                       else 'declined'::public.club_invitation_status end,
         responded_at = now()
   where id = inv.id;

  if p_accept then
    insert into public.club_members (club_id, user_id)
    values (inv.club_id, uid)
    on conflict do nothing;
    -- Une éventuelle demande d'adhésion devient sans objet.
    update public.club_join_requests
       set status = 'approved', decided_at = now(), decided_by = inv.invited_by
     where club_id = inv.club_id and user_id = uid and status = 'pending';
    perform private.log_action('club.invitation.accept', 'club', inv.club_id);
  end if;
end;
$$;

create or replace function public.revoke_club_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.club_invitations;
begin
  perform private.require_user();
  select * into inv from public.club_invitations
   where id = p_invitation_id and status = 'pending' for update;
  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;
  if not private.has_club_role(inv.club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.club_invitations set status = 'revoked', responded_at = now()
   where id = inv.id;
end;
$$;

create or replace function public.leave_club(p_club_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  my_role public.club_role := private.club_role_of(p_club_id, uid);
begin
  if my_role is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;
  if my_role = 'owner' then
    raise exception 'owner_cannot_leave' using errcode = 'P0001';
  end if;
  delete from public.club_members where club_id = p_club_id and user_id = uid;
  perform private.log_action('club.leave', 'club', p_club_id);
end;
$$;

-- Retrait d'un membre : il faut être au moins modérateur ET de rang
-- strictement supérieur à la personne retirée.
create or replace function public.remove_club_member(p_club_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  actor_rank integer := private.club_role_rank(private.club_role_of(p_club_id, uid));
  target_role public.club_role := private.club_role_of(p_club_id, p_user_id);
begin
  if target_role is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;
  if p_user_id = uid
     or actor_rank < private.club_role_rank('moderator')
     or actor_rank <= private.club_role_rank(target_role) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  delete from public.club_members where club_id = p_club_id and user_id = p_user_id;
  perform private.log_action('club.member.remove', 'club', p_club_id,
    jsonb_build_object('user_id', p_user_id, 'role', target_role));
end;
$$;

-- Changement de rôle : l'acteur doit être de rang strictement supérieur au
-- rôle actuel ET au nouveau rôle de la cible. La propriété se transfère
-- uniquement via transfer_club_ownership.
create or replace function public.set_club_member_role(
  p_club_id uuid, p_user_id uuid, p_role public.club_role
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  actor_rank integer := private.club_role_rank(private.club_role_of(p_club_id, uid));
  target_role public.club_role := private.club_role_of(p_club_id, p_user_id);
begin
  if p_role = 'owner' then
    raise exception 'use_transfer_ownership' using errcode = 'P0001';
  end if;
  if target_role is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;
  if p_user_id = uid
     or actor_rank <= private.club_role_rank(target_role)
     or actor_rank <= private.club_role_rank(p_role) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  update public.club_members set role = p_role
   where club_id = p_club_id and user_id = p_user_id;
  perform private.log_action('club.member.role', 'club', p_club_id,
    jsonb_build_object('user_id', p_user_id, 'from', target_role, 'to', p_role));
end;
$$;

create or replace function public.transfer_club_ownership(p_club_id uuid, p_new_owner_id uuid)
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
  if p_new_owner_id = uid or private.club_role_of(p_club_id, p_new_owner_id) is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;

  update public.club_members set role = 'admin'
   where club_id = p_club_id and user_id = uid;
  update public.club_members set role = 'owner'
   where club_id = p_club_id and user_id = p_new_owner_id;
  update public.clubs set owner_id = p_new_owner_id where id = p_club_id;

  perform private.log_action('club.ownership.transfer', 'club', p_club_id,
    jsonb_build_object('from', uid, 'to', p_new_owner_id));
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
  perform private.log_action('club.delete', 'club', p_club_id,
    (select jsonb_build_object('name', name) from public.clubs where id = p_club_id));
  delete from public.clubs where id = p_club_id;
end;
$$;

-- Demande du badge « Vérifié » : réservée au propriétaire.
create or replace function public.request_club_verification(p_club_id uuid, p_message text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created uuid;
begin
  if private.club_role_of(p_club_id, uid) is distinct from 'owner' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.clubs where id = p_club_id and verified_at is not null) then
    raise exception 'already_verified' using errcode = 'P0001';
  end if;
  if p_message is not null and char_length(p_message) > 1000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;

  begin
    insert into public.club_verification_requests (club_id, requested_by, message)
    values (p_club_id, uid, nullif(btrim(p_message), ''))
    returning id into created;
  exception when unique_violation then
    raise exception 'verification_pending' using errcode = 'P0001';
  end;

  perform private.log_action('club.verification.request', 'club', p_club_id);
  return created;
end;
$$;

-- Examen d'une demande : administration Rider Group uniquement.
create or replace function public.review_club_verification(
  p_request_id uuid, p_approve boolean, p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  req public.club_verification_requests;
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select * into req from public.club_verification_requests
   where id = p_request_id and status = 'pending' for update;
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;

  update public.club_verification_requests
     set status = case when p_approve then 'approved'::public.club_verification_status
                       else 'rejected'::public.club_verification_status end,
         review_note = nullif(btrim(p_note), ''),
         reviewed_by = uid,
         reviewed_at = now()
   where id = req.id;

  if p_approve then
    update public.clubs set verified_at = now() where id = req.club_id;
  end if;

  perform private.log_action(
    case when p_approve then 'club.verification.approve' else 'club.verification.reject' end,
    'club', req.club_id, jsonb_build_object('request_id', req.id));
end;
$$;

grant execute on function
  public.create_club(text, text, public.club_visibility, public.club_join_policy, boolean, text, text, text),
  public.join_club(uuid, text),
  public.cancel_club_join_request(uuid),
  public.decide_club_join_request(uuid, boolean),
  public.invite_to_club(uuid, uuid),
  public.respond_to_club_invitation(uuid, boolean),
  public.revoke_club_invitation(uuid),
  public.leave_club(uuid),
  public.remove_club_member(uuid, uuid),
  public.set_club_member_role(uuid, uuid, public.club_role),
  public.transfer_club_ownership(uuid, uuid),
  public.delete_club(uuid),
  public.request_club_verification(uuid, text),
  public.review_club_verification(uuid, boolean, text)
to authenticated;
