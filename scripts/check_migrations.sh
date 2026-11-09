#!/usr/bin/env bash
# Applique les migrations Supabase sur une base PostgreSQL vierge, puis exécute
# les tests SQL (contrôles structurels + scénarios d'autorisation multi-utilisateurs).
#
# Usage : DATABASE_URL=postgres://user:pass@host:5432/db scripts/check_migrations.sh
#
# La base doit être VIERGE et disposer de PostGIS (paquet postgis, ou image
# Docker postgis/postgis en créant la base depuis template1).
# Le script recrée ce que fournit une instance Supabase : rôles anon /
# authenticated / service_role, schémas auth et extensions, auth.users,
# auth.uid(), et les privilèges par défaut accordés aux rôles API.
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL doit être défini}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -X)

echo "==> Préparation de l'environnement de type Supabase"
"${PSQL[@]}" <<'SQL'
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end;
$$;
-- Le rôle de connexion doit pouvoir endosser les rôles API (comme PostgREST).
grant anon, authenticated, service_role to current_user;

create schema if not exists extensions;
create schema if not exists auth;
grant usage on schema public, auth, extensions to anon, authenticated, service_role;

create table if not exists auth.users (
  id                  uuid primary key default gen_random_uuid(),
  email               text unique,
  raw_user_meta_data  jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now()
);

-- Équivalent de la fonction fournie par Supabase.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
    ), ''
  )::uuid;
$$;
grant execute on function auth.uid() to anon, authenticated, service_role;

-- Privilèges par défaut d'un projet Supabase sur le schéma public.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
SQL

shopt -s nullglob
migrations=("$ROOT"/supabase/migrations/*.sql)
if [ ${#migrations[@]} -eq 0 ]; then
  echo "Aucune migration trouvée." >&2
  exit 1
fi

for file in "${migrations[@]}"; do
  echo "==> Migration $(basename "$file")"
  "${PSQL[@]}" -f "$file"
done

for file in "$ROOT"/supabase/sql_tests/*.sql; do
  echo "==> Tests $(basename "$file")"
  # Résultats des SELECT masqués ; les NOTICE « ok - ... » restent affichés.
  "${PSQL[@]}" -o /dev/null -f "$file" 2>&1 | sed -E 's/^psql:[^ ]+ NOTICE:  /  /'
  [ "${PIPESTATUS[0]}" -eq 0 ] || exit 1
done

echo "Migrations et tests SQL : OK"
