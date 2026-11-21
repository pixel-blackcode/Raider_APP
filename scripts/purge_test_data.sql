-- =============================================================================
-- Rider Group — nettoyage des données de test AVANT LE LANCEMENT PUBLIC
-- -----------------------------------------------------------------------------
-- IRRÉVERSIBLE. À lancer une seule fois, juste avant l'ouverture aux vrais
-- motards, sur décision du propriétaire.
--
-- Garde : la structure (tables, fonctions, règles), les tâches planifiées,
--         les secrets (Vault), les comptes administrateurs Rider Group et leur
--         profil, ainsi que leurs jetons de notification.
-- Efface : tous les autres comptes et TOUT le contenu (clubs, balades,
--         publications, messages, annonces, boutiques, événements, garages,
--         mode solo, badges, défis, vérifications, signalements, retours,
--         notifications, journal de l'équipe).
--
-- Les fichiers (photos, factures, pièces) ne peuvent pas être supprimés en
-- SQL : vider ensuite chaque bucket dans Supabase → Storage (voir
-- docs/PUBLICATION.md, « Nettoyage avant lancement »).
-- =============================================================================
begin;

do $$
begin
  if not exists (select 1 from private.platform_admins) then
    raise exception 'Aucun administrateur : nettoyage annulé (vous perdriez l''accès à l''équipe).';
  end if;
end;
$$;

-- 1. Tout le contenu (y compris celui créé par les administrateurs en test).
truncate table
  public.rides, public.clubs, public.posts, public.conversations, public.listings,
  public.shops, public.events, public.motorcycles, public.solo_trips, public.solo_contacts,
  public.badge_awards, public.challenges, public.monthly_awards, public.account_suspensions,
  public.content_reports, public.app_feedback, public.notifications, public.user_blocks,
  public.rider_verification_requests, private.audit_logs
  cascade;

-- 2. Comptes de test (tout sauf les administrateurs) et ce qui leur reste lié.
delete from auth.users u
 where not exists (select 1 from private.platform_admins a where a.user_id = u.id);

-- 3. Les administrateurs repartent comme des motards non vérifiés et sans
--    statistiques (leurs badges seront recalculés à leurs premières actions).
update public.profiles set verified_at = null, verified_until = null;

-- Contrôle : il ne reste que les administrateurs.
select (select count(*) from public.profiles) as profils_restants,
       (select count(*) from private.platform_admins) as administrateurs;

commit;
