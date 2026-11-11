# Sécurité et contrôle d'accès

> Ce document décrit les mesures **implémentées et testées**. Il ne constitue pas une attestation de conformité réglementaire (voir `DECISIONS.md`, O-06).

## Principes

1. **Le serveur décide.** L'application masque les actions impossibles pour le confort d'utilisation, mais chaque règle est appliquée par PostgreSQL (Row Level Security et fonctions `SECURITY DEFINER`). Un client modifié ne peut rien contourner.
2. **Lecture par RLS, écriture par fonctions.** Les tables sensibles sont en lecture seule côté client. Les écritures passent par des fonctions serveur qui vérifient l'identité (`auth.uid()`), le rôle et l'état, puis journalisent.
3. **Privilèges minimaux.**
   - `anon` n'a accès à aucune table ni fonction de l'application.
   - Les nouvelles fonctions ne sont pas exécutables par défaut.
   - Les colonnes modifiables sont listées une par une (`GRANT UPDATE (col, …)`).
4. **Contrôles automatiques en CI** (`supabase/sql_tests/01_database_checks.sql`) :
   - RLS active sur toute table de `public` ;
   - schéma `private` fermé à `anon` et tables privées inaccessibles ;
   - `search_path` fixé sur toute fonction `SECURITY DEFINER` ;
   - aucune fonction ni table exposée à `anon`.

## Comptes et profils

- **Un utilisateur, un compte, un profil.** Le profil est créé par un trigger lors de l'inscription. Les pseudonymes invalides ou déjà pris reçoivent une valeur de repli, afin que l'inscription n'échoue jamais.
- **L'e-mail n'est pas copié dans `profiles`.** Les autres motards voient le pseudonyme, le nom affiché, la ville et la présentation.
- **Modification réservée au propriétaire du profil**, et limitée aux colonnes autorisées. `id` et les dates ne sont pas modifiables.
- **Session :** jeton d'accès et jeton de rafraîchissement sont stockés **chiffrés** via `flutter_secure_storage` (Keychain sur iOS, Keystore sur Android), tout comme le vérificateur PKCE.
  - Le Keychain iOS survit à la désinstallation. Au premier lancement d'une installation, les secrets résiduels sont donc effacés.
  - La sauvegarde automatique Android est désactivée (`allowBackup="false"`).
- **Liens reçus par e-mail** (confirmation, réinitialisation) : flux PKCE. Un lien ne fonctionne que sur l'appareil qui a fait la demande. Ils arrivent par le schéma `com.ridergroup.ridergroup://auth-callback`, que seul `supabase_flutter` traite (le routeur ne reçoit pas les liens profonds).
- **Mot de passe oublié :** la réponse est la même que l'adresse corresponde ou non à un compte, ce qui empêche de deviner les comptes existants. Après ouverture du lien, la saisie d'un nouveau mot de passe est imposée avant tout accès.
- **Confidentialité :**
  - avec un profil non découvrable, seuls les membres d'un club commun voient le profil. Il en va de même pour les administrateurs d'un club auquel une demande est adressée, et pour la personne qui a envoyé une invitation. Le pseudonyme n'est plus trouvable par recherche ;
  - l'utilisateur peut refuser toute invitation de club, et c'est vérifié par le serveur ;
  - les préférences ne sont lisibles et modifiables que par leur propriétaire.
- **Suppression de compte** (`delete_my_account`) :
  - elle est refusée tant que l'utilisateur possède un club comptant d'autres membres ;
  - sinon, elle supprime les clubs sans autre membre, puis le compte. Profil, préférences, adhésions, demandes et invitations reçues partent en cascade ;
  - l'application supprime d'abord la photo de profil (Supabase interdit la suppression directe de fichiers en SQL) ;
  - le journal d'audit conserve l'identifiant de l'action, sans donnée de profil.

## Médias (Supabase Storage)

- **Deux buckets privés,** limités aux formats JPEG, PNG et WebP :
  - `avatars`, 2 Mo par fichier ;
  - `club-media`, 5 Mo par fichier.
- **Rien n'est accessible par une URL publique.** Les images sont chargées avec le jeton de session, et les politiques RLS de `storage.objects` décident :
  - **photo de profil :** lisible si le profil est visible ; écriture uniquement dans son propre dossier `<user_id>/` ;
  - **logo et couverture :** lisibles si le club est visible ; écriture par le propriétaire ou un administrateur du club, dans le dossier `<club_id>/`.
- **Les chemins enregistrés en base doivent pointer vers le bon dossier,** ce que vérifient des contraintes `CHECK` : un club ne peut pas afficher les images d'un autre.
- **Limite connue :** les fichiers d'un club supprimé (ou d'un club supprimé avec le compte de son propriétaire) restent dans Storage, sans être lisibles, car plus aucun club ne les rend visibles. Un nettoyage périodique est prévu en Mission 11.

## Clubs — matrice des permissions

| Action | Non-membre | Membre | Modérateur | Admin | Propriétaire | Admin plateforme |
| --- | --- | --- | --- | --- | --- | --- |
| Voir un club public / privé référencé | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (même règle) |
| Voir un club privé masqué | ❌ (sauf invitation ou demande en cours) | ✅ | ✅ | ✅ | ✅ | ❌ |
| Voir les membres d'un club privé | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Modifier nom, description, règlement, ville | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| Modifier visibilité, référencement, mode d'adhésion | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Inviter, traiter les demandes d'adhésion | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| Retirer un membre | ❌ | ❌ | rang inférieur | rang inférieur | tous | ❌ |
| Changer un rôle | ❌ | ❌ | ❌ | vers modérateur / membre (rang inférieur) | admin / modérateur / membre | ❌ |
| Transférer la propriété, supprimer le club | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Demander le badge Vérifié | ❌ | ❌ | ❌ | ❌ | ✅ | — |
| Accorder le badge Vérifié | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Écrire `verified_at`, `member_count`, `owner_id`, `suspended_at` | ❌ | ❌ | ❌ | ❌ | ❌ | via fonction serveur uniquement |
| Modifier logo / couverture | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |

Règles complémentaires :

- Un club public est toujours référencé, avec une adhésion libre ou sur approbation. Un club privé fonctionne sur approbation ou sur invitation (contrainte SQL).
- **Vitrine d'un club privé référencé :** nom, ville, description et règlement sont visibles par les motards connectés. La liste des membres ne l'est pas. Pour tout masquer, le propriétaire désactive le référencement.
- **Le badge Vérifié** ne donne aucun accès supplémentaire, et l'administration de la plateforme n'obtient aucun accès aux membres des clubs privés. Ces deux points sont testés.
- **Limitation des abus :** 3 créations de club par utilisateur et par 24 h.
- **Noms de club uniques**, sans distinction de casse ni d'espaces, pour limiter l'usurpation.

## Balades — règles d'accès

| Action | Visiteur connecté | Invité | Demandeur | Participant | Retiré | Gestionnaire* |
| --- | --- | --- | --- | --- | --- | --- |
| Voir un brouillon | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Voir une balade publique / de club ouverte | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Voir une balade de club réservée | membres du club | membres du club | ✅ | ✅ | si membre du club | ✅ |
| Voir une balade privée | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Voir la liste des participants | si balade ouverte | si balade ouverte | si balade ouverte | ✅ | si balade ouverte | ✅ |
| Données réservées aux participants (positions, discussion : Missions 05 et 07) | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Rejoindre / demander | selon le mode | ✅ (accepter) | — | — | ❌ | — |
| Modifier (avant le départ), changer le statut, inviter, approuver, retirer | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

\* Gestionnaire : l'organisateur, ou un administrateur du club pour une balade de club.

**Règles complémentaires :**
- **Nouvelles inscriptions :** possibles uniquement si la balade est publiée, ou en cours sans verrouillage, et non complète. Cette règle s'applique aux adhésions directes, aux approbations **et** aux acceptations d'invitation.
- **Invitations :** une invitation ne contourne ni le verrouillage, ni la capacité, ni la restriction aux membres d'un club. Elle respecte aussi la préférence « Accepter les invitations aux balades ».
- **Ce qui n'est jamais modifiable directement :** statut, organisateur, club, compteur de participants, verrouillage. Ces champs ne changent que par les fonctions serveur.
- **Modifications des détails :** impossibles une fois la balade démarrée. La date de départ ne peut pas passer dans le passé, et la capacité ne peut pas descendre sous le nombre d'inscrits.
- **Fin ou annulation :** les demandes et invitations en attente sont closes automatiquement.
- **Confidentialité des profils :** un profil non découvrable reste visible des autres participants confirmés de la même balade, et de l'organisateur auquel une demande est adressée.
- **Limitation des abus :** 10 balades créées par utilisateur et par 24 h.

## Journal d'audit

`private.audit_logs` enregistre l'auteur, l'action, l'entité et les détails de chaque opération sensible :
- création et suppression de club ;
- adhésions, départs, retraits ;
- changements de rôle et transfert de propriété ;
- invitations ;
- demandes et décisions de vérification.

Le journal est inaccessible aux clients.

## Administration de la plateforme

Les administrateurs Rider Group sont listés dans `private.platform_admins`. Ils sont désignés manuellement par SQL, avec un rôle disposant de tous les droits. Voir `CONFIGURATION.md`, section 3. Le tableau de bord d'administration est prévu en Mission 10.
