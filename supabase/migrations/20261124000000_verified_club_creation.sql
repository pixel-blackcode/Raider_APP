-- =============================================================================
-- Rider Group — Migration 0019 : créer un club ou un regroupement exige d'être
-- un motard vérifié.
-- -----------------------------------------------------------------------------
-- D-62 : pour confirmer l'identité du fondateur et éviter qu'on usurpe le nom
-- d'un club existant, seuls les motards vérifiés (D-55) créent un club ou un
-- regroupement. Les clubs déjà créés ne changent pas. L'application envoie
-- les motards non vérifiés vers la demande de vérification de leur profil.
-- =============================================================================

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
  if not private.is_verified_rider(uid) then
    raise exception 'verification_required' using errcode = 'P0001';
  end if;
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

