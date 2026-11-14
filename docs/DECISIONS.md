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
| D-19 | Session et vérificateur PKCE dans `flutter_secure_storage` ; effacement au premier lancement. | Jetons chiffrés au repos ; pas de session fantôme après réinstallation iOS. |
| D-20 | Liens e-mail : schéma `com.ridergroup.ridergroup://auth-callback`, flux PKCE. | Lié à l'identifiant d'application ; à changer avec lui (O-01). Les App Links / Universal Links (domaine vérifié) pourront le remplacer. |
| D-21 | Buckets Storage privés, images chargées avec le jeton de session. | Les médias d'un club privé ou d'un profil non découvrable ne fuient pas par URL publique. Coût : pas de CDN public. |
| D-22 | Confidentialité : « profil découvrable » et « accepter les invitations », activés par défaut. | Préférences effectivement appliquées par le serveur ; d'autres (GPS, messagerie) viendront avec leurs modules. |
| D-23 | Suppression de compte bloquée tant qu'on possède un club avec d'autres membres. | Évite de laisser des clubs sans propriétaire (résout O-08). |
| D-24 | Statut de balade + indicateur `joins_locked`. « Verrouillée » est un statut avant le départ ; pendant la balade, le verrouillage est un indicateur sur « En cours ». | Répond à l'exigence d'une balade « en cours dont les adhésions sont verrouillées », sans dupliquer les états. |
| D-25 | Le verrouillage bloque toutes les nouvelles inscriptions, y compris les approbations de demandes et les invitations. Pour accueillir quelqu'un, l'organisateur déverrouille. | Lecture stricte de « les invitations ne doivent pas contourner le verrouillage ». |
| D-26 | Un participant retiré ne peut pas revenir de lui-même ; seul un gestionnaire peut l'inviter à nouveau. | Exclusion effective. |
| D-27 | Les brouillons se suppriment ; les balades publiées s'annulent, avec un motif facultatif. | Traçabilité pour les participants. |
| D-28 | Fuseau IANA par balade (Kinshasa UTC+1, Lubumbashi UTC+2). Instants stockés en UTC, affichage dans le fuseau de la balade. Jeu complet de la base de fuseaux dans l'application (environ 440 Ko). | La RDC a deux fuseaux ; les jeux réduits omettent ces alias. |
| D-29 | Coordonnées en latitude / longitude simples, point PostGIS `geography` calculé par le serveur (colonne générée). | Lecture simple pour le client ; recherches spatiales indexées côté serveur. |
| D-30 | Une balade de club ne peut être créée que par un propriétaire ou administrateur du club, qui peut ensuite la gérer. | Cohérent avec les rôles de club (D-12). |
| D-32 | Projet de développement `rider-group-dev` (organisation RIDER GROUP, Paris, offre gratuite), séparé de l'organisation « open sphere » qui héberge une autre application en ligne. | Décision du propriétaire ; isolement des données et des quotas. |
| D-33 | APK de test construit par la CI à partir de variables GitHub (`DEV_SUPABASE_URL`, `DEV_SUPABASE_PUBLISHABLE_KEY`), signé avec la clé de debug. | Essais sur téléphone sans attendre la fin ; aucun identifiant dans le dépôt. |
| D-34 | **Cartographie : MapLibre (`maplibre_gl`) + tuiles OpenStreetMap**, sans service payant au départ ; source de tuiles interchangeable. | Décision du propriétaire (11/11/2026) : solution basique et gratuite tant que l'application n'est pas monétisée. Comparaison : [MAP_PROVIDERS.md](MAP_PROVIDERS.md). |
| D-35 | **Positions GPS conservées 72 heures après la fin de la balade**, puis supprimées. | Décision du propriétaire (11/11/2026). Mise en œuvre et purge automatique : Mission 05. |
| D-36 | **Fond de carte par défaut : style « liberty » d'OpenFreeMap** (tuiles OpenStreetMap, gratuit, sans clé ni compte), remplaçable sans changer le code via `MAP_STYLE_URL`. | Conforme à D-34. Risque : service communautaire sans SLA ; prévoir un hébergeur de tuiles (ou auto-hébergement) avant une forte audience. |
| D-37 | **Convoi : suivi au premier plan uniquement** ; dernière position seulement (pas d'historique) ; cadence adaptative 30/15/8 s ; seuils d'alerte 2 km et 3 min. | Évite un service d'arrière-plan permanent (batterie, refus App Store, vie privée). À réévaluer après essais terrain. |
| D-38 | **SOS : notification dans l'application d'abord** (bandeau rouge, son, vibration via le temps réel). Notifications push (Firebase/APNs) reportées. | Décision du propriétaire (12/11/2026). Limite affichée : un destinataire application fermée n'est pas prévenu. |
| D-39 | **Destinataires d'un SOS : participants confirmés et organisateurs de la balade en cours.** | Décision du propriétaire (12/11/2026) : simple et respectueux de la vie privée. |
| D-40 | **Appel d'urgence : 112 par défaut, modifiable** dans les Paramètres, stocké sur l'appareil ; disponibilité non garantie en RDC, affichée comme telle. | Décision du propriétaire (12/11/2026). |
| D-41 | **Style visuel « Vibrant & Block » adapté** à la marque (orange conservé) pour le fil et la messagerie : blocs à fort contraste, titres Barlow Condensed, photos bord à bord, zones tactiles ≥ 48 dp. | Recommandation de la base UI/UX (« Social Media App » → Vibrant & Block-based) ; palette néon écartée pour garder l'identité et la lisibilité au soleil. |
| D-42 | **Publications : audience « tous les motards connectés » ou « membres du club »** ; aucune publication visible sans compte. | Respect de la confidentialité des clubs ; pas de diffusion publique sur Internet. |
| D-43 | **Photos seulement (4 max, 5 Mo)** ; vidéos reportées. | Coût et limites du stockage gratuit. |
| D-44 | **Blocage réciproque et silencieux** : la personne bloquée n'est pas prévenue. | Pratique standard de sécurité des réseaux sociaux. |
| D-45 | **3 signalements distincts masquent automatiquement** un contenu en attendant la décision d'un modérateur. | Limite l'exposition aux contenus abusifs sans attendre ; réversible (« Rétablir »). |
| D-46 | **Discussion de balade : accès dérivé de la participation** (pas de liste de membres séparée). | Un participant retiré perd l'accès immédiatement, comme pour le Convoi et le SOS. |
| D-47 | **Marketplace sans paiement** : prix indicatif (USD ou CDF, ou « à discuter »), contact par la messagerie, rappel de prudence ; zone approximative seulement. | Critère 14 ; aucune responsabilité de paiement pour la plateforme. |
| D-48 | **Recherche tolérante** : texte « plié » (minuscules, sans accents, « ph » = « f », lettres doublées réduites) + similarité par trigrammes (`pg_trgm`). | Demande du propriétaire (Phoenix / Fenix) ; reste performant avec des index. |
| D-49 | **10 photos** par publication et par annonce. | Demande du propriétaire (14/11/2026). |
| D-50 | **Certification payante** (Mission 09) : motard 9 $/mois, club 20 $/mois, regroupement 20 $/mois ; paiement Mobile Money hors application ; le payeur saisit la référence, l'administration saisit les paiements reçus ; correspondance = activation pour 1 mois ; le paiement seul suffit pour le badge. | Décision du propriétaire (14/11/2026). Risque signalé : les magasins d'applications peuvent exiger leur système de paiement pour un abonnement qui débloque des fonctions. |
| D-51 | **Itinéraire pour les retardataires** : seul le trajet du chef de convoi est enregistré pendant la balade, visible des participants, supprimé 72 h après la fin. | Décision du propriétaire (14/11/2026) ; complète D-35. |
| D-52 | **Notifications** : cloche et sons dans l'application d'abord, notifications push (Firebase) ensuite. | Décision du propriétaire (14/11/2026) ; fait évoluer D-38. |
| D-31 | Suppression de compte : fichiers de club conservés sans propriétaire ; refus tant qu'on organise une balade active avec des inscrits ; historique des balades terminées conservé. | Documentation Supabase (« You cannot delete a user if they are the owner of any objects in Supabase Storage ») ; évite d'effacer l'historique ou d'abandonner une balade en cours. |

## Décisions ouvertes (validation du propriétaire requise)

| # | Sujet | Mission | Options / remarques |
| --- | --- | --- | --- |
| O-01 | Identifiant d'application et nom de domaine définitifs. | avant 11 | Irréversible après publication sur les stores. |
| O-04 | Région d'hébergement Supabase. | 02 | ✅ Développement : eu-west-3 (Paris). À confirmer pour la production par des mesures de latence depuis la RDC. |
| O-05 | Fournisseur SMTP pour les e-mails d'authentification. | 02 | Requis pour la production (limites du service intégré). |
| O-07 | Une vitrine de club privé référencé affiche nom, ville, description et règlement. | 03 | Alternative : masquer le règlement aux non-membres (nécessite une table séparée). |
| O-09 | Suppression de compte par fonction SQL (`delete from auth.users`). | 02 | ✅ Vérifiée sur le projet Supabase réel (scénario annulé, voir CONFIGURATION.md §3 bis), y compris avec un fichier Storage appartenant à l'utilisateur. |
| O-10 | Projet Supabase dédié à Rider Group. | — | ✅ Créé : `rider-group-dev` (D-32). |
| O-06 | Cadre juridique (protection des données en RDC et pays futurs). | 11 | Analyse juridique à mener ; aucune conformité n'est affirmée à ce stade. |
