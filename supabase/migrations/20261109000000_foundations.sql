-- =============================================================================
-- Rider Group — Migration 0001 : fondations
-- -----------------------------------------------------------------------------
-- Aucune table métier ici : les tables (profiles, clubs, rides...) arrivent
-- avec leurs missions respectives, chacune avec ses politiques RLS.
--
-- Règles appliquées à toutes les migrations suivantes :
--   * Toute table du schéma `public` DOIT activer Row Level Security
--     (vérifié automatiquement par supabase/tests/database_checks.sql).
--   * Les fonctions internes vivent dans le schéma `private`, non exposé
--     par l'API REST de Supabase.
--   * Les fonctions SECURITY DEFINER fixent `search_path = ''`.
-- =============================================================================

-- Requêtes géospatiales (balades, convoi, annonces à proximité).
create extension if not exists postgis with schema extensions;

-- Schéma interne, jamais exposé aux clients.
create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon, authenticated;

-- Les nouvelles fonctions de `public` ne sont pas exécutables par défaut :
-- chaque RPC exposée devra être explicitement autorisée (GRANT EXECUTE).
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated;

-- Horodatage automatique des mises à jour (trigger générique).
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function private.set_updated_at() is
  'Trigger BEFORE UPDATE : met à jour la colonne updated_at.';
