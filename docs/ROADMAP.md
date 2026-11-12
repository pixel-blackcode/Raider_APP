# Feuille de route

Chaque mission est validée par le propriétaire avant le démarrage de la suivante.

| Mission | Périmètre | État |
| --- | --- | --- |
| 01 — Fondations | Projet Flutter, architecture modulaire, configuration d'environnement, navigation, thèmes, composants UI, fondations Supabase, CI, documentation, tests de base. | ✅ Livrée (compléments : CI corrigée, builds Android/iOS en CI) |
| 02 — Comptes et profils | Inscription, connexion, vérification e-mail, mot de passe oublié, sessions, profil, photo, confidentialité, suppression de compte. | ✅ Livrée — en attente de validation |
| 03 — Clubs | Création libre, public/privé, adhésion, rôles, vérification facultative. | ✅ Livrée — en attente de validation |
| 04 — Balades | Création, recherche, 3 modes d'adhésion, participants, machine à états, verrouillage. | ✅ Livrée — en attente de validation |
| 05 — GPS et mode Convoi | Carte, partage volontaire, temps réel, chef de convoi / serre-file, retardataires, confidentialité, rétention. | ✅ Livrée — en attente de validation (+ refonte visuelle : typographie Barlow Condensed, cartes de balade contrastées) |
| 06 — SOS | Alertes, notifications, accusés de réception, gestion des échecs de transmission. | ✅ Livrée — en attente de validation (notifications dans l'application ; push à venir, D-38) |
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

## Mission 02 — scénarios de recette

| # | Scénario | Vérification |
| --- | --- | --- |
| R02-1 | Créer un compte puis se reconnecter (critère 1). | Widget `auth_flow_test.dart` ; SQL : profil créé automatiquement, un seul par compte |
| R02-2 | Confirmation d'e-mail requise : message clair, retour à la connexion. | Widget |
| R02-3 | Mot de passe oublié : message identique que le compte existe ou non. | Widget `account_flow_test.dart` |
| R02-4 | Lien de réinitialisation : saisie du nouveau mot de passe imposée avant tout accès. | Widget + test unitaire de la garde |
| R02-5 | Session stockée chiffrée (Keychain / Keystore) ; secrets résiduels effacés après réinstallation. | Tests unitaires `media_and_storage_test.dart` |
| R02-6 | Photo de profil : envoi, remplacement (ancien fichier supprimé), retrait ; formats et tailles contrôlés. | Widget + unitaires ; SQL : dossier personnel uniquement |
| R02-7 | Confidentialité : profil non découvrable invisible hors des clubs communs ; invitations refusables. | SQL `04_media_privacy_account_test.sql` + widget |
| R02-8 | Suppression de compte : bloquée si propriétaire d'un club avec membres ; sinon profil, adhésions et clubs solitaires supprimés, opération journalisée. | SQL + widget |
| R02-9 | Liens e-mail ouverts dans l'application sur un vrai téléphone. | **À faire par le propriétaire** (projet Supabase + appareil) |

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

| R03-10 | Logo et couverture : ajout par owner/admin uniquement ; images d'un club masqué invisibles aux non-membres. | SQL `04_media_privacy_account_test.sql` + widget |

## Mission 06 — scénarios de recette

| # | Scénario (numéro du critère d'acceptation) | Preuve |
| --- | --- | --- |
| R06-1 | Panne, accident, demande d'aide, retard : choix en un geste, intention confirmée avant l'envoi. | widget `sos_flow_test.dart` |
| R06-2 | Une alerte non transmise n'est **jamais** présentée comme envoyée : « en cours d'envoi » puis « ALERTE NON TRANSMISE » avec « Réessayer » (12). | widget + tests du suivi d'envoi |
| R06-3 | Renvoi après coupure réseau sans doublon (identifiant d'alerte choisi par l'appareil). | SQL `08_sos_test.sql` + widget |
| R06-4 | Dernière position : GPS de l'appareil, sinon dernière position du mode Convoi, sinon « aucune position » ; l'alerte part même sans GPS. | SQL + widget |
| R06-5 | Destinataires : participants confirmés et organisateurs de la balade en cours uniquement ; non-participants, participants retirés et anonymes ne voient rien. | SQL |
| R06-6 | Bandeau rouge, son et vibration chez les destinataires (application ouverte) ; accusé « J'ai vu, je m'en occupe » visible par l'auteur. | widget + SQL |
| R06-7 | Clôture : l'auteur annule ou résout, un organisateur peut résoudre ; une alerte close ne se rouvre pas. | SQL + widget |
| R06-8 | Appel d'urgence (112 par défaut, modifiable dans les Paramètres), accessible même hors balade ; avertissement « pas un service de secours ». | widget |
| R06-9 | Limitation : 5 alertes / 10 min ; coordonnées effacées 72 h après la fin de la balade, historique conservé. | SQL |
| R06-10 | Essai réel à deux téléphones (TEST_GUIDE §6). | 📱 **À faire par le propriétaire** |

**Limites connues (assumées) :**
- **Pas encore de notification push** (D-38) : un destinataire dont l'application est fermée ne voit l'alerte qu'en la rouvrant. Le SOS ne remplace pas un appel.
- La moto du motard n'est pas encore jointe à l'alerte : le Garage arrive en Mission 09.
- Une alerte « non transmise » est conservée tant que l'application reste ouverte ; si l'application est fermée avant le renvoi, elle est perdue (aucun envoi fantôme).

## Mission 05 — scénarios de recette

| # | Scénario (numéro du critère d'acceptation) | Preuve |
| --- | --- | --- |
| R05-1 | Partage **volontaire** : rien n'est envoyé sans action explicite ; l'autorisation de localisation est demandée au premier partage. | widget `convoy_flow_test.dart` + SQL `07_convoy_test.sql` (`sharing_disabled`) |
| R05-2 | Un non-participant ne voit aucune position et ne peut pas en publier (8). | SQL + widget |
| R05-3 | Un participant retiré perd l'accès, son rôle et sa position immédiatement (9). | SQL (déclencheur `cleanup_convoy_on_leave`) |
| R05-4 | Arrêt du partage : la dernière position disparaît (10). | SQL + widget |
| R05-5 | Fin ou annulation de la balade : publication refusée, positions masquées, l'application arrête l'envoi. | SQL + widget |
| R05-6 | Purge des positions 72 h après la fin (D-35). | SQL (`purge_ride_positions`) ; planifiée toutes les heures par pg_cron |
| R05-7 | Chef de convoi / serre-file désignés par les gestionnaires, parmi les confirmés. | SQL + widget |
| R05-8 | Alertes : « peut-être séparé » (> 2 km du chef), « position ancienne » (> 3 min). Pas de fausse alerte si le chef lui-même est sans signal. | Tests unitaires `convoy_domain_test.dart` + widget |
| R05-9 | Économie batterie/données : envoi toutes les 30 s à l'arrêt, 15 s en ville, 8 s sur route ; filtre 15 m ; le serveur refuse plus d'un envoi par 3 s. | Tests unitaires + SQL (`too_frequent`) |
| R05-10 | Essai réel à deux téléphones (TEST_GUIDE §5). | 📱 **À faire par le propriétaire** |

**Limites connues (assumées) :**
- Suivi **application ouverte uniquement** : écran éteint ou application en arrière-plan, Android/iOS peuvent suspendre l'envoi. L'écran Convoi l'indique. Le suivi en arrière-plan demanderait un service de premier plan Android et une justification App Store (D-37).
- Aucun historique de trajet : seule la dernière position de chaque motard est conservée.
- Fond de carte OpenFreeMap (gratuit, sans clé, D-36) : pas d'engagement de disponibilité ; remplaçable par `MAP_STYLE_URL`.

## Mission 04 — scénarios de recette

| # | Scénario (critère du cahier des charges) | Vérification |
| --- | --- | --- |
| R04-1 | L'organisateur choisit libre, approbation ou invitation (6). | SQL `05_rides_test.sql` + widget `rides_flow_test.dart` |
| R04-2 | Une balade verrouillée bloque les nouvelles adhésions (7). Les demandes, les approbations et les invitations sont aussi refusées ; les participants déjà inscrits restent. | SQL + widget |
| R04-3 | Machine à états brouillon → publiée ⇄ verrouillée → en cours (verrouillable) → terminée / annulée. Les transitions interdites sont refusées. | SQL + 46 tests unitaires (table complète, miroir de la fonction SQL) |
| R04-4 | Balade en cours avec adhésions verrouillées, puis déverrouillées. | SQL + widget |
| R04-5 | Un participant retiré perd immédiatement l'accès (participants, balade privée) et ne peut pas revenir de lui-même. | SQL + widget |
| R04-6 | Brouillons invisibles ; balades privées invisibles sans invitation. | SQL |
| R04-7 | Balade de club réservée aux membres ou ouverte ; une invitation ne contourne pas la restriction aux membres. | SQL + widget |
| R04-8 | Capacité maximale respectée, quelle que soit la voie d'adhésion. | SQL + widget |
| R04-9 | Heure saisie et affichée dans le fuseau de la balade (Kinshasa UTC+1, Lubumbashi UTC+2). | Tests unitaires + widget |
| R04-10 | Recherche de proximité PostGIS, qui respecte la visibilité. | SQL (`rides_near`) |
| R04-11 | Visiteur anonyme : aucun accès ; opérations journalisées. | SQL |
| R04-12 | Essai sur un vrai projet Supabase et un vrai téléphone. | ✅ Supabase réel (`rider-group-dev`) : scénario de bout en bout réussi. 📱 Téléphone : **à faire par le propriétaire** avec l'APK de test (CONFIGURATION.md §3 bis) |

**Préparé mais pas encore exposé dans l'application :**
- **Coordonnées GPS du départ et de la destination :** les colonnes existent, le point PostGIS est calculé par le serveur et la fonction `rides_near` est testée. Leur saisie sur une carte arrivera avec la Mission 05, une fois le fournisseur de cartographie choisi (O-02).
- **Rôles de convoi** (chef de convoi, serre-file) : ✅ Mission 05. Discussion de balade : Mission 07.

