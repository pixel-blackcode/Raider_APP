# Guide de test sur téléphone (projet `rider-group-dev`)

Ce guide sert à vérifier sur de vrais téléphones ce qui est livré : comptes, clubs et balades.
L'idéal est d'avoir **deux téléphones Android** ou plus, et donc deux comptes : A et B.

## 0. Installer l'application

1. Sur GitHub, ouvre **Actions → CI**, puis le dernier run vert de la branche `ccr-7608116f-iuxjed`.
2. En bas de la page, télécharge l'artefact **rider-group-dev-apk**. Il est conservé 14 jours.
3. Décompresse le fichier et copie `rider-group-dev.apk` sur le téléphone.
4. Ouvre le fichier et autorise l'installation depuis cette source si Android le demande.
5. Lance l'application. **Attendu :** l'écran de connexion s'affiche, sans le bandeau « Serveur non configuré ».

> ⚠️ Dans Supabase, *Authentication → Sign In / Providers → **Email*** : le fournisseur **Email doit rester activé**, ainsi que « Allow new users to sign up ». Seule l'option **« Confirm email »** peut être désactivée pour les tests. Si le fournisseur est désactivé, l'inscription échoue avec « Les inscriptions par e-mail sont désactivées sur le serveur ».
>
> Si la confirmation des e-mails est activée dans Supabase, le service d'e-mails intégré n'envoie qu'environ 2 à 4 messages par heure. Pour tester à plusieurs, désactive temporairement « Confirm email » dans Supabase (*Authentication → Providers → Email*), sur ce projet de test uniquement.

## 1. Comptes et profil

| # | Action | Résultat attendu |
| --- | --- | --- |
| 1.1 | Créer le compte A : nom, pseudonyme, e-mail, mot de passe d'au moins 8 caractères avec une lettre et un chiffre | Connexion directe, ou message « Confirmez votre adresse e-mail » si la confirmation est activée |
| 1.2 | Si un e-mail arrive, ouvrir le lien **sur le téléphone** | L'application s'ouvre, connectée |
| 1.3 | Profil → Modifier : ville et présentation | Les changements s'affichent |
| 1.4 | Profil → icône appareil photo → Changer la photo | La photo apparaît |
| 1.5 | Se déconnecter, puis se reconnecter | Retour sur l'accueil |
| 1.6 | Connexion → « Mot de passe oublié ? » | Message neutre ; e-mail reçu ; le lien ouvre l'écran « Nouveau mot de passe » |

## 2. Clubs (comptes A et B)

| # | Action | Résultat attendu |
| --- | --- | --- |
| 2.1 | A : Clubs → Créer un club public, en adhésion libre | Fiche du club : A est « Propriétaire » |
| 2.2 | B : Clubs → Découvrir → rejoindre ce club | « Bienvenue dans le club ! » ; le compteur passe à 2 |
| 2.3 | A : créer un club **privé, sur approbation** | — |
| 2.4 | B : demander à rejoindre ce club | « Demande en attente » ; B ne voit pas la liste des membres |
| 2.5 | A : approuver la demande dans la fiche du club | B devient membre et voit les membres |
| 2.6 | A : créer un club **privé, masqué, sur invitation**, puis inviter B par son pseudonyme | B voit l'invitation dans « Mes clubs » et peut l'accepter |
| 2.7 | A : nommer B administrateur, puis Modifier le club → Logo et couverture | Les images apparaissent dans la liste et sur la fiche |
| 2.8 | B (administrateur) : essayer de changer la visibilité du club | Refusé : seul le propriétaire peut le faire |

## 3. Balades (comptes A et B)

| # | Action | Résultat attendu |
| --- | --- | --- |
| 3.1 | A : Balades → Organiser, sur approbation, 5 participants maximum → Publier | Fiche : « Vous organisez cette balade » ; boutons Verrouiller, Démarrer, Annuler |
| 3.2 | B : trouver la balade dans « À venir » et demander à participer | « Demande en attente » |
| 3.3 | A : **Verrouiller**, puis essayer d'approuver B | Refusé : « inscriptions fermées » |
| 3.4 | A : Déverrouiller, puis approuver B | B apparaît dans les participants |
| 3.5 | A : Démarrer, puis Verrouiller pendant la balade | Statut « En cours · inscriptions fermées » |
| 3.6 | A : Terminer | « Terminée » ; plus aucune action possible |
| 3.7 | A : créer une balade à Lubumbashi avec le fuseau « Heure de Lubumbashi » | L'heure affichée est celle de Lubumbashi |
| 3.8 | A : retirer B d'une balade | B voit « L'organisateur vous a retiré » et ne peut pas revenir |
| 3.9 | Fiche d'un club dont on est admin → Organiser une balade du club, réservée aux membres | Visible pour les membres du club seulement |

## 4. Confidentialité et suppression de compte

| # | Action | Résultat attendu |
| --- | --- | --- |
| 4.1 | B : Profil → Confidentialité → désactiver « Profil visible par tous » | Un compte C sans club commun ne trouve plus B par son pseudonyme |
| 4.2 | B : désactiver « Accepter les invitations aux balades » | Si A invite B : « Ce motard n'accepte pas les invitations » |
| 4.3 | A (propriétaire d'un club avec des membres) : Supprimer mon compte | Refusé avec explication : il faut d'abord transférer le club |
| 4.4 | Compte de test sans club actif : Supprimer mon compte, en tapant SUPPRIMER | Compte supprimé ; retour à l'écran de connexion |

## Signaler un problème

Pour chaque anomalie, note :
- le **numéro du scénario** (par exemple 3.3) ;
- ce que tu as fait ;
- ce que tu attendais et ce qui s'est passé ;
- si possible, une capture d'écran.

Je peux aussi consulter les journaux Supabase du projet pour diagnostiquer.
