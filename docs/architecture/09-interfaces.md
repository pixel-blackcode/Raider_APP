# Partie 9 — Architecture des interfaces

> Le langage visuel (couleurs, typographie, composants, états) sera défini dans `DESIGN.md` à la Mission 01 avec la
> skill `impeccable`. Ce document fixe l'arborescence et les parcours.

## Application mobile

Barre inférieure à cinq onglets, état conservé par onglet :

```
Accueil
├── Recherche (champ en tête d'écran, accessible partout)
├── À la une [Sponsorisé]
├── Catégories
├── À proximité (si localisation accordée) / Par commune (sinon)
├── Quoi de neuf à Kin ? (aperçu) ──► Événement
├── Bons plans à Kinshasa (aperçu) ──► Promotion
└── Coups de cœur ──► Établissement

Explorer
├── Liste des établissements
│   ├── Filtres : catégorie, commune, quartier, ouvert maintenant, note
│   └── Tri : pertinence, distance, note
└── Établissement
    ├── Galerie
    ├── Statut (ouvert, ferme à…, fermeture exceptionnelle), horaires
    ├── Adresse, commune, quartier, précision du point ──► Itinéraire (application externe)
    ├── Contacts : appel, WhatsApp, réseaux, site
    ├── Menus et tarifs
    ├── Événements et promotions du lieu
    ├── Avis ──► Écrire un avis (connexion requise)
    └── Actions : favori, partager, marquer comme visité, signaler, « C'est mon établissement »

Carte
├── Marqueurs (regroupés), mêmes filtres qu'Explorer
├── Fiche résumée en bas d'écran ──► Établissement
└── Bascule Liste / Carte

Quoi de neuf
├── Segment : Événements | Bons plans
├── Filtres : aujourd'hui, ce week-end, catégorie, commune
├── Événement ──► Établissement, contact, réservation
└── Promotion ──► Établissement, conditions

Profil
├── Non connecté : Se connecter / Créer un compte
├── Favoris
├── Lieux visités
├── Mes avis
├── Espace professionnel (ouvre le back-office dans le navigateur)
├── Paramètres : économie de données, cache, localisation, notifications (V2)
├── Confidentialité, conditions, à propos
└── Déconnexion, suppression du compte
```

Les favoris sont dans l'onglet Profil plutôt que dans la barre, conformément aux cinq onglets que vous avez définis
pour la Mission 01 ; un raccourci « Favoris » figure aussi sur l'Accueil pour un utilisateur connecté.

### Parcours du visiteur

1. Ouvre l'application : Accueil affiché depuis la base locale, synchronisation en arrière-plan.
2. Touche une catégorie ou cherche un nom : liste filtrée, calculée localement.
3. Ouvre une fiche : appelle, écrit sur WhatsApp ou lance l'itinéraire. Aucune connexion demandée.
4. Touche « Favori » : feuille « Connectez-vous pour enregistrer ce lieu », avec retour à la fiche après connexion.

### Parcours de l'utilisateur inscrit

1. Connexion (e-mail ou Google), retour à l'écran d'origine.
2. Favoris, lieux visités et avis fonctionnent hors ligne et se synchronisent ensuite ; un avis non envoyé est
   marqué « en attente ».
3. Localisation : demandée seulement quand il touche « À proximité » ou le bouton de position, avec explication.
   En cas de refus : tri par commune, aucune relance insistante.

### États communs à tous les écrans

| État | Présentation |
| --- | --- |
| Chargement | Squelettes à la forme du contenu, jamais d'indicateur seul au centre |
| Aucune donnée synchronisée | Illustration sobre, une phrase, bouton « Réessayer » |
| Aucun résultat | Message + proposition d'élargir les filtres |
| Hors ligne / serveur injoignable | Bandeau discret, non bloquant ; contenu local affiché |
| Données anciennes | Mention « Mis à jour il y a … » |
| Erreur d'action | Message court, action « Réessayer », jamais de code technique |
| Image indisponible | Aplat de couleur + icône de catégorie |

### Composants réutilisables

`AppButton`, `PlaceCard` (liste et compacte), `EventCard`, `DealCard`, `FilterChip`, `SearchField`, `OfflineBanner`,
`EmptyState`, `ErrorState`, `SkeletonLoader`, `OpenStatusBadge`, `SponsoredBadge`, `VerifiedBadge`, `RatingStars`,
`PriceText` (devise d'origine + estimation), `AppImage` (tailles, remplacement, reprise), `SectionHeader`,
`ContactActions`, `LoginPromptSheet`.

Contraintes : cible tactile d'au moins 48 dp, contraste AA, textes qui supportent l'agrandissement du système,
écrans utilisables à 360 dp de large, robustesse aux noms longs (vérifiée avec la skill `break-ui`).

## Back-office web (gérants et administrateurs)

Une seule application ; le menu dépend du rôle. Mise en page à une colonne sur téléphone, barre latérale sur
ordinateur.

### Espace professionnel

```
Connexion professionnelle
Tableau de bord (consultations, clics, abonnement, tâches en attente)
Mes établissements
├── Revendiquer ou proposer un établissement ──► Suivi de la vérification
└── Établissement
    ├── Fiche : informations, contacts, emplacement sur la carte
    ├── Horaires et fermetures exceptionnelles
    ├── Photos
    ├── Menus et tarifs
    ├── Événements : brouillon ──► programmation ──► publication
    ├── Promotions : brouillon ──► programmation ──► publication
    ├── Statistiques
    ├── Collaborateurs
    └── Campagnes sponsorisées
Abonnement (forfait, échéance, changement)
Paiements et factures
```

Parcours du gérant : crée un compte → revendique sa fiche et joint une pièce → attend la décision (statut visible) →
complète la fiche → choisit un forfait et déclare son paiement → publie événements et promotions dans la limite de
ses droits → consulte ses statistiques. Un bouton désactivé par manque de droit explique pourquoi et renvoie vers
l'écran Abonnement ; le refus réel vient du serveur.

### Administration

```
Tableau de bord général (fiches, comptes, revenus, files d'attente)
Établissements
├── Liste, création, import, fusion de doublons
└── Demandes de vérification ──► Dossier ──► Décision motivée
Utilisateurs et professionnels ──► Suspension
Modération
├── Signalements
├── Contenus en attente (événements, promotions, photos)
└── Avis
Catégories et zones géographiques
Abonnements ──► Détail, prolongation, suspension
Transactions ──► Paiements à valider ──► Validation ou refus
Campagnes publicitaires ──► Revue, emplacements, tarifs
Coups de cœur
Statistiques
Paramètres (taux de change, délais, plafonds)
Audit et sécurité
```

Parcours de l'administrateur : traite chaque matin trois files — vérifications, paiements à valider, signalements —
chacune avec un compteur sur le tableau de bord. Toute décision demande un motif et laisse une trace d'audit.
