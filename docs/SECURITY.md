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
- **Session :** elle est gérée par `supabase_flutter` (jeton d'accès + jeton de rafraîchissement). Par défaut, elle est stockée dans `SharedPreferences`, qui n'est **pas** un stockage chiffré.
  - Sur Android, la sauvegarde automatique est désactivée (`allowBackup="false"`).
  - Le passage à un stockage sécurisé (Keychain / Keystore) est prévu en Mission 02.

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

Règles complémentaires :

- Un club public est toujours référencé, avec une adhésion libre ou sur approbation. Un club privé fonctionne sur approbation ou sur invitation (contrainte SQL).
- **Vitrine d'un club privé référencé :** nom, ville, description et règlement sont visibles par les motards connectés. La liste des membres ne l'est pas. Pour tout masquer, le propriétaire désactive le référencement.
- **Le badge Vérifié** ne donne aucun accès supplémentaire, et l'administration de la plateforme n'obtient aucun accès aux membres des clubs privés. Ces deux points sont testés.
- **Limitation des abus :** 3 créations de club par utilisateur et par 24 h.
- **Noms de club uniques**, sans distinction de casse ni d'espaces, pour limiter l'usurpation.

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
