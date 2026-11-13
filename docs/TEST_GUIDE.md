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

## 5. Mode Convoi (deux téléphones, à l'extérieur)

Préparer : A organise une balade, B la rejoint (confirmé), A la **démarre**.

| # | Action | Résultat attendu |
| --- | --- | --- |
| 5.1 | B : fiche de la balade → « Ouvrir le mode Convoi » | Carte et liste des participants ; « Votre position n'est pas partagée » |
| 5.2 | B : « Partager ma position » | Le téléphone demande l'autorisation ; ensuite « Dernier envoi à HH:MM » |
| 5.3 | A : ouvrir le mode Convoi | B apparaît sur la carte et dans la liste (« en direct ») |
| 5.4 | A : fiche → menu à côté de B → « Nommer chef de convoi » | B affiché « chef de convoi » chez A et B |
| 5.5 | B : « Arrêter le partage » | B disparaît de la carte de A |
| 5.6 | A : couper le partage de son côté puis s'éloigner de plus de 2 km de B (chef) avec partage actif | Alerte « peut-être séparé » sur A |
| 5.7 | B : passer en mode avion 4 min | Chez A : « Position ancienne » pour B |
| 5.8 | A : terminer la balade | L'envoi de B s'arrête ; plus de carte pour personne |
| 5.9 | Compte C non inscrit : ouvrir le lien de la balade | Pas de bouton Convoi, aucune position visible |

## 6. SOS (deux téléphones)

Préparer : A organise une balade, B la rejoint, A la **démarre**. Les deux gardent l'application ouverte.

| # | Action | Résultat attendu |
| --- | --- | --- |
| 6.1 | B : fiche de la balade → bouton rouge « SOS et assistance » | Avertissement « pas un service de secours », bouton « Appeler le 112 », 4 choix |
| 6.2 | B : « Panne » → « Envoyer l'alerte » | « Alerte transmise à HH:MM » ; « Pas encore d'accusé de réception » |
| 6.3 | A (sur n'importe quel écran) | Bandeau rouge « SOS : Panne dans votre balade », son et vibration |
| 6.4 | A : « Voir » → « Voir sur la carte » | La position de B s'ouvre dans OpenStreetMap |
| 6.5 | A : « J'ai vu, je m'en occupe » | Chez B : « Vu par : A » ; le bandeau de A disparaît |
| 6.6 | B : « Problème résolu » | L'alerte disparaît chez A |
| 6.7 | B : activer le **mode avion**, puis « Accident » → Envoyer | « ALERTE NON TRANSMISE » en rouge ; jamais « transmise » |
| 6.8 | B : désactiver le mode avion → « Réessayer l'envoi » | « Alerte transmise » ; A ne reçoit qu'**une** alerte. Puis « Annuler (fausse alerte) » |
| 6.9 | B : Paramètres → Numéro d'appel d'urgence → saisir un autre numéro | L'écran SOS propose « Appeler le <nouveau numéro> » ; le composeur s'ouvre (l'appel n'est pas lancé automatiquement) |
| 6.10 | Compte C non inscrit : ouvrir la balade | Pas de bouton SOS ; aucune alerte visible |

## 7. Communauté et messagerie (un téléphone suffit, deux comptes)

Astuce : avec un seul téléphone, déconnectez-vous et reconnectez-vous avec le compte B entre les étapes.

| # | Action | Résultat attendu |
| --- | --- | --- |
| 7.1 | A : Accueil → « Publier » → texte + 2 photos → Publier | « Publication partagée » ; elle apparaît en haut du fil avec ses photos |
| 7.2 | A : mode avion → nouvelle publication → Publier | « Publication NON envoyée » ; rien dans le fil. Mode avion désactivé → Publier : une seule publication |
| 7.3 | B : réagir « En feu », puis commenter la publication de A | Compteurs mis à jour ; commentaire visible |
| 7.4 | B : menu de la publication → Signaler → « Spam » | « Signalement envoyé. Merci. » |
| 7.5 | Fiche d'un club dont A est membre → « Publier dans le club » (Membres du club) | Visible par les membres ; invisible pour un compte non membre |
| 7.6 | B : touche le nom de A → profil → « Message » → écrire | Conversation ouverte ; chez A : badge sur l'onglet Messages |
| 7.7 | B : mode avion → envoyer un message | « Non envoyé — touchez pour réessayer » ; après reconnexion, toucher : envoyé une seule fois |
| 7.8 | A : Messages → « Nouveau message » → Groupe → ajouter B par pseudonyme → Créer | Groupe créé ; B le voit dans ses messages |
| 7.9 | Fiche d'une balade où A et B sont inscrits → « Discussion de la balade » | Les deux participants écrivent dans la même discussion |
| 7.10 | B : profil de A → Bloquer | Les publications de A disparaissent chez B ; plus de message possible. Profil → Motards bloqués → Débloquer |

## Signaler un problème

Pour chaque anomalie, note :
- le **numéro du scénario** (par exemple 3.3) ;
- ce que tu as fait ;
- ce que tu attendais et ce qui s'est passé ;
- si possible, une capture d'écran.

Je peux aussi consulter les journaux Supabase du projet pour diagnostiquer.
