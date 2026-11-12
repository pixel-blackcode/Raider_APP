# Partie 7 — Architecture de sécurité

## Principes

1. **L'interface n'est jamais une barrière.** Toute règle est appliquée en base (RLS, contraintes) ou dans une
   fonction serveur. Masquer un bouton est un confort, pas une protection.
2. **Aucun secret dans un client.** Le mobile et le back-office n'embarquent que l'URL du projet et la clé publique.
   La clé `service_role` n'existe que dans les secrets des Edge Functions et de la CI.
3. **Moindre privilège.** Un gérant n'accède qu'à ses établissements ; un modérateur ne voit pas les paiements.
4. **Tout ce qui compte est tracé** dans `audit_logs`.

## Authentification

| Méthode | Version | Remarques |
| --- | --- | --- |
| E-mail + mot de passe | MVP | Confirmation par e-mail, réinitialisation par lien ; longueur minimale 8, contrôle des mots de passe compromis si l'option est disponible sur le plan retenu (**à vérifier**) |
| Google | MVP | Voir configuration ci-dessous |
| Téléphone (SMS) | V2, sous condition | Supabase prend en charge Twilio, MessageBird, Vonage et Textlocal, plus un hook d'envoi personnalisé. La livraison réelle vers les numéros +243 n'a pas pu être confirmée : **test obligatoire** avant d'activer |
| Apple | Avec la version iOS | Exigé par Apple dès qu'une connexion tierce (Google) est proposée sur iOS — règle **à revérifier** au moment de la publication |

Sessions : jeton d'accès court et jeton de rafraîchissement, stockés dans le stockage sécurisé du téléphone
(Keystore / Keychain). Déconnexion = révocation + effacement des données personnelles locales. Les rôles ne sont
**pas** lus dans des métadonnées modifiables par l'utilisateur : ils viennent des tables `platform_roles` et
`establishment_members`.

Administrateurs et modérateurs : double authentification (TOTP) obligatoire, vérifiée dans les politiques par le
niveau d'assurance de la session.

### Google Sign-In : configuration requise (intervention humaine)

| Élément | Où | Qui |
| --- | --- | --- |
| Projet Google Cloud + écran de consentement OAuth | Console Google Cloud | Vous |
| Client OAuth « Web » (identifiant + secret) | Console Google, puis réglages Auth de Supabase | Vous |
| Client OAuth Android par saveur : nom du paquet + empreinte SHA-1 du certificat de signature (debug, release **et** clé de signature Google Play) | Console Google | Vous, avec les empreintes que je fournis |
| Client OAuth iOS + schéma d'URL inversé dans `Info.plist` | Console Google, projet Xcode | Vous (Mac requis) |
| URL de redirection et liens profonds (`kinguide://auth-callback`) | Réglages Auth de Supabase | Vous |

## Modèle de permissions

| Ressource | Visiteur | Inscrit | Membre de l'établissement | Modérateur | Admin |
| --- | --- | --- | --- | --- | --- |
| Fiches, événements, promotions publiés | Lecture | Lecture | Lecture | Lecture | Tout |
| Brouillons d'un établissement | — | — | Lecture, écriture | Lecture | Tout |
| Publication | — | — | Par RPC, selon forfait | Suspendre, masquer | Tout |
| Favoris, lieux visités | — | Les siens | Les siens | — | — |
| Avis | Lecture | Écrire le sien | Lire, signaler | Masquer | Tout |
| Statistiques d'un établissement | — | — | Selon forfait | — | Lecture |
| Abonnement, factures | — | — | `owner` : lecture | — | Tout |
| Paiements | — | — | `owner` : lecture | — | Validation |
| Revendications, pièces | — | Les siennes | — | — | Décision |
| Référentiels, paramètres, taux | Lecture | Lecture | Lecture | Lecture | Écriture |
| Journal d'audit | — | — | — | — | Lecture seule |

### Stratégie RLS

- RLS activé sur toutes les tables ; un test automatisé échoue si une table du schéma public n'a pas RLS.
- Politiques séparées par opération (`select`, `insert`, `update`, `delete`) et par rôle (`anon`, `authenticated`).
- `update` : clause `with check` systématique, pour empêcher de déplacer une ligne vers un autre établissement.
- Colonnes sensibles (`status`, `verification_status`, `rating_*`, tout `subscriptions`, `payments`) : aucun droit
  d'écriture pour les clients ; modification par fonctions `security definer` qui revérifient le rôle de l'appelant.
- Les fonctions `security definer` fixent `search_path`, ne sont exécutables que par les rôles prévus et ne
  renvoient que les colonnes nécessaires.
- Les vues exposées sont en `security invoker`.
- Storage : compartiment public en lecture seule pour les variantes d'images ; compartiment privé pour les pièces de
  vérification et les factures, accessible par URL signée de courte durée.

Chaque politique a au moins deux tests SQL : un accès légitime qui réussit, un accès illégitime qui échoue
(en particulier : gérant de l'établissement A contre données de l'établissement B).

## Vérification des professionnels

1. Le gérant crée un compte, puis **revendique** une fiche existante ou en propose une nouvelle (brouillon).
2. Il joint une pièce (document d'enregistrement, facture au nom de l'établissement, photo de la devanture avec un
   code affiché) dans le compartiment privé.
3. Un administrateur vérifie : cohérence des pièces et rappel sur le numéro **déjà public** de la fiche, jamais sur
   un numéro fourni par le demandeur seul.
4. La décision passe par la fonction `approve_claim` / `reject_claim` : création du lien `owner`, changement de
   `verification_status`, entrée d'audit avec le motif.
5. La vérification ne dépend d'aucun paiement et ne s'achète pas. Elle peut être retirée (changement de
   propriétaire, fraude), sans perte de données.

## Protections contre les abus

| Menace | Protection |
| --- | --- |
| Essais de mots de passe en rafale | Limites de débit de Supabase Auth ; CAPTCHA sur inscription et connexion si l'abus apparaît |
| Avis en rafale, faux avis | Un avis par compte et par lieu ; compte confirmé ; délai minimal entre deux avis ; limite quotidienne ; interdiction pour les membres de l'établissement ; signalement |
| Faux clics sur les statistiques | Dédoublonnage par empreinte d'appareil non réversible et fenêtre de temps ; plafond par appareil ; le gérant et ses collaborateurs ne sont pas comptés |
| Revendication abusive | Vérification manuelle ; une demande ouverte à la fois ; audit |
| Fraude à l'abonnement | Droits calculés en base à partir de `subscriptions` ; jamais d'activation par le client ; essai gratuit unique par établissement |
| Campagne fictive ou impayée | Une campagne ne démarre que si sa facture est `paid` ; contenu sponsorisé revu avant diffusion |
| Fichier malveillant | Vérification du type réel (octets d'en-tête), taille maximale, ré-encodage complet de l'image (supprime métadonnées et contenu caché), nom de fichier généré par le serveur |
| Injection, XSS dans le back-office | Requêtes paramétrées ; aucun HTML saisi par un utilisateur n'est rendu tel quel |
| Publications en masse | Limites techniques par établissement et par jour, y compris pour les forfaits « illimités » |
| Appels directs à l'API | Tout appel direct passe par les mêmes politiques RLS que l'application |

## Données personnelles

- Collecte minimale : e-mail, nom affiché, avatar facultatif. Aucune position enregistrée : la localisation sert au
  calcul de distance sur le téléphone ou est envoyée arrondie pour une recherche, sans être stockée.
- Statistiques : empreinte d'appareil renouvelée chaque jour, non reliée à un compte.
- Suppression de compte depuis l'application (exigée par Google Play et Apple) : anonymisation des avis ou
  suppression au choix, effacement des favoris et lieux visités.
- Pièces de vérification supprimées 90 jours après la décision.
- Politique de confidentialité et conditions d'utilisation en français : rédaction et validation juridique à votre
  charge (cadre légal congolais **à vérifier**).

## Journal d'audit

Écrit par déclencheurs et par les fonctions serveur, jamais par un client. Événements couverts : attribution de rôle,
décision de revendication, changement de statut d'une fiche ou d'un contenu, modération, changement d'abonnement,
validation ou refus de paiement, modification de taux, de tarif ou de paramètre, suspension de compte. Aucune
modification ni suppression possible, y compris pour un administrateur.

## Sauvegardes et restauration

- Production sur un plan Supabase incluant des sauvegardes automatiques ; durée de rétention **à vérifier** sur
  l'offre retenue.
- En complément, export logique hebdomadaire (`pg_dump`) chiffré vers un stockage hors Supabase.
- Exercice de restauration sur un projet vierge avant le lancement, puis une fois par trimestre ; le temps de
  restauration mesuré est consigné.
- Les migrations sont versionnées dans le dépôt : la structure se reconstruit à partir de zéro.

## Secrets et chaîne de livraison

- `.env`, clés et fichiers de signature exclus par `.gitignore` ; seuls des fichiers d'exemple sont suivis.
- Secrets de CI dans GitHub Actions ; analyse de secrets activée sur le dépôt.
- MCP Supabase relié au seul projet de développement ; la production n'est modifiée que par migrations revues.
- Signature Android : clé de téléversement conservée par vous, hors dépôt ; signature finale gérée par Google Play.
