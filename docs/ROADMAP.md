# Feuille de route

Chaque mission est validée par le propriétaire avant le démarrage de la suivante.

| Mission | Périmètre | État |
| --- | --- | --- |
| 01 — Fondations | Projet Flutter, architecture modulaire, configuration d'environnement, navigation, thèmes, composants UI, fondations Supabase, CI, documentation, tests de base. | ✅ Livrée (compléments : CI corrigée, builds Android/iOS en CI) |
| 02 — Comptes et profils | Inscription, connexion, vérification e-mail, mot de passe oublié, sessions, profil, photo, confidentialité, suppression de compte. | 🟡 Partielle — socle livré avec la Mission 03 (voir ci-dessous) |
| 03 — Clubs | Création libre, public/privé, adhésion, rôles, vérification facultative. | ✅ Livrée — en attente de validation (hors logos/couvertures) |
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
| R01-8 | Les migrations s'appliquent sur une base vierge ; une table sans RLS fait échouer les contrôles. | `scripts/check_migrations.sh` |
| R01-9 | Lancement manuel sur appareil Android et iOS. | **À faire par le propriétaire** (non exécutable dans l'environnement cloud) |

## Mission 02 — socle livré avec la Mission 03

Les clubs exigent des comptes (propriétaire, membres, permissions côté serveur). Le minimum nécessaire a donc été réalisé :

| Livré | Restant pour clore la Mission 02 |
| --- | --- |
| Inscription e-mail / mot de passe (avec suggestion de pseudonyme) | Mot de passe oublié (nécessite les liens profonds) |
| Connexion, déconnexion, session persistante, garde de navigation | Liens profonds de confirmation d'e-mail vers l'application |
| Gestion du cas « confirmation d'e-mail requise » | Photo de profil (Supabase Storage) |
| Table `profiles` + RLS + création automatique | Préférences de confidentialité |
| Consultation et modification du profil | Suppression de compte et des données associées |
| | Stockage chiffré de la session (Keychain / Keystore) |

## Mission 03 — scénarios de recette

| # | Scénario (critère du cahier des charges) | Vérification |
| --- | --- | --- |
| R03-1 | Un utilisateur crée un club sans approbation préalable (3). | SQL `03_clubs_test.sql` + widget `clubs_flow_test.dart` |
| R03-2 | Un motard appartient à plusieurs clubs (2). | SQL + widget |
| R03-3 | Un club ne peut pas s'attribuer le badge vérifié (4). | SQL (écriture `verified_at` refusée, auto-approbation refusée, badge accordé uniquement par l'administration) |
| R03-4 | Les informations privées restent protégées (5) : club masqué invisible, membres d'un club privé cachés, adhésion par identifiant refusée. | SQL + widget |
| R03-5 | Permissions owner / admin / modérateur / membre appliquées côté serveur (15). | SQL (20 assertions) + widget |
| R03-6 | Adhésion libre, sur approbation, sur invitation. | SQL + widget |
| R03-7 | Visiteur anonyme : aucun accès aux profils, clubs ni fonctions. | SQL |
| R03-8 | Opérations sensibles journalisées. | SQL |
| R03-9 | Essai réel sur un projet Supabase + appareil. | **À faire par le propriétaire** (aucun projet Supabase ni appareil disponible dans l'environnement cloud) |

Non livré dans la Mission 03 : **téléversement du logo et de l'image de couverture**. Les colonnes `logo_path` et `cover_path` existent, mais le bucket Storage, ses politiques et le sélecteur d'image restent à faire. Une initiale tient lieu de logo en attendant.
