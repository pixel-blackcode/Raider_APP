# Feuille de route

Chaque mission est validée par le propriétaire avant le démarrage de la suivante.

| Mission | Périmètre | État |
| --- | --- | --- |
| 01 — Fondations | Projet Flutter, architecture modulaire, configuration d'environnement, navigation, thèmes, composants UI, fondations Supabase, CI, documentation, tests de base. | ✅ Livrée — en attente de validation |
| 02 — Comptes et profils | Inscription, connexion, vérification e-mail, mot de passe oublié, sessions, profil, photo, confidentialité, suppression de compte. | À venir |
| 03 — Clubs | Création libre, public/privé, adhésion, rôles, vérification facultative. | À venir |
| 04 — Balades | Création, recherche, 3 modes d'adhésion, participants, machine à états, verrouillage. | À venir |
| 05 — GPS et mode Convoi | Carte, partage volontaire, temps réel, chef de convoi / serre-file, retardataires, confidentialité, rétention. | À venir |
| 06 — SOS | Alertes, notifications, accusés de réception, gestion des échecs de transmission. | À venir |
| 07 — Communauté | Publications, photos, commentaires, messagerie, modération. | À venir |
| 08 — Marketplace | Annonces sans paiement, recherche, favoris, contact vendeur. | À venir |
| 09 — Garage | Motos, historique d'entretien, rappels. | À venir |
| 10 — Gamification et administration | Badges, défis, tableau de bord web, modération. | À venir |
| 11 — Stabilisation | Tests d'intégration, sécurité, performance, accessibilité, builds, déploiement. | À venir |

## Mission 01 — scénarios de recette

| # | Scénario | Vérification |
| --- | --- | --- |
| R01-1 | L'application démarre sans configuration et affiche « Serveur non configuré ». | Test widget `navigation_test.dart` |
| R01-2 | La barre affiche Accueil, Balades, Clubs, Messages, Profil et chaque onglet s'ouvre. | Test widget |
| R01-3 | Garage et Marketplace sont accessibles depuis l'accueil, avec retour. | Test widget |
| R01-4 | La Marketplace indique qu'aucun paiement n'est intégré. | Test widget |
| R01-5 | Le thème clair / sombre / système se change et persiste. | Tests widget + unitaires |
| R01-6 | Une clé `service_role` ou `sb_secret_` est refusée ; HTTP refusé hors local. | Tests unitaires `app_config_test.dart` |
| R01-7 | Un échec d'initialisation Supabase est affiché comme tel, sans plantage. | Tests unitaires + widget |
| R01-8 | Les migrations s'appliquent (et se ré-appliquent) sur une base vierge ; une table sans RLS fait échouer les contrôles. | `scripts/check_migrations.sh` |
| R01-9 | Lancement manuel sur appareil Android et iOS. | **À faire par le propriétaire** (non exécutable dans l'environnement cloud) |
