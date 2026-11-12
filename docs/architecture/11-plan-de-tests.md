# Partie 11 — Plan de tests

## Niveaux de test

| Niveau | Outil | Ce qu'il couvre | Exécution |
| --- | --- | --- | --- |
| Unitaire Dart | `flutter test` | Règles pures : horaires, expiration, conversion, curseurs, temporisation | CI à chaque commit |
| Widgets | `flutter test` | Composants, états (vide, erreur, hors ligne), absence de débordement à 360 dp et en grande police | CI |
| Intégration mobile | `integration_test` + Supabase local | Synchronisation, file d'attente, authentification | CI (émulateur) ou manuel |
| SQL | Tests dans `supabase/tests/` | RLS, contraintes, fonctions, déclencheurs | CI (Supabase local) |
| Edge Functions | Tests Deno | Notification de paiement, traitement d'image | CI |
| Back-office | Tests de composants + parcours dans un navigateur | Formulaires, droits | CI |
| Manuel | Grille de recette | Appareils réels, réseau réel de Kinshasa | Avant chaque validation de mission |

## Scénarios exigés par le cahier des charges

| # | Scénario | Type | Résultat attendu |
| --- | --- | --- | --- |
| T01 | Ouverture sans Internet, base vide | Widget + manuel | Coquille affichée, état « aucune donnée synchronisée », pas d'écran blanc |
| T02 | Ouverture sans Internet, base remplie | Intégration + manuel | Contenu local affiché, bandeau hors ligne |
| T03 | Coupure pendant un lot de synchronisation | Unitaire + intégration | Lot annulé proprement, reprise au même curseur, aucune ligne à moitié écrite |
| T04 | Retour du réseau | Intégration | Synchronisation sans bloquer la navigation ; listes mises à jour |
| T05 | Fiche modifiée côté serveur | Intégration | Nouvelle version visible après synchronisation ; fiche dépubliée retirée |
| T06 | Wi-Fi sans Internet | Unitaire + manuel | État « serveur injoignable », pas « en ligne » |
| T07 | Promotion expirée | Unitaire (horloge simulée) + SQL | Absente des offres actives, en ligne comme hors ligne |
| T08 | Événement terminé | Unitaire + SQL | Absent de « à venir », toujours présent en base |
| T09 | Horaires traversant minuit | Unitaire Dart et SQL, même jeu de cas | Ouvert à 01 h 30 le samedi si le vendredi ferme à 03 h ; fermeture exceptionnelle prioritaire |
| T10 | Échec de chargement d'une image | Widget | Image de remplacement, nouvelle tentative limitée, pas d'erreur visible |
| T11 | Proximité sans autorisation de localisation | Widget + manuel | Tri par commune proposé, aucun blocage, aucune relance répétée |
| T12 | Connexion et déconnexion | Intégration | Session créée ; après déconnexion, aucune donnée personnelle locale |
| T13 | Accès à un établissement non autorisé | SQL + appel direct à l'API | Lecture de brouillon et écriture refusées |
| T14 | Expiration d'un abonnement Premium | SQL (horloge simulée) | Droits retirés à l'échéance, contenus suspendus, rien de supprimé |
| T15 | Paiement signalé deux fois | SQL + Edge Function | Un seul effet ; seconde notification ignorée |
| T16 | Paiement refusé | SQL + Edge Function | Abonnement inchangé, facture non payée, nouvel essai possible |
| T17 | Publication par un compte gratuit | SQL + appel direct | Refus côté serveur avec motif |
| T18 | Isolation entre deux établissements | SQL | Aucun accès croisé sur fiches, brouillons, statistiques, factures |

## Scénarios complémentaires

| # | Scénario | Type |
| --- | --- | --- |
| T19 | Favori ajouté hors ligne puis synchronisé, sans doublon après rejeu | Intégration |
| T20 | Avis modifié sur deux appareils | Intégration |
| T21 | Deux écritures concurrentes autour du curseur de synchronisation | SQL |
| T22 | Fichier non-image ou trop lourd envoyé comme photo | Edge Function |
| T23 | Montant de paiement différent de la facture | Edge Function |
| T24 | Conversion USD ↔ CDF : arrondi et mention « estimation » | Unitaire + widget |
| T25 | Deux campagnes du même annonceur sur un même écran | SQL |
| T26 | Table sans RLS | SQL (test générique) |
| T27 | Horloge du téléphone déréglée | Unitaire |
| T28 | Noms très longs, textes sans espace, absence de photo | Widget (skill `break-ui`) |
| T29 | Application trop ancienne face à un schéma plus récent | Intégration |
| T30 | Restauration d'une sauvegarde sur un projet vierge | Manuel |

## Tests de sécurité

- Pour chaque table : matrice rôle × opération vérifiée par tests SQL (anonyme, inscrit, membre d'un autre
  établissement, membre, modérateur, administrateur).
- Tentatives d'élévation : modification de `status`, de `verification_status`, d'un rôle, d'un abonnement, par
  appel direct.
- Recherche de secrets dans le dépôt et dans l'APK (aucune clé `service_role`).
- Conseillers de sécurité Supabase sans alerte bloquante.
- Limites de débit : connexion, avis, signalements, statistiques.

## Objectifs de performance (cibles à valider sur appareils réels)

Appareil de référence proposé : Android d'entrée de gamme, 2 Go de mémoire, Android 10 ; réseau 3G bridé
(environ 400 kbit/s, latence 400 ms). Appareil exact à confirmer selon ce qui est courant à Kinshasa.

| Mesure | Cible |
| --- | --- |
| Démarrage à froid jusqu'au premier écran utile, base locale remplie | ≤ 3 s |
| Affichage d'une fiche depuis la liste | ≤ 500 ms |
| Recherche locale par nom | ≤ 300 ms |
| Fluidité du défilement des listes | ≥ 90 % des images sous 16 ms |
| Mémoire en usage courant | ≤ 250 Mo |
| Taille de l'APK par architecture | ≤ 35 Mo |
| Première synchronisation, hors images | ≤ 1,5 Mo transférés |
| Synchronisation incrémentale quotidienne typique | ≤ 100 ko |
| Données d'une session de 5 minutes, images comprises | ≤ 3 Mo |
| Vignette de liste | ≤ 30 ko |
| Requête de proximité côté serveur (95ᵉ centile) | ≤ 200 ms |

Ces chiffres sont des objectifs de conception, pas des mesures. Ils seront confirmés ou révisés à la Mission 03.

## Critères de sortie du MVP

1. Scénarios T01 à T18 réussis, avec preuve (journal de CI ou grille de recette signée).
2. Aucun défaut bloquant ou majeur ouvert.
3. `flutter analyze` sans erreur ; tests automatisés verts sur la branche de publication.
4. Objectifs de performance atteints sur l'appareil de référence, ou écarts acceptés par écrit.
5. Aucune alerte de sécurité bloquante ; RLS vérifié sur toutes les tables.
6. Restauration de sauvegarde réussie une fois.
7. Politique de confidentialité et conditions d'utilisation publiées ; suppression de compte fonctionnelle.
8. Un établissement pilote a parcouru le cycle complet : revendication, vérification, abonnement, publication.

## Règle de compte rendu

Chaque rapport de mission distingue : tests **exécutés** (commande et résultat), tests **non exécutés** (raison
précise et ce qu'il faudrait), tests **manuels à faire par vous**. Un test non exécuté n'est jamais présenté comme
réussi.
