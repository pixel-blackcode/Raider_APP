# Partie 3 — Stack technique recommandée

> Les versions exactes seront figées à la Mission 01 (dernières versions stables au moment de l'installation).
> Aucun tarif ci-dessous n'a été confirmé sur une page officielle : tout chiffre est **à vérifier** avant engagement.

## Synthèse

| Besoin | Choix recommandé | Alternatives écartées | Raison du choix |
| --- | --- | --- | --- |
| Mobile | **Flutter / Dart** | React Native, natif Kotlin + Swift | Une base de code Android + iOS, bon rendu sur appareils modestes, demandé par le cahier des charges |
| Gestion d'état | **Riverpod** | Bloc, Provider | Injection de dépendances et état dans un seul outil, testable sans widget, peu de code répétitif |
| Routage | **go_router** (`StatefulShellRoute`) | auto_route, Navigator 2 brut | Maintenu par l'équipe Flutter, liens profonds, barre inférieure avec état conservé par onglet |
| Base locale | **Drift (SQLite)** | Isar, Hive, ObjectBox | Vrai SQL (filtres, tris, jointures hors ligne), migrations typées, requêtes observables |
| Synchronisation | **Module maison au-dessus de Drift** | PowerSync, Brick | Voir comparaison ci-dessous |
| Backend | **Supabase** | Firebase, serveur NestJS/Django + PostgreSQL géré | PostgreSQL + PostGIS + Auth + Storage + fonctions sans serveur à administrer |
| Base de données | **PostgreSQL + PostGIS** | — | Exigé ; requêtes de proximité et intégrité relationnelle |
| Logique serveur | **Fonctions SQL (RPC) + Edge Functions (TypeScript)** | Serveur applicatif dédié | Règles près des données ; Edge Functions pour paiements, images, tâches privilégiées |
| Tâches planifiées | **pg_cron** | Planificateur externe | Expiration des abonnements, agrégats statistiques, purge |
| Médias | **Supabase Storage + variantes pré-générées (WebP)** | Transformation d'images à la volée, Cloudinary, Cloudflare Images | Pas de dépendance à une option payante ; variantes servies par CDN avec cache long |
| Authentification | **Supabase Auth** : e-mail + mot de passe, Google ; téléphone plus tard | Firebase Auth | Intégré aux politiques RLS |
| Back-office | **Application web React + TypeScript (Vite), statique** | Flutter Web, Next.js | Voir comparaison ci-dessous ; décision D-03 |
| Cartographie | **MapLibre + données OpenStreetMap** | Google Maps, Mapbox | Voir comparaison ci-dessous ; décision D-04 |
| Itinéraire | **Délégué à l'application de navigation du téléphone** | API d'itinéraires payante | Zéro coût, zéro clé |
| CI | **GitHub Actions** | — | Analyse, tests, build APK debug |
| Suivi des erreurs | **Sentry** (suggestion, V1.1) | Firebase Crashlytics | Indépendant de Firebase ; à activer après le MVP |

## Comparaison : synchronisation hors ligne

| Critère | Module maison sur Drift | PowerSync | Brick |
| --- | --- | --- | --- |
| Adapté à un catalogue public surtout en lecture | Oui, cas simple | Oui, mais surdimensionné | Partiel : ne met en cache que ce qui a déjà été lu |
| Filtres et tris locaux en SQL | Oui | Oui | Limité |
| Service supplémentaire à payer ou héberger | Non | Oui | Non |
| Respect des règles RLS | Oui (passe par l'API Supabase) | Règles à redéfinir dans le service de synchronisation | Oui |
| Effort de développement | Moyen, maîtrisé | Faible au départ, dépendance forte | Faible au départ |

**Choix : module maison.** Les données publiques ne sont jamais modifiées depuis le mobile ; seules trois opérations
partent du téléphone hors ligne (favori, lieu visité, avis). Le problème difficile de la synchronisation — les
conflits d'écriture — est donc presque absent. Un service tiers ajouterait un coût et une dépendance pour un besoin
simple. Sources consultées : billet Supabase sur Brick, billet PowerSync, retours de la communauté Flutter (liens en bas).

## Comparaison : back-office

| Critère | React + TypeScript (Vite) | Flutter Web | Next.js |
| --- | --- | --- | --- |
| Tableaux, formulaires, filtres denses | Excellent (écosystème mûr) | Moyen | Excellent |
| Poids de la première page sur réseau lent | Faible | Lourd (plusieurs Mo) | Faible |
| Hébergement | Fichiers statiques, gratuit ou presque | Fichiers statiques | Serveur ou plateforme dédiée |
| Partage de code avec le mobile | Non | Oui (modèles) | Non |
| Secrets côté serveur | Aucun : tout passe par RLS et Edge Functions | Idem | Possibles, mais un serveur de plus à sécuriser |

**Choix : React + TypeScript, application statique.** Le gérant ouvre son espace depuis un téléphone sur réseau
lent : le poids de Flutter Web est un handicap réel. Le partage de code avec le mobile est limité aux modèles, que la
génération de types Supabase couvre déjà. Une seule application sert gérants et administrateurs, les menus dépendant
du rôle ; la sécurité repose sur RLS, pas sur l'interface. La bibliothèque de composants sera choisie avec la skill
`pick-ui-library` à la mission concernée.

## Comparaison : cartographie

| Critère | MapLibre + OpenStreetMap | Google Maps | Mapbox |
| --- | --- | --- | --- |
| Coût d'affichage | Pas de licence ; hébergement des tuiles ou offre d'un hébergeur | Compte de facturation avec carte bancaire | Gratuit jusqu'à un seuil d'utilisateurs actifs |
| Cartes hors ligne | Libre (licence ODbL, attribution obligatoire) | Mise en cache des tuiles restreinte par les conditions | Autorisé, avec limites |
| Qualité à Kinshasa | Bonne au centre, lacunes signalées en périphérie | Probablement la meilleure | Proche d'OSM |
| Dépendance | Faible | Forte | Forte |

**Choix : MapLibre + OpenStreetMap**, source de tuiles interchangeable. Au lancement : hébergeur de tuiles avec offre
compatible usage commercial ; ensuite, fichier PMTiles de Kinshasa hébergé par nous si le trafic le justifie.
Ce tableau s'appuie sur la comparaison déjà réalisée dans ce dépôt pour un autre projet (`docs/MAP_PROVIDERS.md`,
novembre 2026), dont les tarifs n'avaient pas pu être confirmés sur les pages officielles : **à revérifier**.

## Coûts et dépendances externes

| Poste | Lancement | Point à vérifier |
| --- | --- | --- |
| Supabase | Palier gratuit en développement ; plan payant en production | Prix du plan, pause des projets gratuits inactifs, durée de rétention des sauvegardes, coût de la bande passante |
| Tuiles de carte | Offre d'un hébergeur ou auto-hébergement | Conditions d'usage commercial de l'offre retenue |
| Hébergement du back-office | Hébergement statique | Conditions du palier gratuit |
| Google Play | Frais d'inscription développeur | Montant et délai de validation du compte |
| Apple Developer | Abonnement annuel (nécessaire pour iOS) | Montant ; un Mac est requis pour compiler |
| SMS (V2) | Aucun au MVP | Fournisseur délivrant réellement vers +243, prix par SMS |
| Paiement (V2) | Aucun au MVP (validation manuelle) | Agrégateur : contrat, frais, devises, délais de reversement |
| Nom de domaine + e-mail d'envoi | Nécessaires pour les e-mails d'authentification et les liens | Fournisseur SMTP et délivrabilité |

## Sources consultées (novembre 2026)

- Supabase, offline-first avec Brick : <https://supabase.com/blog/offline-first-flutter-apps>
- PowerSync et Supabase : <https://powersync.com/blog/bringing-offline-first-to-supabase>
- Supabase, connexion par téléphone : <https://supabase.com/docs/guides/auth/phone-login>
- Supabase, hook d'envoi de SMS : <https://supabase.com/blog/third-party-auth-mfa-phone-send-hooks>
- Tarifs Supabase (articles tiers, chiffres contradictoires — se référer à <https://supabase.com/pricing>) :
  <https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/>,
  <https://makerkit.dev/blog/saas/supabase-pricing>
- Paiement en RDC : voir [08-monetisation.md](08-monetisation.md).
