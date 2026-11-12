# Dossier d'architecture — Kin Guide

> **Statut : proposé, en attente de validation.** Rédigé le 2026-11-12 à partir du
> [cahier des charges](../00-cahier-des-charges.md). Rien dans ce dossier n'est encore implémenté.
> Les décisions marquées « à valider » sont regroupées dans [12-decisions-a-valider.md](12-decisions-a-valider.md).

| Partie | Fichier | Contenu |
| --- | --- | --- |
| 1 | [01-comprehension.md](01-comprehension.md) | Produit, utilisateurs, objectifs, contraintes |
| 2 | [02-analyse-recommandations.md](02-analyse-recommandations.md) | Lacunes, risques, améliorations |
| 3 | [03-stack.md](03-stack.md) | Technologies retenues et comparaisons |
| 4 | [04-architecture.md](04-architecture.md) | Composants, échanges, structure du dépôt |
| 5 | [05-base-de-donnees.md](05-base-de-donnees.md) | Schéma relationnel, contraintes, index, RLS |
| 6 | [06-offline-first.md](06-offline-first.md) | Cache local, synchronisation, erreurs |
| 7 | [07-securite.md](07-securite.md) | Authentification, permissions, anti-fraude |
| 8 | [08-monetisation.md](08-monetisation.md) | Abonnements, paiements, campagnes |
| 9 | [09-interfaces.md](09-interfaces.md) | Arborescence des écrans et parcours |
| 10 | [10-mvp-feuille-de-route.md](10-mvp-feuille-de-route.md) | MVP, V2, missions numérotées |
| 11 | [11-plan-de-tests.md](11-plan-de-tests.md) | Scénarios de recette, critères de sortie |
| 12 | [12-decisions-a-valider.md](12-decisions-a-valider.md) | Décisions qui demandent votre intervention |

## Conventions de lecture

- **Obligatoire** : exigé par le cahier des charges. **Suggestion** : proposition de l'équipe, à accepter ou refuser.
- **À vérifier** : information dépendant d'un fournisseur externe (tarif, disponibilité en RDC) qui n'a pas pu être
  confirmée sur une source officielle. Aucun tarif de ce dossier ne doit être tenu pour acquis.
- Une décision validée devient un ADR dans `docs/adr/`.
