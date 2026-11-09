-- =============================================================================
-- Vérifications structurelles exécutées après application des migrations.
-- Chaque contrôle lève une exception en cas d'écart.
-- =============================================================================
do $$
declare
  offending text;
begin
  -- 1. Toute table de `public` doit avoir RLS activé.
  select string_agg(c.relname, ', ')
    into offending
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind in ('r', 'p')
     and not c.relrowsecurity;
  if offending is not null then
    raise exception 'RLS désactivé sur : %', offending;
  end if;

  -- 2. Le schéma private ne doit pas être accessible aux rôles clients.
  if has_schema_privilege('anon', 'private', 'USAGE')
     or has_schema_privilege('authenticated', 'private', 'USAGE') then
    raise exception 'Le schéma private est accessible aux clients';
  end if;

  -- 3. Les fonctions SECURITY DEFINER doivent fixer search_path.
  select string_agg(p.oid::regprocedure::text, ', ')
    into offending
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')
     and p.prosecdef
     and not exists (
       select 1 from unnest(coalesce(p.proconfig, '{}')) cfg
        where cfg like 'search_path=%'
     );
  if offending is not null then
    raise exception 'SECURITY DEFINER sans search_path : %', offending;
  end if;

  -- 4. PostGIS est disponible.
  if not exists (select 1 from pg_extension where extname = 'postgis') then
    raise exception 'Extension postgis absente';
  end if;

  raise notice 'Vérifications base de données : OK';
end;
$$;
