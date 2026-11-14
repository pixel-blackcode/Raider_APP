-- =============================================================================
-- Rider Group — Migration 0015 : regroupements et vérification des motards
-- -----------------------------------------------------------------------------
-- D-54 : un REGROUPEMENT rassemble des motards (de clubs différents ou sans
-- club). Il fonctionne comme un club (membres, rôles, publications, balades)
-- et peut être vérifié comme un club. Il est enregistré dans `clubs` avec
-- kind = 'regroupement' ; le type est fixé à la création.
-- D-55 : vérification des MOTARDS, sans aucun paiement dans l'application,
-- sur le modèle des clubs : nom réel, WhatsApp, pièce facultative ; examen,
-- date de fin, rappels neutres, retrait ; badge sur le profil.
-- =============================================================================

alter table public.clubs add column kind text not null default 'club'
  check (kind in ('club', 'regroupement'));
create index clubs_kind_idx on public.clubs (kind);

-- Création d'un regroupement : mêmes règles que create_club, type fixé.
create or replace function public.create_regroupement(
  p_name text,
  p_city text,
  p_visibility public.club_visibility,
  p_join_policy public.club_join_policy,
  p_is_listed boolean default true,
  p_description text default '',
  p_rules text default '',
  p_country_code text default 'CD'
)
returns public.clubs
language plpgsql
security definer
set search_path = ''
as $$
declare
  created public.clubs;
begin
  created := public.create_club(p_name, p_city, p_visibility, p_join_policy, p_is_listed,
                                p_description, p_rules, p_country_code);
  update public.clubs set kind = 'regroupement' where id = created.id
  returning * into created;
  perform private.log_action('regroupement.create', 'club', created.id, '{}'::jsonb);
  return created;
end;
$$;

-- -----------------------------------------------------------------------------
-- Vérification des motards
-- -----------------------------------------------------------------------------
alter table public.profiles
  add column verified_at timestamptz,
  add column verified_until timestamptz,
  add column verification_reminders smallint not null default 0;

create table public.rider_verification_requests (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  real_name       text not null check (char_length(btrim(real_name)) between 2 and 120),
  contact_phone   text not null check (contact_phone ~ '^\+?[0-9]{8,15}$'),
  message         text check (message is null or char_length(message) <= 1000),
  document_paths  text[] not null default '{}' check (cardinality(document_paths) <= 3),
  status          public.club_verification_status not null default 'pending',
  review_note     text check (review_note is null or char_length(review_note) <= 1000),
  reviewed_by     uuid references auth.users (id) on delete set null,
  reviewed_at     timestamptz,
  verified_until  timestamptz,
  created_at      timestamptz not null default now()
);
create unique index rider_verification_one_pending
  on public.rider_verification_requests (user_id) where status = 'pending';
create index rider_verification_requests_reviewed_by_idx
  on public.rider_verification_requests (reviewed_by);

alter table public.rider_verification_requests enable row level security;
revoke all on public.rider_verification_requests from anon, authenticated;
grant select on public.rider_verification_requests to authenticated;
create policy "rider_verification_requests: soi-même ou équipe"
  on public.rider_verification_requests for select to authenticated
  using (user_id = (select auth.uid()) or private.is_platform_admin());

-- Pièces des motards : verification-docs/riders/<user_id>/…
create policy "verification-docs: pièces du motard (lui-même et l'équipe)"
  on storage.objects for select to authenticated
  using (bucket_id = 'verification-docs'
         and (storage.foldername(name))[1] = 'riders'
         and ((storage.foldername(name))[2] = (select auth.uid())::text
              or private.is_platform_admin()));
create policy "verification-docs: dépôt de ses pièces"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'verification-docs'
              and (storage.foldername(name))[1] = 'riders'
              and (storage.foldername(name))[2] = (select auth.uid())::text);
create policy "verification-docs: suppression de ses pièces"
  on storage.objects for delete to authenticated
  using (bucket_id = 'verification-docs'
         and (storage.foldername(name))[1] = 'riders'
         and ((storage.foldername(name))[2] = (select auth.uid())::text
              or private.is_platform_admin()));

create or replace function public.request_rider_verification(
  p_real_name text,
  p_contact_phone text,
  p_message text default null,
  p_document_paths text[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created uuid;
  v_phone text := regexp_replace(coalesce(p_contact_phone, ''), '[\s.\-()]', '', 'g');
  v_docs text[] := coalesce(p_document_paths, '{}');
  i integer;
begin
  if exists (select 1 from public.profiles where id = uid and verified_at is not null
               and (verified_until is null or verified_until > now() + interval '30 days')) then
    raise exception 'already_verified' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_real_name, ''))) not between 2 and 120
     or v_phone !~ '^\+?[0-9]{8,15}$'
     or (p_message is not null and char_length(p_message) > 1000)
     or cardinality(v_docs) > 3 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  for i in 1 .. cardinality(v_docs) loop
    if v_docs[i] is null or v_docs[i] not like 'riders/' || uid::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'verification-docs' and o.name = v_docs[i]) then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
  end loop;
  begin
    insert into public.rider_verification_requests
      (user_id, real_name, contact_phone, message, document_paths)
    values (uid, btrim(p_real_name), v_phone, nullif(btrim(p_message), ''), v_docs)
    returning id into created;
  exception when unique_violation then
    raise exception 'verification_pending' using errcode = 'P0001';
  end;
  perform private.log_action('rider.verification.request', 'profile', uid);
  return created;
end;
$$;

create or replace function public.rider_verification_queue()
returns table (
  request_id uuid,
  user_id uuid,
  username text,
  display_name text,
  real_name text,
  contact_phone text,
  message text,
  document_paths text[],
  status public.club_verification_status,
  created_at timestamptz
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
    select r.id, r.user_id, p.username, p.display_name, r.real_name, r.contact_phone,
           r.message, r.document_paths, r.status, r.created_at
      from public.rider_verification_requests r
      join public.profiles p on p.id = r.user_id
     where r.status = 'pending'
     order by r.created_at desc
     limit 200;
end;
$$;

create or replace function public.review_rider_verification(
  p_request_id uuid,
  p_approve boolean,
  p_note text default null,
  p_valid_until timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  req public.rider_verification_requests;
  v_until timestamptz := coalesce(p_valid_until, now() + interval '1 year');
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_approve and v_until <= now() + interval '1 day' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select * into req from public.rider_verification_requests
   where id = p_request_id and status = 'pending' for update;
  if not found then
    raise exception 'request_not_found' using errcode = 'P0001';
  end if;
  update public.rider_verification_requests
     set status = case when p_approve then 'approved'::public.club_verification_status
                       else 'rejected'::public.club_verification_status end,
         review_note = nullif(btrim(p_note), ''), reviewed_by = uid, reviewed_at = now(),
         verified_until = case when p_approve then v_until end
   where id = req.id;
  if p_approve then
    update public.profiles
       set verified_at = coalesce(verified_at, now()), verified_until = v_until,
           verification_reminders = 0
     where id = req.user_id;
  end if;
  perform private.notify(req.user_id,
    case when p_approve then 'rider_verification_approved' else 'rider_verification_rejected' end,
    null, p_data => jsonb_build_object('until', v_until, 'note', nullif(btrim(p_note), '')));
  perform private.log_action(
    case when p_approve then 'rider.verification.approve' else 'rider.verification.reject' end,
    'profile', req.user_id, jsonb_build_object('request_id', req.id, 'until', v_until));
end;
$$;

create or replace function public.revoke_rider_verification(p_user_id uuid, p_note text default null)
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
  update public.profiles set verified_at = null, verified_until = null, verification_reminders = 0
   where id = p_user_id and verified_at is not null;
  if not found then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  perform private.log_action('rider.verification.revoke', 'profile', p_user_id,
    jsonb_build_object('note', p_note));
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
  'rider_verification_expiring', 'rider_verification_expired'));

create or replace function private.process_rider_verifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  p record;
  n integer := 0;
begin
  for p in
    select id, verified_until from public.profiles
     where verified_at is not null and verified_until is not null and verified_until > now()
       and ((verification_reminders = 0 and verified_until <= now() + interval '7 days')
            or (verification_reminders < 2 and verified_until <= now() + interval '1 day'))
  loop
    perform private.notify(p.id, 'rider_verification_expiring', null,
                           p_data => jsonb_build_object('until', p.verified_until));
    update public.profiles
       set verification_reminders = case when p.verified_until <= now() + interval '1 day' then 2 else 1 end
     where id = p.id;
    n := n + 1;
  end loop;
  for p in
    select id from public.profiles
     where verified_at is not null and verified_until is not null and verified_until <= now()
  loop
    update public.profiles set verified_at = null, verified_until = null, verification_reminders = 0
     where id = p.id;
    perform private.notify(p.id, 'rider_verification_expired', null);
    perform private.log_action('rider.verification.expire', 'profile', p.id);
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke all on function private.process_rider_verifications() from public, anon, authenticated;

grant execute on function
  public.create_regroupement(text, text, public.club_visibility, public.club_join_policy, boolean, text, text, text),
  public.request_rider_verification(text, text, text, text[]),
  public.rider_verification_queue(),
  public.review_rider_verification(uuid, boolean, text, timestamptz),
  public.revoke_rider_verification(uuid, text)
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-rider-verifications', '9 6 * * *',
                          'select private.process_rider_verifications()');
  end if;
end;
$$;
