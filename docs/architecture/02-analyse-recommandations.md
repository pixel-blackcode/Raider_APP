# Partie 2 — Analyse et recommandations

## Lacunes du cahier des charges

| # | Lacune | Pourquoi c'est un problème | Proposition | Nature |
| --- | --- | --- | --- | --- |
| L1 | Origine du contenu initial non définie | Une application vide au lancement n'a aucune valeur | Mission dédiée à l'import et à la saisie par l'équipe ; outil d'import dans `tools/` ; champ `source` sur chaque fiche | Obligatoire en pratique |
| L2 | Cadre légal des données personnelles non cité | Avis, comptes, pièces de vérification sont des données personnelles | Politique de confidentialité, consentement, suppression de compte, durée de conservation ; cadre légal congolais **à vérifier avec un juriste** | Obligatoire avant production |
| L3 | Preuve de visite non définie | « Avis vérifié » sans règle = promesse non tenable | MVP : aucun avis n'est marqué vérifié. V2 : code ou QR affiché par l'établissement | Suggestion |
| L4 | Critères de vérification d'un établissement absents | Risque de revendication abusive | Procédure : pièce justificative + appel sur le numéro public de la fiche + décision tracée | Obligatoire |
| L5 | « Pertinence » du tri non définie | Résultats incohérents | Score = correspondance textuelle + distance + note + fraîcheur ; le sponsorisé est un bloc séparé, jamais mélangé au score | Suggestion |
| L6 | Langues de recherche | Les noms de lieux mêlent français, lingala et orthographes variables | Recherche tolérante aux accents et aux fautes (`unaccent` + `pg_trgm`) ; champ « autres noms » | Suggestion |
| L7 | Publication sur les stores | Comptes Google Play et Apple, fiches, politique de confidentialité hébergée | Listé dans les actions humaines (Partie 12) | Obligatoire |
| L8 | Notifications « ultérieurement » sans cadre | Dépendance Firebase Cloud Messaging | Reporté en V2 ; consentement stocké dès le MVP | Suggestion |
| L9 | Pas de règle sur la fraîcheur des fiches | Horaires et contacts périmés nuisent à la confiance | Date de dernière confirmation visible, relance du gérant, signalement « information erronée » | Suggestion |
| L10 | Factures : mentions légales et numérotation | Obligations fiscales locales inconnues | Numérotation séquentielle sans trou dès le MVP ; mentions **à vérifier avec un comptable** | Obligatoire avant facturation |

## Risques

| Risque | Gravité | Parade |
| --- | --- | --- |
| Aucun prestataire de paiement validé en RDC | Élevée | Paiement manuel validé par l'administrateur au MVP ; interface `PaymentProvider` pour brancher un agrégateur ensuite |
| SMS d'authentification non fiables vers +243 | Moyenne | E-mail et Google au MVP ; téléphone seulement après test réel d'un fournisseur |
| Qualité inégale d'OpenStreetMap hors du centre | Moyenne | La carte est un complément : la liste fonctionne sans elle ; le point GPS vient de la fiche, pas du géocodage |
| Complexité de l'offline-first | Élevée | Données publiques en lecture seule côté mobile ; file d'attente limitée aux favoris, lieux visités et avis |
| Palier gratuit Supabase (pause après inactivité, pas de sauvegarde garantie) | Élevée en production | Gratuit pour le développement uniquement ; plan payant avant l'ouverture au public — conditions **à vérifier** |
| Faux clics et statistiques gonflées | Moyenne | Dédoublonnage par appareil et par fenêtre de temps, agrégats journaliers, pas de données personnelles |
| Revendication abusive d'une fiche | Élevée | Vérification manuelle, journal d'audit, révocation possible |
| Un seul développeur, plusieurs surfaces | Moyenne | Un seul back-office web pour gérants et administrateurs ; pas de serveur applicatif à maintenir |
| Dépôt partagé avec Rider Group | Moyenne | Dépôt dédié recommandé (décision D-01) |

## Améliorations proposées (toutes des suggestions)

1. **Niveau de précision du point GPS** (`exact`, `approximate`, `neighborhood`) affiché sur la fiche, pour ne pas
   promettre une adresse exacte.
2. **Bouton WhatsApp** avec message prérempli, compté comme clic de contact.
3. **Itinéraire délégué** à l'application de navigation du téléphone : aucun coût d'API, fonctionne avec ce que
   l'utilisateur a déjà installé.
4. **Mode économie de données** : réglage qui bloque le chargement des images en grand format hors Wi-Fi.
5. **Partage d'une fiche** par lien (WhatsApp), avec lien profond vers l'application.
6. **Un seul back-office web** dont les menus dépendent du rôle, plutôt que deux applications.
7. **Droits calculés par forfait** (`plan_entitlements`) plutôt que des `if premium` dispersés : changer une offre
   devient une modification de données.

## Ce qui reste obligatoire sans discussion

Offline-first, interface en français, RLS et contrôle serveur, absence de secret côté client, étiquette
« Sponsorisé », vérification indépendante du paiement, montants sans arrondi flottant, paiement jamais validé par
le client, événements et promotions expirés retirés des listes actives, validation de chaque mission.
