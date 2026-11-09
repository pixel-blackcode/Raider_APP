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
| D-11 | Écritures sensibles via fonctions SQL (`create_club`, `join_club`…), tables en lecture seule côté client. | Vérification atomique des permissions, journalisation, aucune logique d'autorisation côté client. |
| D-12 | Rôles de club hiérarchiques (owner 4 > admin 3 > modérateur 2 > membre 1) ; on n'agit que sur un rang strictement inférieur. | Règle simple, sans escalade de privilèges. |
| D-13 | Seul le propriétaire modifie visibilité / référencement / mode d'adhésion ; les administrateurs modifient le contenu. | Les conditions d'adhésion sont une décision du propriétaire (cahier des charges §5.2). |
| D-14 | Club public = toujours référencé (libre ou approbation) ; privé = approbation ou invitation, référencé ou masqué. | Interprétation de §5.2–5.3 ; à confirmer par le propriétaire. |
| D-15 | Noms de club uniques (insensibles à la casse). | Limite l'usurpation ; le badge vérifié reste la garantie d'authenticité. |
| D-16 | Limite de 3 créations de club par 24 h et par utilisateur. | Limitation des abus ; valeur ajustable. |
| D-17 | Administrateurs plateforme dans `private.platform_admins`, désignés par SQL. | En attendant le tableau de bord (Mission 10). |
| D-18 | Socle de la Mission 02 réalisé avec la Mission 03. | Les clubs ne peuvent pas fonctionner sans comptes. |

## Décisions ouvertes (validation du propriétaire requise)

| # | Sujet | Mission | Options / remarques |
| --- | --- | --- | --- |
| O-01 | Identifiant d'application et nom de domaine définitifs. | avant 11 | Irréversible après publication sur les stores. |
| O-02 | Fournisseur de cartographie. | 05 | Mapbox, Google Maps Platform, MapLibre + tuiles OSM hébergées (ex. MapTiler, Stadia). Critères : coût par utilisateur actif, mode hors ligne, licence, qualité des données en RDC, consommation de données mobiles. Une comparaison chiffrée sera produite avant implémentation. |
| O-03 | Durée de conservation des positions GPS. | 05 | Proposition à valider : positions brutes supprimées 24 à 72 h après la fin de la balade ; seule la dernière position est conservée pendant la balade active. |
| O-04 | Région d'hébergement Supabase. | 02 | À choisir selon la latence mesurée depuis Kinshasa/Lubumbashi et les contraintes juridiques. |
| O-05 | Fournisseur SMTP pour les e-mails d'authentification. | 02 | Requis pour la production (limites du service intégré). |
| O-07 | Une vitrine de club privé référencé affiche nom, ville, description et règlement. | 03 | Alternative : masquer le règlement aux non-membres (nécessite une table séparée). |
| O-08 | Un propriétaire ne peut pas supprimer son compte tant qu'il possède un club (`on delete restrict`). | 02 | Transfert ou suppression du club à prévoir dans le parcours de suppression de compte. |
| O-06 | Cadre juridique (protection des données en RDC et pays futurs). | 11 | Analyse juridique à mener ; aucune conformité n'est affirmée à ce stade. |
