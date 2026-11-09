# Configuration

## 1. Outils

| Outil | Version | Usage |
| --- | --- | --- |
| Flutter | 3.47.x stable (Dart 3.13) | Application |
| Android Studio + SDK Android | récent | Builds Android |
| Xcode (macOS uniquement) | récent | Builds iOS |
| Supabase CLI | récent | Migrations, instance locale (optionnel) |
| Docker | récent | Supabase local / vérification des migrations (optionnel) |

Identifiants d'application provisoires : `com.ridergroup.rider_group` (Android `applicationId` et iOS bundle id). **À confirmer avant toute publication** : ils ne pourront plus changer une fois l'application publiée sur les stores.

## 2. Variables d'environnement

Les valeurs sont injectées à la compilation avec `--dart-define-from-file`. Les fichiers `env/*.json` sont ignorés par Git, à l'exception de `env/example.json`.

| Variable | Obligatoire | Description |
| --- | --- | --- |
| `APP_ENV` | non (`dev`) | `dev`, `staging` ou `prod`. |
| `SUPABASE_URL` | oui pour le mode en ligne | `https://<project-ref>.supabase.co`. HTTP n'est accepté que pour `localhost`, `127.0.0.1` et `10.0.2.2` (émulateur Android). |
| `SUPABASE_PUBLISHABLE_KEY` | oui pour le mode en ligne | Clé **publishable** (`sb_publishable_…`) ou ancienne clé `anon`. |

```sh
cp env/example.json env/dev.json      # puis compléter
flutter run --dart-define-from-file=env/dev.json
```

Sans ces valeurs, l'application démarre en mode **« Serveur non configuré »** et l'affiche clairement (accueil et Paramètres). Elle ne simule aucune connexion.

> ⚠️ Ne fournissez **jamais** la clé `service_role` / `sb_secret_…` à l'application : elle contourne toutes les règles RLS. L'application la détecte et refuse de s'initialiser avec. Toute valeur compilée dans une application mobile doit être considérée comme publique.

## 3. Projet Supabase (action humaine requise)

Recommandation : **un projet Supabase par environnement** (au minimum `dev` et `prod`) afin de séparer les données.

1. Créer le projet sur <https://supabase.com/dashboard> (région la plus proche des utilisateurs ; à arbitrer selon la latence mesurée depuis la RDC).
2. *Project Settings → API Keys* : copier l'URL du projet et la clé **publishable** dans `env/dev.json`.
3. Lier le dépôt et appliquer les migrations :
   ```sh
   supabase login
   supabase init          # crée supabase/config.toml, conserve supabase/migrations
   supabase link --project-ref <project-ref>
   supabase db push
   ```
4. *Authentication* (préparation de la Mission 02) : activer la confirmation d'e-mail, configurer un fournisseur SMTP (l'envoi intégré de Supabase est limité et réservé aux tests) et les URL de redirection pour les liens profonds.

### Instance locale (optionnel)

```sh
supabase start                       # nécessite Docker
supabase status                      # affiche l'URL et la clé publishable locales
```
Sur émulateur Android, utiliser `http://10.0.2.2:54321` comme `SUPABASE_URL`.

## 4. Vérifier les migrations sans Supabase

Le script applique les migrations sur une base PostgreSQL + PostGIS vierge (en recréant les rôles `anon`, `authenticated`, `service_role`), les ré-applique pour vérifier l'idempotence, puis exécute `supabase/tests/*.sql`.

```sh
docker run -d --name rider-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=rider -p 5432:5432 postgis/postgis:16-3.4
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/rider scripts/check_migrations.sh
```

La CI exécute ce même script à chaque push.

## 5. Services à configurer lors des missions suivantes

| Service | Mission | Action humaine |
| --- | --- | --- |
| Fournisseur de cartographie | 05 | Choisir après comparaison (tarifs, licence, hors ligne) — voir `docs/DECISIONS.md`. Créer les clés restreintes par application. |
| Firebase Cloud Messaging | 06 | Créer le projet Firebase, ajouter `google-services.json` (ignoré par Git). |
| Apple Push Notification service | 06 | Compte Apple Developer, clé APNs `.p8`, capacités *Push* et *Background Modes*. |
| Signature Android | 11 | Générer le keystore de release, `android/key.properties` (ignoré par Git). |
| Signature iOS | 11 | Certificats et profils via Xcode / App Store Connect. |

## 6. Remarques de sécurité Android

- `android:allowBackup="false"` : empêche la sauvegarde automatique (Google Drive) des données locales, dont les futurs jetons de session.
- La permission `INTERNET` est déclarée dans le manifeste principal (elle n'existe par défaut qu'en debug).
