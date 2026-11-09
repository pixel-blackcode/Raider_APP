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
4. *Authentication → Providers → Email* : laisser **Confirm email** activé. L'application gère le cas « confirmation requise » : elle affiche un message, puis l'utilisateur se connecte après avoir cliqué le lien.
5. *Authentication → SMTP* : configurer un fournisseur d'e-mails. L'envoi intégré de Supabase est très limité et réservé aux tests.
6. *Authentication → URL Configuration* : renseigner le *Site URL*, vers lequel mène le lien de confirmation. Les liens profonds vers l'application arriveront avec la fin de la Mission 02.
7. Désigner un administrateur Rider Group, qui pourra examiner les demandes de badge « Vérifié ». Dans *SQL Editor*, avec l'identifiant visible dans *Authentication → Users* :
   ```sql
   insert into private.platform_admins (user_id, note)
   values ('<uuid-de-l-utilisateur>', 'Administrateur Rider Group');
   ```
   En attendant le tableau de bord (Mission 10), une demande s'examine ainsi :
   ```sql
   -- Lister les demandes en attente
   select r.id, c.name, r.message, r.created_at
     from public.club_verification_requests r join public.clubs c on c.id = r.club_id
    where r.status = 'pending';
   ```
   L'approbation passe par la fonction `public.review_club_verification(request_id, true, 'note')`. Elle doit être appelée par un utilisateur listé dans `platform_admins`, depuis l'application d'administration à venir, ou en SQL après `set request.jwt.claims`. Elle met à jour le badge et journalise la décision.

### Instance locale (optionnel)

```sh
supabase start                       # nécessite Docker
supabase status                      # affiche l'URL et la clé publishable locales
```
Sur émulateur Android, utiliser `http://10.0.2.2:54321` comme `SUPABASE_URL`.

## 4. Vérifier les migrations et les règles d'accès sans Supabase

Le script commence par recréer, sur une base PostgreSQL + PostGIS **vierge**, ce que fournit Supabase :
- les rôles `anon`, `authenticated` et `service_role` ;
- `auth.users` et `auth.uid()` ;
- les privilèges par défaut.

Il applique ensuite les migrations, puis exécute `supabase/sql_tests/*.sql`. Ces tests jouent des scénarios multi-utilisateurs, chacun agissant « en tant que » un compte, comme PostgREST avec un JWT. Le script s'arrête au premier échec.

```sh
docker run -d --name rider-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgis/postgis:16-3.4
# L'image installe PostGIS dans « public » de la base par défaut : utiliser une base vierge.
psql postgresql://postgres:postgres@localhost:5432/postgres -c 'create database rider template template1'
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
