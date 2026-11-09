#!/usr/bin/env bash
# Applique les migrations Supabase sur une base PostgreSQL vierge puis exécute
# les vérifications structurelles (RLS, schéma private, search_path...).
#
# Usage : DATABASE_URL=postgres://user:pass@host:5432/db scripts/check_migrations.sh
#
# La base doit disposer de PostGIS (image Docker postgis/postgis:16-3.4 par ex.).
# Le script recrée les rôles et le schéma « extensions » fournis par Supabase.
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL doit être défini}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -X)

echo "==> Préparation de l'environnement de type Supabase"
"${PSQL[@]}" <<'SQL'
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end;
$$;
create schema if not exists extensions;
create schema if not exists auth;
grant usage on schema public to anon, authenticated, service_role;
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

echo "==> Ré-application (idempotence)"
for file in "${migrations[@]}"; do
  "${PSQL[@]}" -f "$file"
done

echo "==> Vérifications"
for file in "$ROOT"/supabase/tests/*.sql; do
  "${PSQL[@]}" -f "$file"
done

echo "Migrations et vérifications : OK"
