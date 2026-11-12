# Partie 10 — MVP et feuille de route

> **Statut : proposée, non validée.** Chaque mission se termine par un rapport dans `docs/missions/` et attend une
> validation écrite avant la suivante.

## Périmètre

| Domaine | MVP (V1) | V2 et au-delà |
| --- | --- | --- |
| Découverte | Fiches, catégories, communes, quartiers, photos, horaires, contacts, menus | Nouvelles catégories, autres villes |
| Recherche | Nom, filtres, « ouvert maintenant », proximité, tri, carte, itinéraire externe | Carte téléchargeable hors ligne |
| Contenus | Consultation des événements et promotions, expiration automatique | Notifications, rappels d'événement |
| Hors ligne | Catalogue local, file d'attente pour favoris, lieux visités, avis, signalements | Synchronisation en arrière-plan |
| Comptes | E-mail + mot de passe, Google, profil, suppression de compte | Téléphone (SMS), Apple avec iOS |
| Engagement | Favoris, lieux visités, notes et avis, signalements | Avis avec preuve de visite |
| Espace gérant | Revendication, édition de fiche, photos, brouillons et publication d'événements et promotions, statistiques de base | Collaborateurs avancés, campagnes |
| Administration | Fiches, import, vérifications, modération, référentiels, taux, paiements manuels, audit | Tableau de bord des revenus détaillé |
| Abonnements | Forfaits, droits, essai, **paiement validé manuellement**, factures | Paiement en ligne par agrégateur, renouvellement automatique |
| Campagnes | Schéma prêt, étiquette « Sponsorisé » et « Coups de cœur » éditoriaux | Achat en libre-service, emplacements, statistiques de campagne |
| Plateformes | Android | iOS |
| Billetterie | — | Étude ultérieure |

**Fonctions commerciales dès le MVP** : forfaits et droits appliqués côté serveur, essai gratuit, validation
manuelle des paiements, factures, statistiques de base. Sans elles, impossible de tester la volonté de payer.
**Reportées** : paiement en ligne, campagnes en libre-service, renouvellement automatique.

## Missions

### Mission 01 — Fondations

1. **Objectif** : squelette d'application propre, testable et compilable, sans fonctionnalité métier.
2. **Fonctionnalités** : structure du monorepo ; projet Flutter (saveurs `dev` et `prod`, configuration par
   `--dart-define-from-file`, Riverpod, go_router, analyse statique stricte) ; internationalisation ARB en
   français ; `DESIGN.md` (skill `impeccable`), thème et composants de base (bouton, carte de lieu, puce de filtre,
   bandeau hors ligne, état vide, état d'erreur, squelette) ; coquille à cinq onglets (Accueil, Explorer, Carte,
   Quoi de neuf, Profil) avec état « aucune donnée synchronisée » ; `supabase init` sans migration métier ; CI
   (analyse, tests, APK debug).
3. **Dépendances** : décisions D-01 (dépôt) et D-02 (stack) ; Flutter installable dans l'environnement.
4. **Tables** : aucune.
5. **Livrables** : `apps/mobile/`, `supabase/`, `tools/`, `DESIGN.md`, workflow CI, rapport de mission.
6. **Tests** : tests de widgets de la coquille, du thème et de chaque composant ; test de démarrage sans réseau.
7. **Critères d'acceptation** : `flutter analyze` sans erreur ; tests verts ; APK debug généré ; application
   ouvrable hors ligne sans écran blanc ; aucun texte d'interface codé en dur ; `DESIGN.md` validé par vous.
8. **Risques** : outils absents de l'environnement ; cohabitation avec Rider Group ; test en mode avion impossible
   sans appareil.
9. **Validation** : vous installez l'APK, l'ouvrez en mode avion et validez `DESIGN.md`.

### Mission 02 — Schéma de base et sécurité

1. **Objectif** : base de données du catalogue, sécurisée et testée.
2. **Fonctionnalités** : référentiels, établissements, horaires, contacts, médias ; fonctions d'aide RLS ;
   déclencheurs `updated_at` et d'audit ; fonction `is_open_at` ; données de démonstration.
3. **Dépendances** : Mission 01 ; projet Supabase de développement créé par vous.
4. **Tables** : `profiles`, `platform_roles`, `cities`, `communes`, `neighborhoods`, `categories`,
   `establishments`, `opening_hours`, `opening_hour_exceptions`, `establishment_contacts`, `media_assets`,
   `establishment_photos`, `currencies`, `exchange_rates`, `app_settings`, `audit_logs`.
5. **Livrables** : migrations, `seed.sql` (24 communes, catégories initiales, fiches fictives), tests SQL.
6. **Tests** : RLS (lecture anonyme des seules fiches publiées, écriture refusée) ; contraintes ; horaires
   traversant minuit ; fermeture exceptionnelle ; présence de RLS sur toutes les tables.
7. **Critères d'acceptation** : migrations rejouables de zéro ; tests SQL verts en local et en CI ; aucun
   avertissement de sécurité des conseillers Supabase.
8. **Risques** : exactitude de la liste des quartiers (source à fournir ou à valider par vous).
9. **Validation** : revue du schéma et des données de référence.

### Mission 03 — Catalogue hors ligne

1. **Objectif** : parcourir les fiches réelles, y compris sans réseau.
2. **Fonctionnalités** : base Drift ; moteur de synchronisation (`sync_pull`, curseurs, lots, reprises) ; état du
   réseau à trois valeurs ; Accueil, Explorer, fiche d'établissement ; images en variantes et cache disque.
3. **Dépendances** : Mission 02.
4. **Tables** : celles de la Mission 02 ; `menus`, `menu_items`.
5. **Livrables** : fonctionnalités `home`, `explore`, `establishment` ; module `core/sync` ; pipeline d'images
   (Edge Function).
6. **Tests** : unitaires du moteur (curseur, reprise, retrait de ligne) ; widgets des états ; intégration avec
   Supabase local ; coupure pendant un lot.
7. **Critères d'acceptation** : après une synchronisation, les fiches consultées restent lisibles en mode avion ;
   première ouverture hors ligne sans écran blanc ; budgets de données de la Partie 11 respectés.
8. **Risques** : volume réel du catalogue ; mémoire sur appareils modestes.
9. **Validation** : essai sur téléphone d'entrée de gamme, réseau bridé.

### Mission 04 — Recherche, filtres, proximité, carte

1. **Objectif** : trouver un lieu rapidement.
2. **Fonctionnalités** : recherche par nom tolérante ; filtres ; tri ; « ouvert maintenant » ; proximité avec
   permission facultative ; carte MapLibre ; itinéraire externe.
3. **Dépendances** : Mission 03 ; décision D-04 (carte).
4. **Tables** : aucune nouvelle ; index et RPC `search_establishments`.
5. **Livrables** : fonctionnalités `search`, `map` ; règle « ouvert maintenant » en Dart et en SQL avec jeu de cas
   commun.
6. **Tests** : horaires traversant minuit, exceptions ; refus de localisation ; recherche hors ligne ; carte sans
   réseau.
7. **Critères d'acceptation** : recherche locale sous 300 ms sur l'appareil de référence ; refus de localisation
   sans blocage ; attribution OpenStreetMap visible.
8. **Risques** : qualité des tuiles à Kinshasa ; poids du moteur de carte dans l'APK.
9. **Validation** : essai sur dix lieux réels de communes différentes.

### Mission 05 — Événements et promotions (consultation)

1. **Objectif** : rubriques « Quoi de neuf à Kin ? » et « Bons plans à Kinshasa ».
2. **Fonctionnalités** : listes, détails, filtres par date ; expiration automatique ; prix avec devise d'origine et
   estimation.
3. **Dépendances** : Mission 03.
4. **Tables** : `events`, `promotions`, `content_media`, `editorial_picks`.
5. **Livrables** : fonctionnalités `whats_new`, `deals` ; composant `PriceText`.
6. **Tests** : promotion expirée et événement terminé, y compris hors ligne et avec horloge simulée ; conversion
   et arrondi.
7. **Critères d'acceptation** : aucun contenu expiré présenté comme actif ; mention « estimation » sur tout prix
   converti.
8. **Risques** : horloge du téléphone déréglée (parade : écart mesuré avec l'heure du serveur à chaque
   synchronisation).
9. **Validation** : recette avec contenus de démonstration.

### Mission 06 — Comptes, favoris, lieux visités

1. **Objectif** : authentification fiable et fonctions personnelles.
2. **Fonctionnalités** : e-mail + mot de passe, Google, réinitialisation, profil, suppression de compte ; favoris
   et lieux visités avec file d'attente hors ligne.
3. **Dépendances** : Mission 03 ; configuration Google OAuth et envoi d'e-mails par vous.
4. **Tables** : `favorites`, `visited_places` ; file `outbox` locale.
5. **Livrables** : fonctionnalités `auth`, `profile`, `favorites`.
6. **Tests** : connexion, déconnexion, session expirée ; favori hors ligne puis synchronisé ; RLS « chacun ses
   favoris ».
7. **Critères d'acceptation** : aucune donnée personnelle locale après déconnexion ; opérations rejouées sans
   doublon.
8. **Risques** : empreintes de signature Android ; délivrabilité des e-mails.
9. **Validation** : parcours complet sur téléphone avec un vrai compte Google.

### Mission 07 — Back-office : administration minimale

1. **Objectif** : alimenter et administrer le catalogue sans passer par SQL.
2. **Fonctionnalités** : connexion avec double authentification ; gestion des fiches, photos, référentiels, taux ;
   import par fichier ; détection de doublons ; journal d'audit.
3. **Dépendances** : Mission 02 ; décision D-03 (back-office).
4. **Tables** : aucune nouvelle.
5. **Livrables** : `apps/backoffice/` ; outil d'import dans `tools/` ; déploiement de l'environnement de
   développement.
6. **Tests** : composants ; accès refusé à un non-administrateur par appel direct à l'API ; import avec lignes
   invalides.
7. **Critères d'acceptation** : une fiche créée dans le back-office apparaît dans l'application après
   synchronisation ; toute action sensible est dans l'audit.
8. **Risques** : qualité des données importées ; skill `frontend-design` absente de la session.
9. **Validation** : vous créez dix fiches réelles.

### Mission 08 — Espace gérant

1. **Objectif** : un professionnel gère sa fiche et publie.
2. **Fonctionnalités** : revendication et vérification ; édition de fiche, horaires, menus, photos ; brouillons,
   programmation et publication d'événements et de promotions ; collaborateurs.
3. **Dépendances** : Missions 05 et 07.
4. **Tables** : `business_accounts`, `establishment_members`, `establishment_claims`, `claim_documents`,
   `location_corrections`.
5. **Livrables** : écrans de l'espace professionnel ; fonctions `approve_claim`, `publish_event`,
   `publish_promotion`.
6. **Tests** : isolation entre deux établissements ; revendication refusée ; envoi d'un fichier non conforme.
7. **Critères d'acceptation** : un gérant ne peut ni lire ni modifier les brouillons d'un autre établissement, même
   par appel direct.
8. **Risques** : charge de vérification manuelle.
9. **Validation** : parcours complet avec un établissement pilote.

### Mission 09 — Avis, notes, signalements, modération

1. **Objectif** : contributions des utilisateurs, maîtrisées.
2. **Fonctionnalités** : note et avis ; signalement ; file de modération ; limites anti-abus.
3. **Dépendances** : Missions 06 et 07.
4. **Tables** : `reviews`, `visit_proofs` (structure seule), `reports`, `moderation_actions`, `rate_limits`.
5. **Livrables** : écrans mobile et back-office ; déclencheur de note moyenne.
6. **Tests** : un avis par personne et par lieu ; avis d'un membre sur son propre lieu refusé ; note moyenne
   exacte ; avis masqué absent de l'application.
7. **Critères d'acceptation** : aucun avis affiché « vérifié » ; un contenu masqué disparaît après
   synchronisation.
8. **Risques** : charge de modération.
9. **Validation** : recette des cas d'abus.

### Mission 10 — Abonnements, paiements manuels, statistiques

1. **Objectif** : première monétisation réelle.
2. **Fonctionnalités** : forfaits et droits ; essai ; souscription ; déclaration et validation manuelle d'un
   paiement ; factures PDF ; expiration ; collecte et affichage des statistiques.
3. **Dépendances** : Mission 08 ; prix des forfaits fournis par vous.
4. **Tables** : `plans`, `plan_prices`, `plan_entitlements`, `subscriptions`, `invoices`, `invoice_lines`,
   `payments`, `payment_transactions`, `interaction_events`, `interaction_daily_stats`.
5. **Livrables** : écrans Abonnement, Paiements et factures, Statistiques, Transactions ; tâches `pg_cron`.
6. **Tests** : publication refusée à un compte gratuit ; expiration d'un abonnement ; paiement signalé deux fois ;
   paiement refusé ; dédoublonnage des clics.
7. **Critères d'acceptation** : aucun droit payant sans paiement validé côté serveur ; données conservées après
   expiration.
8. **Risques** : mentions légales des factures.
9. **Validation** : cycle complet avec un établissement pilote et un paiement réel.

### Mission 11 — Durcissement et mise en production

1. **Objectif** : MVP prêt pour une diffusion restreinte.
2. **Fonctionnalités** : campagne de tests de la Partie 11 ; performance ; accessibilité ; environnement de
   production ; sauvegarde et exercice de restauration ; publication en test fermé sur Google Play.
3. **Dépendances** : toutes les missions précédentes ; comptes et documents légaux fournis par vous.
4. **Tables** : aucune.
5. **Livrables** : rapport de recette, procédure d'exploitation, version de test fermée.
6. **Tests** : sécurité, performance sur appareils de référence, restauration.
7. **Critères d'acceptation** : critères de sortie de la Partie 11.
8. **Risques** : délais de validation des stores.
9. **Validation** : décision de lancement par vous.

## Après le MVP (ordre proposé)

| Mission | Contenu | Condition préalable |
| --- | --- | --- |
| 12 | Paiement en ligne par agrégateur, renouvellement | Contrat signé, paiement de test réussi |
| 13 | Campagnes sponsorisées en libre-service | Mission 12 ; tarifs définis |
| 14 | Notifications avec consentement | Compte Firebase |
| 15 | Version iOS | Compte Apple Developer, Mac |
| 16 | Connexion par téléphone | Fournisseur SMS validé vers +243 |
| 17 | Preuve de visite, avis vérifiés | Décision sur la méthode |
| 18 | Carte hors ligne de Kinshasa | Mesure du poids du fichier |
