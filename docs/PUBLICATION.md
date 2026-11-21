# Publication sur Google Play et l'App Store (Mission 12)

Ce guide liste, dans l'ordre, ce que **le propriétaire** doit faire (comptes,
paiements, formulaires) et ce que la CI fait toute seule.

- Identifiant Android : `com.ridergroup.rider_group` — iOS : `com.ridergroup.riderGroup` (définitifs).
- Serveur : `rider-group-dev` sert aussi de production ; les données de test
  sont effacées juste avant le lancement (« Nettoyage avant lancement »).
- Textes et images des fiches : `store/FICHES.md`, `store/*.png`.
- Pages publiques : https://pixel-blackcode.github.io/Raider_APP/confidentialite.html,
  `conditions.html`, `suppression-compte.html`.

## 0. Avant tout lancement (serveur)

1. **E-mails d'inscription (obligatoire)** : le service d'e-mail intégré de
   Supabase est limité à quelques messages par heure. Créer un compte gratuit
   chez un fournisseur SMTP (ex. Brevo : 300 e-mails/jour gratuits), puis
   Supabase → *Authentication → Emails → SMTP Settings* : hôte, port, identifiant,
   mot de passe, expéditeur (ex. `Rider Group <adresse validée chez le fournisseur>`).
2. **Mots de passe (SEC-02)** : Supabase → *Authentication → Providers → Email* :
   longueur minimale 8, « lettres et chiffres ».
3. **Nettoyage avant lancement** (une seule fois, juste avant l'ouverture) :
   - demander à Claude de lancer `scripts/purge_test_data.sql` (efface tous les
     comptes sauf les administrateurs et tout le contenu de test) ;
   - puis Supabase → *Storage* : ouvrir chaque bucket (`avatars`, `club-media`,
     `post-media`, `listing-media`, `ride-media`, `event-media`, `shop-media`,
     `garage-media`, `verification-docs`), tout sélectionner, supprimer.

## 1. Google Play

### Une fois
1. Créer un compte **Google Play Console** (25 $ une fois) : https://play.google.com/console
   — vérification d'identité (pièce d'identité, quelques jours).
   - Compte **personnel** : Google exige un **test fermé avec au moins 12 testeurs
     pendant 14 jours** avant la production. Compte **organisation** (numéro
     D-U-N-S) : pas cette obligation.
2. *Créer une application* : nom « Rider Group », langue française, application,
   gratuite ; accepter les déclarations.
3. *Configuration de l'application* (« App content ») :
   - Politique de confidentialité : l'URL ci-dessus.
   - Accès à l'application : fournir un **compte de démonstration** (e-mail + mot
     de passe d'un compte de test) pour les examinateurs.
   - Annonces : non. Classification : voir `store/FICHES.md`.
   - Public cible : 16 ans et plus.
   - **Sécurité des données** : voir le tableau plus bas.
   - Suppression de compte : URL `suppression-compte.html`.
   - Applications d'actualités / santé / finance : non.
4. *Fiche principale du Store* : textes et images de `store/FICHES.md`.

### À chaque version
1. GitHub → *Actions* → **« Publication (stores) »** → *Run workflow* (Android coché).
2. Télécharger l'artefact `rider-group-play-aab` (fichier `.aab`).
3. Play Console → *Tests* (interne, puis fermé) ou *Production* → *Créer une
   version* → déposer le `.aab`. Au premier envoi, accepter **la signature
   d'application par Google Play** : la clé `rider-group-release` devient la
   « clé d'importation » (garder le fichier et ses mots de passe en lieu sûr).

## 2. App Store (iPhone)

### Une fois
1. Adhérer à l'**Apple Developer Program** (99 $ par an) :
   https://developer.apple.com/programs/ (individuel, ou organisation avec D-U-N-S).
2. https://developer.apple.com/account → *Certificates, Identifiers & Profiles* :
   - *Identifiers* → `+` → App IDs → identifiant **`com.ridergroup.riderGroup`**,
     cocher **Push Notifications**.
   - *Keys* → `+` → cocher **Apple Push Notifications service (APNs)** →
     télécharger le fichier `.p8` (une seule fois !) et noter son *Key ID* et
     votre *Team ID*.
3. **Firebase** (projet déjà utilisé pour Android) → *Paramètres du projet* :
   - *Ajouter une application* → iOS → identifiant `com.ridergroup.riderGroup` →
     télécharger `GoogleService-Info.plist` (pour lire les valeurs ci-dessous,
     ne pas l'envoyer sur GitHub).
   - *Cloud Messaging* → *Configuration de l'application Apple* → importer la clé
     APNs `.p8` avec son Key ID et le Team ID.
4. GitHub → *Settings → Secrets and variables → Actions* :
   - **Variables** (valeurs publiques du `GoogleService-Info.plist`) :
     `FIREBASE_IOS_APP_ID` (= `GOOGLE_APP_ID`), `FIREBASE_IOS_API_KEY`
     (= `API_KEY`), `FIREBASE_SENDER_ID` (= `GCM_SENDER_ID`), `FIREBASE_PROJECT_ID`
     (= `PROJECT_ID`).
   - **Secrets** : `APPLE_TEAM_ID` ; clé API App Store Connect (App Store Connect →
     *Utilisateurs et accès* → *Intégrations* → *App Store Connect API* → nouvelle
     clé, rôle **Admin**) : `ASC_KEY_ID`, `ASC_ISSUER_ID`, et `ASC_KEY_P8_BASE64`
     = le fichier `.p8` de cette clé encodé en base64.
5. **App Store Connect** → *Apps* → `+` → nouvelle app : iOS, nom « Rider Group »,
   langue française, identifiant `com.ridergroup.riderGroup`, SKU `ridergroup`.

### À chaque version
1. GitHub → *Actions* → **« Publication (stores) »** → *Run workflow* (iOS coché) :
   la CI compile, signe automatiquement et envoie sur **TestFlight**.
2. App Store Connect → *TestFlight* : tester sur iPhone (installer l'app
   TestFlight, inviter des testeurs).
3. *Distribution* → version → textes et captures de `store/FICHES.md`,
   *Confidentialité de l'app* (tableau plus bas), compte de démonstration et note
   pour l'examinateur (« Alerte SOS et mode solo : aides entre motards, ne
   remplacent pas les secours ; la position n'est partagée qu'à la demande »),
   puis *Soumettre pour vérification*.

## 3. Formulaires « données » (Google Play et Apple)

| Donnée | Collectée | Partagée avec des tiers | Finalité | Facultative | Liée à l'identité |
| --- | --- | --- | --- | --- | --- |
| E-mail | Oui | Non | Gestion du compte | Non | Oui |
| Nom, pseudo, photo, ville | Oui | Non | Fonctionnalités de l'app | Oui (sauf nom et pseudo) | Oui |
| Position précise | Oui | Non | Fonctionnalités (convoi, SOS, mode solo) | Oui | Oui |
| Photos | Oui | Non | Fonctionnalités | Oui | Oui |
| Messages | Oui | Non | Fonctionnalités | Oui | Oui |
| Autre contenu (publications, annonces, garage) | Oui | Non | Fonctionnalités | Oui | Oui |
| Pièce d'identité, numéro de téléphone (vérification) | Oui | Non | Vérification (sécurité) | Oui | Oui |
| Identifiant de l'appareil (jeton de notification) | Oui | Non | Fonctionnalités (notifications) | Non | Oui |
| Diagnostics (version de l'app dans les retours) | Oui | Non | Analyse / correction | Oui | Oui |

- Données chiffrées en transit : **oui**. Suppression possible : **oui** (dans
  l'application et par e-mail).
- Publicité, suivi entre applications (« tracking » Apple) : **non**.
- Les prestataires (Supabase, Firebase/APNs, OpenFreeMap) sont des sous-traitants
  agissant pour Rider Group : ce n'est pas un « partage » au sens des formulaires.

## 4. Ce que la CI fait

- Workflow **CI** (chaque envoi) : tests, APK de test, build iOS non signé.
- Workflow **Publication (stores)** (manuel) : `.aab` signé (clé de production,
  numéro de version = 10000 + n° d'exécution) et envoi TestFlight si les secrets
  Apple existent.
- Workflow **Tableau de bord web** : site de l'équipe et pages publiques.
