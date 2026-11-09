# Rider Group

Application mobile communautaire pour motards — République démocratique du Congo, Android et iOS.

Rider Group réunit motards indépendants et clubs : profils, garage virtuel, clubs publics et privés, balades organisées, mode Convoi avec GPS en temps réel, SOS, réseau social, marketplace sans paiement et suivi d'entretien.

> **État actuel : Mission 01 — Fondations techniques.**
> L'application démarre, navigue entre ses écrans structurels et affiche honnêtement l'état du serveur. Aucune fonctionnalité métier (comptes, clubs, balades…) n'est encore livrée. Voir [docs/ROADMAP.md](docs/ROADMAP.md).

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

# Migrations SQL sur un PostgreSQL + PostGIS vierge
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
supabase/tests/                Contrôles structurels (RLS obligatoire, etc.)
docs/                          Architecture, configuration, décisions, feuille de route
```

Détails : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · Décisions : [docs/DECISIONS.md](docs/DECISIONS.md)

## Sécurité

- Aucun secret dans le dépôt. Seule la clé Supabase *publishable* est fournie au client ; l'application **refuse** une clé `service_role` / `sb_secret_`.
- Toute table exposée doit activer Row Level Security (contrôlé en CI).
- Les autorisations (clubs, balades, positions GPS) seront vérifiées côté serveur.
