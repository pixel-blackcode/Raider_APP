-- =============================================================================
-- Outils de test SQL (schéma `tests`, uniquement dans les bases de test).
-- Permettent d'agir « en tant que » un utilisateur, comme le ferait PostgREST
-- avec un JWT Supabase : rôle `authenticated` + claim `sub`.
-- =============================================================================
create schema if not exists tests;
grant usage on schema tests to anon, authenticated;

-- Crée un utilisateur auth (le trigger crée son profil). Retourne son id.
create or replace function tests.create_user(p_name text, p_meta jsonb default null)
returns uuid
language sql
security definer
set search_path = ''
as $$
  insert into auth.users (email, raw_user_meta_data)
  values (p_name || '@test.local',
          coalesce(p_meta, jsonb_build_object('username', p_name, 'display_name', initcap(p_name))))
  returning id;
$$;

create or replace function tests.uid(p_name text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from auth.users where email = p_name || '@test.local';
$$;

-- Agit en tant qu'utilisateur connecté (jusqu'à la fin de la transaction).
create or replace function tests.authenticate_as(p_name text)
returns void
language plpgsql
as $$
declare
  user_id uuid := tests.uid(p_name);
begin
  if user_id is null then
    raise exception 'Utilisateur de test inconnu : %', p_name;
  end if;
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_id, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

-- Agit en tant que visiteur anonyme.
create or replace function tests.authenticate_as_anon()
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  perform set_config('role', 'anon', true);
end;
$$;

create or replace function tests.ok(p_condition boolean, p_description text)
returns void
language plpgsql
as $$
begin
  if p_condition is distinct from true then
    raise exception 'ÉCHEC : %', p_description;
  end if;
  raise notice 'ok - %', p_description;
end;
$$;

-- Vérifie qu'une instruction échoue avec un message contenant p_expected.
-- L'instruction s'exécute dans un sous-bloc : ses effets sont annulés.
create or replace function tests.throws(p_sql text, p_expected text, p_description text)
returns void
language plpgsql
as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm ilike '%' || p_expected || '%' then
      raise notice 'ok - % (erreur attendue : %)', p_description, sqlerrm;
      return;
    end if;
    raise exception 'ÉCHEC : % — erreur inattendue : %', p_description, sqlerrm;
  end;
  raise exception 'ÉCHEC : % — aucune erreur levée', p_description;
end;
$$;

-- Exécute une requête de comptage et renvoie le résultat.
create or replace function tests.count_of(p_sql text)
returns bigint
language plpgsql
as $$
declare
  result bigint;
begin
  execute 'select count(*) from (' || p_sql || ') q' into result;
  return result;
end;
$$;

-- Nombre de lignes affectées par une instruction de modification.
create or replace function tests.rows_affected(p_sql text)
returns bigint
language plpgsql
as $$
declare
  result bigint;
begin
  execute p_sql;
  get diagnostics result = row_count;
  return result;
end;
$$;

grant execute on all functions in schema tests to anon, authenticated;

create or replace function tests.club_id(p_name text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.clubs where name = p_name;
$$;
grant execute on function tests.club_id(text) to anon, authenticated;

-- Identifiant d'une demande d'adhésion, lu sans RLS (préparation des tests).
create or replace function tests.join_request_id(p_club_name text, p_user_name text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select r.id from public.club_join_requests r
   where r.club_id = tests.club_id(p_club_name) and r.user_id = tests.uid(p_user_name)
   order by r.created_at desc limit 1;
$$;
grant execute on function tests.join_request_id(text, text) to anon, authenticated;
