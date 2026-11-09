# Rider Group

Application mobile communautaire pour motards — République démocratique du Congo, Android et iOS.

Rider Group réunit motards indépendants et clubs : profils, garage virtuel, clubs publics et privés, balades organisées, mode Convoi avec GPS en temps réel, SOS, réseau social, marketplace sans paiement et suivi d'entretien.

> **État actuel : Missions 01, 02 et 03 livrées (en attente de validation).**
> - Comptes : inscription, connexion, mot de passe oublié, liens e-mail ouverts dans l'application, session chiffrée, profil et photo, confidentialité, suppression de compte.
> - Clubs : création libre, publics et privés, logo et couverture, adhésion libre, sur approbation ou sur invitation, rôles, demande de badge vérifié.
>
> Toutes les règles d'accès sont appliquées côté serveur et testées. Les balades, le GPS, le SOS, etc. viendront avec les missions suivantes. Voir [docs/ROADMAP.md](docs/ROADMAP.md).

## Stack

| Couche | Choix |
| --- | --- |
| Mobile | Flutter 3.47 / Dart 3.13 — Android et iOS |
| État | Riverpod 3 |
| Navigation | GoRouter 18 (`StatefulShellRoute`, 5 onglets) |
| Backend | Supabase (Auth, PostgreSQL + PostGIS, Realtime, Storage) |
| i18n | `flutter_localizations` + ARB — français par défaut |
| CI | GitHub Actions (format, analyse, tests, migrations SQL) |

## Démarrage rapide

Prérequis : Flutter **3.47.x stable** (`flutter --version`), Android Studio et/ou Xcode.

```sh
flutter pub get

# Sans backend : l'application fonctionne et signale « Serveur non configuré ».
flutter run

# Avec Supabase : copier puis compléter le fichier d'environnement (ignoré par Git).
cp env/example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

La configuration complète (Supabase, environnements, notifications à venir) est décrite dans [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## Vérifications

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# Migrations + tests SQL d'autorisation (PostgreSQL + PostGIS vierge)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/rider scripts/check_migrations.sh
```

## Structure

```
lib/
  main.dart / bootstrap.dart   Démarrage, configuration, injection des dépendances
  app/                         Widget racine, routeur, barre de navigation
  core/                        Config, backend, thème, préférences, composants UI
  features/<module>/           Un dossier par fonctionnalité (data / domain / presentation)
  l10n/                        Traductions ARB (+ code généré)
supabase/migrations/           Migrations SQL versionnées
supabase/sql_tests/            Contrôles structurels et scénarios d'autorisation multi-utilisateurs
docs/                          Architecture, configuration, décisions, feuille de route
```

Détails : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · Décisions : [docs/DECISIONS.md](docs/DECISIONS.md) · Sécurité : [docs/SECURITY.md](docs/SECURITY.md)

## Sécurité

- Aucun secret dans le dépôt. Seule la clé Supabase *publishable* est fournie au client ; l'application **refuse** une clé `service_role` / `sb_secret_`.
- Toute table exposée doit activer Row Level Security (contrôlé en CI).
- Les autorisations sont vérifiées côté serveur : RLS en lecture, fonctions SQL pour les écritures sensibles, journal d'audit. Voir [docs/SECURITY.md](docs/SECURITY.md).
