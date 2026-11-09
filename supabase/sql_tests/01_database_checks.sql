-- =============================================================================
-- Contrôles structurels exécutés après application des migrations.
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

  -- 2. Le schéma private n'est jamais accessible au rôle anonyme...
  if has_schema_privilege('anon', 'private', 'USAGE') then
    raise exception 'Le schéma private est accessible au rôle anon';
  end if;

  -- 3. ...et aucune de ses tables n'est lisible ou modifiable par les clients.
  select string_agg(c.relname, ', ')
    into offending
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private'
     and c.relkind in ('r', 'p', 'v', 'm')
     and (has_table_privilege('authenticated', c.oid, 'SELECT, INSERT, UPDATE, DELETE')
          or has_table_privilege('anon', c.oid, 'SELECT, INSERT, UPDATE, DELETE'));
  if offending is not null then
    raise exception 'Tables privées accessibles aux clients : %', offending;
  end if;

  -- 4. Les fonctions SECURITY DEFINER doivent fixer search_path.
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

  -- 5. Aucune fonction de l'application n'est exécutable par le rôle anonyme.
  select string_agg(p.oid::regprocedure::text, ', ')
    into offending
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')
     and has_function_privilege('anon', p.oid, 'EXECUTE')
     and not exists (select 1 from pg_depend d
                      where d.objid = p.oid and d.deptype = 'e');
  if offending is not null then
    raise exception 'Fonctions exécutables par anon : %', offending;
  end if;

  -- 6. Aucune table de public n'accorde de droits au rôle anonyme.
  select string_agg(c.relname, ', ')
    into offending
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind in ('r', 'p', 'v', 'm')
     and has_table_privilege('anon', c.oid, 'SELECT, INSERT, UPDATE, DELETE');
  if offending is not null then
    raise exception 'Tables accessibles au rôle anon : %', offending;
  end if;

  -- 7. PostGIS est disponible.
  if not exists (select 1 from pg_extension where extname = 'postgis') then
    raise exception 'Extension postgis absente';
  end if;

  raise notice 'Contrôles structurels : OK';
end;
$$;
