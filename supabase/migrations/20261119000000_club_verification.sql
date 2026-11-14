-- =============================================================================
-- Rider Group — Migration 0014 : vérification des clubs, sans paiement (D-53)
-- -----------------------------------------------------------------------------
-- Règles des magasins d'applications (Apple 3.1.1, Google Play) : AUCUN prix,
-- montant ni paiement dans l'application. La vérification est une demande
-- examinée par l'équipe Rider Group :
--   1. le propriétaire ou un administrateur du club remplit le formulaire
--      (nom officiel, responsable, numéro WhatsApp, documents facultatifs) ;
--   2. l'équipe examine la demande dans son onglet réservé et contacte le
--      club EN DEHORS de l'application ;
--   3. l'équipe valide (ou refuse) ; le badge apparaît avec une date de fin ;
--   4. rappels neutres 7 jours avant et la veille ; retrait automatique à
--      l'échéance ; l'équipe peut retirer un badge à tout moment.
-- Toutes les actions de l'équipe sont journalisées.
-- =============================================================================

alter table public.clubs add column verified_until timestamptz;

alter table public.club_verification_requests
  add column official_name text check (official_name is null or char_length(btrim(official_name)) between 2 and 120),
  add column contact_name  text check (contact_name is null or char_length(btrim(contact_name)) between 2 and 120),
  add column contact_phone text check (contact_phone is null or contact_phone ~ '^\+?[0-9]{8,15}$'),
  add column document_paths text[] not null default '{}' check (cardinality(document_paths) <= 5),
  add column verified_until timestamptz;

-- Rappels déjà envoyés pour la période en cours (7 jours, 1 jour).
alter table public.clubs add column verification_reminders smallint not null default 0;

-- Documents justificatifs : privés, visibles par le club et l'équipe seulement.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('verification-docs', 'verification-docs', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "verification-docs: club (owner/admin) et équipe Rider Group"
  on storage.objects for select to authenticated
  using (bucket_id = 'verification-docs'
         and (private.is_platform_admin()
              or private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin')));
create policy "verification-docs: dépôt par le club (owner/admin)"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'verification-docs'
              and private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin'));
create policy "verification-docs: suppression par le club ou l'équipe"
  on storage.objects for delete to authenticated
  using (bucket_id = 'verification-docs'
         and (private.is_platform_admin()
              or private.has_club_role(private.try_uuid((storage.foldername(name))[1]), 'admin')));

-- Les demandes sont désormais faites par le propriétaire OU un administrateur.
drop policy "club_verification_requests: owner/admin du club ou plateforme"
  on public.club_verification_requests;
create policy "club_verification_requests: owner/admin du club ou plateforme"
  on public.club_verification_requests for select to authenticated
  using (private.has_club_role(club_id, 'admin') or private.is_platform_admin());

-- Le club est-il vérifié en ce moment ?
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

-- -----------------------------------------------------------------------------
-- Demande
-- -----------------------------------------------------------------------------
drop function public.request_club_verification(uuid, text);

create or replace function public.request_club_verification(
  p_club_id uuid,
  p_official_name text,
  p_contact_name text,
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
  if not private.has_club_role(p_club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  -- Déjà vérifié : nouvelle demande permise seulement dans les 30 derniers
  -- jours (renouvellement).
  if exists (select 1 from public.clubs where id = p_club_id and verified_at is not null
               and (verified_until is null or verified_until > now() + interval '30 days')) then
    raise exception 'already_verified' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_official_name, ''))) not between 2 and 120
     or char_length(btrim(coalesce(p_contact_name, ''))) not between 2 and 120
     or v_phone !~ '^\+?[0-9]{8,15}$'
     or (p_message is not null and char_length(p_message) > 1000)
     or cardinality(v_docs) > 5 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  for i in 1 .. cardinality(v_docs) loop
    if v_docs[i] is null or v_docs[i] not like p_club_id::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'verification-docs' and o.name = v_docs[i]) then
      raise exception 'invalid_input' using errcode = 'P0001';
    end if;
  end loop;

  begin
    insert into public.club_verification_requests
      (club_id, requested_by, message, official_name, contact_name, contact_phone, document_paths)
    values (p_club_id, uid, nullif(btrim(p_message), ''), btrim(p_official_name),
            btrim(p_contact_name), v_phone, v_docs)
    returning id into created;
  exception when unique_violation then
    raise exception 'verification_pending' using errcode = 'P0001';
  end;

  perform private.log_action('club.verification.request', 'club', p_club_id);
  return created;
end;
$$;

-- -----------------------------------------------------------------------------
-- Examen par l'équipe Rider Group
-- -----------------------------------------------------------------------------
create or replace function public.am_i_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_platform_admin();
$$;

-- File d'examen : demandes en attente (et récentes), avec les coordonnées.
create or replace function public.verification_queue(p_include_closed boolean default false)
returns table (
  request_id uuid,
  club_id uuid,
  club_name text,
  club_city text,
  requested_by uuid,
  requester_name text,
  official_name text,
  contact_name text,
  contact_phone text,
  message text,
  document_paths text[],
  status public.club_verification_status,
  created_at timestamptz,
  club_verified_until timestamptz
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
    select r.id, r.club_id, c.name, c.city, r.requested_by, p.display_name,
           r.official_name, r.contact_name, r.contact_phone, r.message, r.document_paths,
           r.status, r.created_at, c.verified_until
      from public.club_verification_requests r
      join public.clubs c on c.id = r.club_id
      left join public.profiles p on p.id = r.requested_by
     where p_include_closed or r.status = 'pending'
     order by (r.status = 'pending') desc, r.created_at desc
     limit 200;
end;
$$;

drop function public.review_club_verification(uuid, boolean, text);

-- Valide (badge jusqu'à p_valid_until, 1 an par défaut) ou refuse.
create or replace function public.review_club_verification(
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
  req public.club_verification_requests;
  v_until timestamptz := coalesce(p_valid_until, now() + interval '1 year');
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_approve and v_until <= now() + interval '1 day' then
    raise exception 'invalid_input' using errcode = 'P0001';
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
         reviewed_at = now(),
         verified_until = case when p_approve then v_until end
   where id = req.id;

  if p_approve then
    update public.clubs
       set verified_at = coalesce(verified_at, now()), verified_until = v_until,
           verification_reminders = 0
     where id = req.club_id;
  end if;

  perform private.notify(req.requested_by,
    case when p_approve then 'club_verification_approved' else 'club_verification_rejected' end,
    null, p_club => req.club_id,
    p_data => jsonb_build_object('until', v_until, 'note', nullif(btrim(p_note), '')));
  perform private.log_action(
    case when p_approve then 'club.verification.approve' else 'club.verification.reject' end,
    'club', req.club_id, jsonb_build_object('request_id', req.id, 'until', v_until));
end;
$$;

-- Retrait du badge par l'équipe (litige, erreur…), journalisé.
create or replace function public.revoke_club_verification(p_club_id uuid, p_note text default null)
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
  update public.clubs set verified_at = null, verified_until = null, verification_reminders = 0
   where id = p_club_id and verified_at is not null;
  if not found then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  perform private.log_action('club.verification.revoke', 'club', p_club_id,
    jsonb_build_object('note', p_note));
end;
$$;

-- -----------------------------------------------------------------------------
-- Rappels neutres et expiration (tâche quotidienne)
-- -----------------------------------------------------------------------------
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in (
  'ride_join_request', 'ride_joined', 'ride_request_approved',
  'ride_request_rejected', 'ride_removed', 'ride_invitation',
  'ride_locked', 'ride_started', 'ride_finished', 'ride_cancelled',
  'club_join_request', 'club_request_approved', 'club_request_rejected',
  'club_invitation', 'post_comment', 'post_reaction',
  'club_verification_approved', 'club_verification_rejected',
  'club_verification_expiring', 'club_verification_expired'));

create or replace function private.process_club_verifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  c record;
  admin uuid;
  n integer := 0;
begin
  -- Rappels : 7 jours avant (1er rappel), puis la veille (2e rappel).
  for c in
    select id, verified_until, verification_reminders from public.clubs
     where verified_at is not null and verified_until is not null and verified_until > now()
       and ((verification_reminders = 0 and verified_until <= now() + interval '7 days')
            or (verification_reminders < 2 and verified_until <= now() + interval '1 day'))
  loop
    for admin in select user_id from public.club_members
                  where club_id = c.id and role in ('owner', 'admin') loop
      perform private.notify(admin, 'club_verification_expiring', null, p_club => c.id,
                             p_data => jsonb_build_object('until', c.verified_until));
    end loop;
    update public.clubs
       set verification_reminders = case when c.verified_until <= now() + interval '1 day' then 2 else 1 end
     where id = c.id;
    n := n + 1;
  end loop;

  -- Échéance : le badge disparaît.
  for c in
    select id from public.clubs
     where verified_at is not null and verified_until is not null and verified_until <= now()
  loop
    update public.clubs set verified_at = null, verified_until = null, verification_reminders = 0
     where id = c.id;
    for admin in select user_id from public.club_members
                  where club_id = c.id and role in ('owner', 'admin') loop
      perform private.notify(admin, 'club_verification_expired', null, p_club => c.id);
    end loop;
    perform private.log_action('club.verification.expire', 'club', c.id);
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke all on function
  private.process_club_verifications(),
  private.club_is_verified(uuid)
from public, anon, authenticated;

grant execute on function
  public.request_club_verification(uuid, text, text, text, text, text[]),
  public.review_club_verification(uuid, boolean, text, timestamptz),
  public.revoke_club_verification(uuid, text),
  public.verification_queue(boolean),
  public.am_i_platform_admin()
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-club-verifications', '7 6 * * *',
                          'select private.process_club_verifications()');
  end if;
end;
$$;
