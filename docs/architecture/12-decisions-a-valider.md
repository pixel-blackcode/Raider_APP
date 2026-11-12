# Partie 12 — Décisions à valider

Seules les décisions qui demandent votre intervention figurent ici. Une réponse du type
« D-01 : A, D-02 : oui… » suffit. Chaque décision validée deviendra un ADR.

## D-01 — Où vit le code de Kin Guide ? (bloquant pour la Mission 01)

Le dépôt actuel (`pixel-blackcode/Raider_APP`) contient déjà l'application Rider Group à sa racine.

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. Nouveau dépôt dédié** (par exemple `kin-guide`) | Structure propre, CI indépendante, aucun risque de casser Rider Group, historique lisible | Vous devez créer le dépôt et y donner accès à la session |
| B. Sous-dossier `kin-guide/` dans ce dépôt | Rien à créer | Deux produits dans un dépôt, deux CI à faire cohabiter, `CLAUDE.md` et `docs/` ambigus |
| C. Branche orpheline dans ce dépôt (sans le code Rider Group) | Rien à créer, arborescence propre | Deux historiques sans rapport dans un dépôt ; source de confusion |

**Recommandation : A.** Conséquence : je déplace la documentation Kin Guide dans le nouveau dépôt et la Mission 01
y démarre. Avec B, la structure de la Partie 4 est préfixée par `kin-guide/` et la CI est filtrée par chemin.

## D-02 — Stack générale

Flutter + Riverpod + go_router + Drift ; Supabase (PostgreSQL, PostGIS, Auth, Storage, Edge Functions) ;
synchronisation maison. Détail et comparaisons en [Partie 3](03-stack.md).

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. Stack proposée** | Peu de composants, pas de serveur à administrer, coût de départ faible | Dépendance à Supabase ; module de synchronisation à écrire |
| B. Supabase + PowerSync | Synchronisation prête à l'emploi | Service supplémentaire, règles d'accès à dupliquer |
| C. Serveur applicatif dédié | Liberté totale | Hébergement et exploitation à assurer |

**Recommandation : A.** Conséquence : la Mission 01 fige ces choix dans le squelette.

## D-03 — Technologie du back-office

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. Application web React + TypeScript, une seule pour gérants et administrateurs** | Légère sur réseau lent, écosystème riche pour tableaux et formulaires, hébergement statique | Un second langage dans le projet |
| B. Flutter Web | Un seul langage | Première page lourde, tableaux moins confortables |
| C. Deux applications séparées (gérants, administrateurs) | Cloisonnement visible | Double travail ; la sécurité repose de toute façon sur RLS |

**Recommandation : A.** Conséquence : `apps/backoffice/` créé à la Mission 07 ; rien à faire avant.

## D-04 — Cartographie

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. MapLibre + OpenStreetMap** | Pas de licence par utilisateur, cache hors ligne autorisé, pas de carte bancaire obligatoire | Couverture inégale en périphérie ; hébergeur de tuiles à choisir |
| B. Google Maps | Meilleure couverture probable | Compte de facturation, mise en cache restreinte, dépendance |
| C. Mapbox | Bon rendu, hors ligne encadré | Coût au-delà d'un seuil, dépendance |

**Recommandation : A.** Conséquence : choix d'un hébergeur de tuiles à la Mission 04, après vérification de ses
conditions commerciales.

## D-05 — Paiements au MVP

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. Validation manuelle par un administrateur ; agrégateur en V2** | Lancement sans contrat, aucun frais de prestataire, conforme au cahier des charges (phase pilote) | Travail quotidien de rapprochement ; pas de renouvellement automatique |
| B. Intégrer un agrégateur dès le MVP | Parcours automatisé | Contrat et tests à obtenir avant ; aucun prestataire vérifié à ce jour |

**Recommandation : A.** Conséquence : vous (ou un collaborateur) validez les paiements dans le back-office. En
parallèle, vous demandez leurs conditions à deux agrégateurs (voir [Partie 8](08-monetisation.md)).

## D-06 — Méthodes de connexion au MVP

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. E-mail + mot de passe et Google ; téléphone en V2** | Fiable, sans coût par connexion | Une partie du public n'utilise pas l'e-mail |
| B. Téléphone (SMS) dès le MVP | Plus naturel localement | Livraison des SMS vers +243 non vérifiée ; coût par SMS |

**Recommandation : A**, avec un test réel d'un fournisseur SMS pendant le MVP pour décider de la suite.

## D-07 — Forfaits, droits et prix

La grille de droits de la [Partie 8](08-monetisation.md) est une proposition. À fournir avant la Mission 10 :
nombre de forfaits payants (un seul « Pro » ou « Pro » et « Premium »), prix mensuels et annuels en USD et en CDF,
durée de l'essai, délai de grâce.

**Recommandation : un seul forfait payant au lancement**, plus simple à expliquer et à vendre ; le second s'ajoute
par simple saisie de données.

## D-08 — Modération des contenus professionnels

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| **A. Publication immédiate pour les établissements vérifiés, revue préalable pour les autres** | Réactivité, charge de modération limitée | Un abus d'un compte vérifié est corrigé après coup |
| B. Revue préalable de tout | Contrôle total | Délai pour chaque publication, charge quotidienne |
| C. Publication immédiate pour tous | Aucune charge | Risque d'abus |

**Recommandation : A.**

## Actions qui vous reviennent (aucune n'est faisable par moi)

| Action | Nécessaire pour | Bloquant |
| --- | --- | --- |
| Créer le dépôt dédié et y donner accès (si D-01 = A) | Mission 01 | Oui |
| Rendre Flutter et la CLI Supabase disponibles dans l'environnement, ou m'autoriser à les installer | Mission 01 | Oui pour l'analyse, les tests et le build |
| Installer la skill `frontend-design` ou désigner un remplacement | Mission 07 | Non |
| Créer le projet Supabase de développement et vérifier que le MCP ne pointe que vers lui | Mission 02 | Oui |
| Fournir ou valider la liste des communes et quartiers, et les catégories initiales | Mission 02 | Oui |
| Fournir un téléphone Android d'entrée de gamme pour les essais | Mission 03 | Oui pour la recette |
| Créer le projet Google Cloud et les identifiants OAuth | Mission 06 | Oui |
| Nom de domaine et service d'envoi d'e-mails | Mission 06 | Oui |
| Contenu initial : fiches réelles, photos avec droit d'utilisation | Mission 07 | Oui pour le lancement |
| Prix des forfaits ; numéros Mobile Money d'encaissement | Mission 10 | Oui |
| Conseil d'un comptable (factures) et d'un juriste (données personnelles, conditions d'utilisation) | Missions 10 et 11 | Oui avant production |
| Compte Google Play, clé de signature, fiche de l'application | Mission 11 | Oui |
| Projet Supabase de production sur un plan payant | Mission 11 | Oui |
| Demander leurs conditions à deux agrégateurs de paiement ; tester un fournisseur SMS | V2 | Non |
| Compte Apple Developer et Mac | Version iOS | Non |
