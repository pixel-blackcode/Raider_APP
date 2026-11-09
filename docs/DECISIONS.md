# Journal des décisions

## Décisions prises

| # | Décision | Justification |
| --- | --- | --- |
| D-01 | Flutter / Dart, Android + iOS, un seul code. | Imposé par le cahier des charges ; écosystème mature pour cartes et géolocalisation. |
| D-02 | Riverpod 3 pour l'état. | Injection testable (surcharges), pas de dépendance au `BuildContext`, adapté aux flux temps réel. |
| D-03 | GoRouter 18 avec `StatefulShellRoute`. | Navigation déclarative, liens profonds (e-mails de vérification, invitations), onglets à pile conservée. |
| D-04 | Supabase (Auth, PostgreSQL/PostGIS, Realtime, Storage). | RLS au niveau base = autorisation côté serveur ; PostGIS pour les requêtes géographiques. |
| D-05 | Configuration par `--dart-define-from-file`, fichiers `env/*.json` ignorés. | Aucun identifiant dans le dépôt ; un fichier par environnement. |
| D-06 | Clé *publishable* uniquement ; refus actif des clés secrètes côté client. | Défense contre une fuite de `service_role` par erreur de configuration. |
| D-07 | Schéma `private` + `EXECUTE` révoqué par défaut sur les fonctions de `public`. | Réduit la surface exposée par l'API REST. |
| D-08 | Contrôle automatique « RLS obligatoire » en CI. | Empêche qu'une nouvelle table soit exposée sans politique. |
| D-09 | Aucune donnée fictive dans l'interface : états vides explicites. | Exigence du cahier des charges ; évite de confondre maquette et fonctionnalité. |
| D-10 | Identifiant provisoire `com.ridergroup.rider_group`. | Nécessaire à l'initialisation ; **à confirmer** avant publication. |

## Décisions ouvertes (validation du propriétaire requise)

| # | Sujet | Mission | Options / remarques |
| --- | --- | --- | --- |
| O-01 | Identifiant d'application et nom de domaine définitifs. | avant 11 | Irréversible après publication sur les stores. |
| O-02 | Fournisseur de cartographie. | 05 | Mapbox, Google Maps Platform, MapLibre + tuiles OSM hébergées (ex. MapTiler, Stadia). Critères : coût par utilisateur actif, mode hors ligne, licence, qualité des données en RDC, consommation de données mobiles. Une comparaison chiffrée sera produite avant implémentation. |
| O-03 | Durée de conservation des positions GPS. | 05 | Proposition à valider : positions brutes supprimées 24 à 72 h après la fin de la balade ; seule la dernière position est conservée pendant la balade active. |
| O-04 | Région d'hébergement Supabase. | 02 | À choisir selon la latence mesurée depuis Kinshasa/Lubumbashi et les contraintes juridiques. |
| O-05 | Fournisseur SMTP pour les e-mails d'authentification. | 02 | Requis pour la production (limites du service intégré). |
| O-06 | Cadre juridique (protection des données en RDC et pays futurs). | 11 | Analyse juridique à mener ; aucune conformité n'est affirmée à ce stade. |
