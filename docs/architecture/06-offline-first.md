# Partie 6 — Stratégie offline-first

## Principe

**L'interface lit toujours la base locale (Drift), jamais le réseau.** Le réseau ne sert qu'à mettre la base locale
à jour, en arrière-plan. Conséquences : aucun écran ne dépend d'une réponse serveur pour s'afficher, et le
comportement est le même en ligne et hors ligne.

## Ce qui est stocké sur le téléphone

| Donnée | Stockage local | Portée |
| --- | --- | --- |
| Référentiels (villes, communes, quartiers, catégories, devises, taux) | Complet | Toute la ville |
| Établissements (texte, coordonnées, horaires, contacts, note) | Complet | Toute la ville, fiches publiées |
| Événements à venir, promotions actives | Complet | Toute la ville |
| Menus et tarifs | À la demande | Fiches ouvertes ; conservés ensuite |
| Avis | À la demande, paginés | Fiches ouvertes |
| Favoris, lieux visités, mes avis | Complet | Utilisateur connecté |
| Images | Cache disque borné | Uniquement celles déjà affichées |
| Tuiles de carte | Cache du moteur de carte, borné | Zones déjà consultées |

Ordre de grandeur attendu : quelques milliers de fiches textuelles représentent quelques mégaoctets une fois
compressées. **À mesurer** avec les données réelles avant de figer la stratégie « catalogue complet » ; si le volume
dépasse le budget, on bascule sur une synchronisation par commune.

## Synchronisation descendante (serveur → téléphone)

1. Chaque table synchronisée porte `updated_at` (déclencheur) et `deleted_at` (suppression logique).
2. Le téléphone garde un curseur par table : (`updated_at`, `id`) de la dernière ligne reçue.
3. Appel `sync_pull(table, cursor, limit)` : lignes dont (`updated_at`,`id`) est supérieur au curseur, triées, par
   lots de 200. La réponse indique s'il reste des lignes.
4. Chaque lot est écrit dans Drift en une transaction (insertion ou remplacement). Une ligne avec `deleted_at`, ou
   devenue non publique, est supprimée localement : le serveur renvoie pour elle un simple marqueur de retrait, sans
   contenu.
5. Ordre des tables : référentiels, établissements, puis tables enfants, pour respecter les dépendances.

**Précaution sur le curseur.** Deux transactions concurrentes peuvent valider dans un ordre différent de leur
`updated_at` ; une ligne pourrait alors être sautée. Parade : chaque synchronisation repart 5 minutes avant le
curseur. Les écritures étant des remplacements idempotents, relire quelques lignes est sans effet. Un test SQL
couvre ce cas.

**Resynchronisation complète** : déclenchée si le serveur annonce une version de schéma supérieure, si le curseur a
plus de 30 jours, ou sur action de l'utilisateur (« Tout actualiser »).

## Durées de validité

| Donnée | Rafraîchie si plus ancienne que | Affichée comme « peut être ancienne » après |
| --- | --- | --- |
| Événements, promotions | 30 minutes | 6 heures |
| Établissements, horaires | 6 heures | 3 jours |
| Avis d'une fiche | 1 heure | 1 jour |
| Référentiels, taux de change | 24 heures | 7 jours (taux : date toujours affichée) |
| Paramètres publics | 24 heures | — |

Déclencheurs : ouverture de l'application, retour au premier plan, retour du serveur, tirer pour actualiser.
Pas de synchronisation périodique en arrière-plan au MVP (économie de batterie et de données).

Une donnée périmée reste **affichée**. Les promotions et événements sont filtrés localement par date : même sans
réseau depuis une semaine, une promotion expirée n'apparaît plus comme active.

## Synchronisation montante (téléphone → serveur)

File d'attente locale (`outbox`) pour les seules opérations autorisées hors ligne :

| Opération | Hors ligne | Conflit possible | Résolution |
| --- | --- | --- | --- |
| Ajouter ou retirer un favori | Oui | Deux appareils | Dernière action gagne ; opération idempotente |
| Marquer un lieu comme visité | Oui | Aucun | Insertion idempotente |
| Écrire ou modifier son avis | Oui, affiché « en attente d'envoi » | Avis modifié sur un autre appareil | Le serveur compare `updated_at` : la version la plus récente gagne ; l'autre est proposée à l'utilisateur |
| Signaler un contenu | Oui | Aucun | Insertion idempotente |
| Publication professionnelle, paiement, revendication | **Non** | — | Connexion requise, message clair |

Chaque entrée porte un identifiant généré sur le téléphone (clé d'idempotence), un nombre de tentatives et la date du
prochain essai. Une réponse définitive du serveur (refus de permission, établissement supprimé) retire l'entrée et
informe l'utilisateur ; une erreur temporaire la reprogramme.

## Réseau contre disponibilité du serveur

Trois états distincts, exposés à l'interface par un seul fournisseur d'état :

| État | Détection | Interface |
| --- | --- | --- |
| `offline` | Aucune interface réseau | Bandeau « Hors ligne » |
| `backendUnreachable` | Réseau présent, mais la requête légère de santé échoue ou dépasse 8 secondes | Bandeau « Serveur injoignable, données enregistrées affichées » |
| `online` | Dernière requête réussie | Rien ; discret « Mis à jour il y a … » dans les listes |

L'état « serveur injoignable » couvre le Wi-Fi sans Internet, le portail captif et la panne du backend.

## Reprises sur erreur

- Temporisation exponentielle avec aléa : 2 s, 4 s, 8 s… plafonnée à 5 minutes ; remise à zéro au retour du réseau.
- Délai maximal par requête : 15 secondes ; un lot échoué est repris au même curseur.
- Les erreurs de synchronisation ne produisent jamais de fenêtre bloquante.

## Limiter la consommation de données

- Compression gzip des réponses ; colonnes strictement nécessaires.
- Aucune image téléchargée à l'avance. Taille choisie selon l'affichage (vignette en liste, moyenne sur la fiche).
- Réglage « Économie de données » : vignettes seules hors Wi-Fi, grandes images sur appui.
- Statistiques envoyées par lots, au plus une fois par minute, et abandonnées au-delà de 24 heures.
- Suivi du volume échangé en mode développement pour vérifier les budgets (Partie 11).

## Nettoyage du cache

- Images : plafond de 150 Mo et 30 jours sans accès ; éviction des moins récemment utilisées.
- Événements terminés depuis plus de 7 jours et promotions expirées depuis plus de 7 jours : supprimés localement.
- Avis et menus de fiches non ouvertes depuis 30 jours : supprimés.
- Bouton « Vider le cache » dans les paramètres ; déconnexion = suppression des données personnelles locales.

## Première ouverture sans connexion

La base locale est vide. L'application affiche la coquille complète (barre inférieure, titres) et, dans chaque
onglet, l'état « Aucune donnée synchronisée » : explication en une phrase, bouton « Réessayer », et reprise
automatique dès que le serveur répond. Jamais d'écran blanc ni d'indicateur de chargement infini.

## Cartes hors ligne : limites

- Sans réseau, seules les tuiles déjà consultées s'affichent ; ailleurs, le fond est vide mais les marqueurs restent
  (leurs coordonnées sont en base locale). La vue Liste reste entièrement utilisable.
- Le téléchargement d'une carte de Kinshasa pour usage hors ligne est possible avec des données OpenStreetMap
  (licence ODbL : mention « © les contributeurs d'OpenStreetMap » obligatoire et visible). Proposé en V2.
- Les conditions de Google Maps et de Mapbox encadrent ou interdisent la mise en cache des tuiles : une raison de
  plus pour MapLibre + OSM. Les conditions exactes de l'hébergeur de tuiles retenu sont **à vérifier**.
- L'itinéraire est délégué à l'application de navigation du téléphone ; son fonctionnement hors ligne dépend d'elle.
