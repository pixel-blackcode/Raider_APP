# Architecture

## Vue d'ensemble

```
┌───────────────────────── Application Flutter ─────────────────────────┐
│ presentation (widgets, écrans)  ──►  providers Riverpod (état)         │
│                                         │                              │
│                              domain (entités, règles pures)            │
│                                         │                              │
│                              data (repositories, sources Supabase)     │
└─────────────────────────────────────────┼─────────────────────────────┘
                                          ▼
        Supabase : Auth · PostgreSQL + PostGIS (RLS) · Realtime · Storage · Edge Functions
```

Le client n'est **jamais** source d'autorité : il affiche, le serveur autorise. Toute règle d'accès (membre de club, participant confirmé, verrouillage, partage GPS) est appliquée par RLS ou par des fonctions serveur.

## Arborescence `lib/`

| Dossier | Rôle |
| --- | --- |
| `main.dart` | Point d'entrée minimal. |
| `bootstrap.dart` | Lit la configuration, initialise Supabase si possible, charge les préférences, lance `ProviderScope`. |
| `app/app.dart` | `MaterialApp.router` : thèmes, localisations, routeur. |
| `app/router/` | Chemins (`app_routes.dart`), routeur GoRouter, coquille de navigation, page 404. |
| `core/config/` | `AppConfig` : variables de compilation, validation (URL HTTPS, refus des clés secrètes). |
| `core/backend/` | `BackendStatus` (non configuré / prêt / échec), initialisation Supabase, providers. |
| `core/preferences/` | Préférences locales **non sensibles**. |
| `core/theme/` | Thèmes Material 3 clair/sombre, `RiderColors` (SOS, succès, alerte, position périmée), espacements. |
| `core/widgets/` | Composants partagés : `EmptyState`, `InfoCard`, `SectionHeader`, `ShortcutTile`, `BackendStatusCard`, `FeaturePlaceholderScaffold`. |
| `features/<module>/` | Un module par fonctionnalité. |
| `l10n/` | `app_fr.arb` (modèle) et code généré dans `l10n/generated/`. |

### Convention d'un module

```
features/rides/
  data/          repositories + sources (Supabase), DTO
  domain/        entités immuables, règles métier pures (ex. machine à états d'une balade)
  presentation/  écrans, widgets, controllers Riverpod
```

En Mission 01, seuls les dossiers `presentation/` existent (écrans structurels). Les couches `data/` et `domain/` seront créées avec chaque module, sans dossier vide anticipé.

Règles de dépendance : `presentation → domain ← data`. Un module ne dépend pas des détails internes d'un autre module ; les éléments partagés montent dans `core/`.

## Navigation

- `StatefulShellRoute.indexedStack` : cinq onglets conservant leur pile et leur état — **Accueil** (`/accueil`), **Balades** (`/balades`), **Clubs** (`/clubs`), **Messages** (`/messages`), **Profil** (`/profil`).
- Écrans plein écran au-dessus de la barre : `/garage`, `/marketplace`, `/parametres`.
- `/` redirige vers `/accueil` ; toute route inconnue affiche une page « introuvable ».
- Mission 02 ajoutera la garde d'authentification (`redirect`) et les écrans de connexion.
- Le mode Convoi (Mission 05) aura une route plein écran dédiée, à interface simplifiée (zones tactiles ≥ 64 dp, `AppSpacing.convoyTouchTarget`).

## Gestion d'état

Riverpod 3. Les dépendances déterminées au démarrage (`appConfigProvider`, `backendStatusProvider`, `sharedPreferencesProvider`) sont des `Provider` **surchargés** dans `bootstrap.dart` ; les tests les surchargent de la même façon, sans réseau.

`supabaseClientProvider` renvoie `null` tant que le backend n'est pas initialisé : les modules doivent alors afficher un état explicite, jamais des données simulées.

## Backend

- Migrations SQL versionnées dans `supabase/migrations/` (format CLI Supabase `AAAAMMJJHHMMSS_nom.sql`).
- Schéma `private` non exposé par l'API pour les fonctions internes.
- Exécution des fonctions de `public` révoquée par défaut : chaque RPC exposée est autorisée explicitement.
- `supabase/tests/database_checks.sql` échoue si une table de `public` n'a pas RLS, si `private` est accessible aux clients, ou si une fonction `SECURITY DEFINER` ne fixe pas `search_path`.

## Thème et accessibilité

- Material 3, couleur de marque orange `#E8590C`, modes clair / sombre / système (persisté).
- Couleurs sémantiques métier via `ThemeExtension<RiderColors>`.
- Boutons de 48 dp minimum ; titres de section marqués `Semantics(header: true)`.

## Internationalisation

Français seul en Mission 01 (`app_fr.arb` est le modèle). Pour ajouter une langue : créer `lib/l10n/app_<code>.arb`, lancer `flutter gen-l10n`, ajouter la langue dans `CFBundleLocalizations` (iOS) et retirer le `locale` forcé dans `app.dart`.
