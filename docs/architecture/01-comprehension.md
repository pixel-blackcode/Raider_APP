# Partie 1 — Compréhension du projet

## Le produit

Kin Guide est un guide urbain mobile pour Kinshasa. Il répond à trois questions : « où aller ? » (établissements et
lieux), « que se passe-t-il ? » (événements, rubrique « Quoi de neuf à Kin ? ») et « où sont les bonnes affaires ? »
(promotions, rubrique « Bons plans à Kinshasa »).

C'est aussi une plateforme commerciale : les établissements y gèrent leur fiche, publient événements et promotions,
s'abonnent à une offre payante et achètent de la visibilité sponsorisée.

Trois surfaces logicielles en découlent :

1. **L'application mobile** grand public (Android d'abord, iOS ensuite).
2. **L'espace professionnel** (gérants), utilisable sur ordinateur et sur téléphone.
3. **L'administration** de la plateforme.

## Les utilisateurs

| Profil | Ce qu'il fait | Ce qui compte pour lui |
| --- | --- | --- |
| Visiteur non connecté | Parcourt, cherche, consulte fiches, événements, promotions, carte | Aucune inscription forcée, rapidité, peu de données consommées |
| Utilisateur inscrit | Favoris, avis et notes, lieux visités (déclarés volontairement), profil | Vie privée : localisation facultative, pas d'historique de position |
| Gérant d'établissement | Gère une ou plusieurs fiches, publie, suit abonnement et statistiques, achète des campagnes | Simplicité sur téléphone, droits clairs, collaborateurs possibles |
| Administrateur | Vérifie, modère, gère abonnements, paiements, campagnes, référentiels, audit | Traçabilité, contrôle, vue sur les revenus |

## Objectifs commerciaux

- Revenus récurrents : abonnements professionnels mensuels et annuels (Gratuit, Pro/Premium, période d'essai).
- Revenus ponctuels : campagnes sponsorisées (fiche, promotion ou événement) sur des emplacements définis.
- Deux principes non négociables : la **vérification d'un établissement est indépendante du paiement**, et un contenu
  payé est toujours étiqueté « Sponsorisé », distinct des « Coups de cœur » éditoriaux.

## Contraintes principales

| Contrainte | Conséquence sur la conception |
| --- | --- |
| Réseau lent ou instable, données mobiles chères | Offline-first, synchronisation incrémentale, images en plusieurs tailles, pas de téléchargement de masse |
| Parc Android, souvent d'entrée de gamme | Mémoire et taille d'APK surveillées, listes paginées, cache d'images borné |
| Interface entièrement en français | Fichiers ARB, aucun texte codé en dur |
| USD et CDF | Montants en unité mineure, devise d'origine conservée, taux historisés, conversion affichée comme estimation |
| WhatsApp et Mobile Money omniprésents | Contact WhatsApp sur les fiches ; paiement Mobile Money prévu, prestataire à vérifier |
| Adresses imprécises | Adresse descriptive + commune + quartier + point GPS avec niveau de précision et correction possible |
| Fuseau `Africa/Kinshasa` (UTC+1, sans heure d'été) | Horaires en heure locale, instants en `timestamptz` |
| Coûts de lancement limités | Services gérés avec palier gratuit, peu de composants, pas de serveur à administrer |

## Hypothèses retenues (à corriger si fausses)

1. Une seule ville au lancement (Kinshasa), mais le modèle de données porte une notion de ville pour en ajouter.
2. Le contenu initial (fiches) est saisi ou importé par l'équipe avant l'arrivée des gérants : une fiche peut exister
   sans propriétaire.
3. Le volume de départ est modeste (quelques centaines à quelques milliers de fiches), ce qui autorise une
   synchronisation locale complète des données textuelles de la ville.
4. Pendant la phase pilote, les paiements sont validés manuellement par un administrateur.
5. La billetterie n'est pas dans le périmètre, mais le schéma ne doit pas l'empêcher.
