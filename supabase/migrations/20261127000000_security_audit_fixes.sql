-- =============================================================================
-- Rider Group — Migration 0022 : corrections de l'audit de sécurité (19/11/2026)
-- -----------------------------------------------------------------------------
-- SEC-03 : les invitations de co-organisation en attente ou refusées ne sont
-- plus lisibles par tous les motards connectés : seulement les invitations
-- acceptées (publiques), les gestionnaires de l'événement et les responsables
-- du club invité.
-- SEC-04 (D-66) : limites anti-spam — 10 événements par club et par 24 h,
-- 20 invitations de co-organisation par heure et par motard.
-- =============================================================================

drop policy "event_coorganizers: visibles des motards connectés" on public.event_coorganizers;
create policy "event_coorganizers: acceptées, gestionnaires, club invité"
  on public.event_coorganizers for select to authenticated
  using (status = 'accepted'
         or private.can_manage_event(event_id)
         or private.has_club_role(club_id, 'admin'));

create or replace function public.create_event(
  p_club_id uuid,
  p_client_ref uuid,
  p_title text,
  p_starts_at timestamptz,
  p_place_name text,
  p_city text,
  p_description text default '',
  p_ends_at timestamptz default null,
  p_lat double precision default null,
  p_lng double precision default null
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
  if not private.has_club_role(p_club_id, 'admin') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if not private.is_verified_club(p_club_id) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  -- Anti-spam : 10 événements par club et par 24 h (D-66).
  if (select count(*) from public.events
       where club_id = p_club_id and created_at > now() - interval '24 hours') >= 10
     and not exists (select 1 from public.events
                      where club_id = p_club_id and client_ref = p_client_ref) then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  perform private.check_event_input(p_title, p_description, p_starts_at, p_ends_at,
                                    p_place_name, p_city, p_lat, p_lng);
  if p_starts_at < now() - interval '1 hour' then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  select id into created from public.events where club_id = p_club_id and client_ref = p_client_ref;
  if found then
    return created;
  end if;
  insert into public.events (club_id, created_by, client_ref, title, description, starts_at,
                             ends_at, place_name, city, lat, lng)
  values (p_club_id, uid, p_client_ref, btrim(p_title), coalesce(btrim(p_description), ''),
          p_starts_at, p_ends_at, btrim(p_place_name), btrim(p_city), p_lat, p_lng)
  returning id into created;
  perform private.log_action('event.create', 'event', created);
  return created;
end;
$$;

create or replace function public.invite_event_coorganizer(p_event_id uuid, p_club_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  ev public.events;
  created uuid;
  m record;
begin
  if not private.can_manage_event(p_event_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select * into ev from public.events where id = p_event_id;
  if ev.cancelled_at is not null or p_club_id = ev.club_id then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if not private.is_verified_club(p_club_id) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
  -- Anti-spam : 20 invitations par heure et par motard (D-66).
  if (select count(*) from public.event_coorganizers
       where invited_by = uid and created_at > now() - interval '1 hour') >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.event_coorganizers (event_id, club_id, invited_by)
  values (p_event_id, p_club_id, uid)
  on conflict (event_id, club_id) do update
    set status = 'pending', invited_by = excluded.invited_by, responded_at = null,
        created_at = now()
    where public.event_coorganizers.status = 'declined'
  returning id into created;
  if created is null then
    raise exception 'already_invited' using errcode = 'P0001';
  end if;
  for m in select user_id from public.club_members
            where club_id = p_club_id and role in ('owner', 'admin') loop
    perform private.notify(m.user_id, 'event_coorganizer_invitation', uid, p_club => p_club_id,
                           p_ref => created,
                           p_data => jsonb_build_object('event_id', ev.id, 'title', ev.title));
  end loop;
  return created;
end;
$$;
