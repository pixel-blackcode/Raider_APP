# Journal des sessions — Kin Guide

Une entrée par session, la plus récente en haut : ce qui a été fait, ce qui reste, ce qui attend une validation.

## 2026-11-12 — Dossier d'architecture (proposé)

- Demande reçue : Mission 01. Constat : `03-stack.md`, `04-architecture.md` et `10-mvp-feuille-de-route.md` n'existaient pas. Le propriétaire a demandé de choisir la meilleure option : le dossier d'architecture a été rédigé d'abord.
- Créé : `docs/architecture/01` à `12` (compréhension, analyse, stack, architecture, base de données, offline-first, sécurité, monétisation, interfaces, feuille de route, plan de tests, décisions).
- Statut : **proposé, non validé**. Aucun code écrit, aucun test exécuté, rien de déployé.
- Vérifications web faites : prestataires de paiement en RDC, SMS Supabase, tarifs Supabase, synchronisation hors ligne. Aucune confirmation sur source officielle pour les tarifs ni pour la livraison des SMS vers +243 : points marqués « à vérifier ».
- Commit initial poussé sur `claude/fervent-pascal-7banbv` à la demande du propriétaire.
- En attente : réponses aux décisions D-01 à D-08 (`docs/architecture/12-decisions-a-valider.md`). D-01 (dépôt dédié ou non) bloque la Mission 01.
- Prochaine étape, après validation : plan de la Mission 01 (mode plan), puis exécution.

## 2026-11-12 — Initialisation de la documentation

- État des lieux : le dépôt contient déjà l'application Flutter « Rider Group » (200 fichiers suivis, 13 commits). Rien n'a été supprimé ni modifié dans ce code.
- Créé : `docs/00-cahier-des-charges.md`, `CLAUDE.md`, `docs/architecture/`, `docs/adr/ADR-000-modele.md`, `docs/missions/`, ce journal.
- `.gitignore` existant complété (Node, Supabase, clés) sans retirer de règle.
- Outils absents de l'environnement : `flutter`, `dart`, `supabase` CLI. Aucun test exécuté (aucun code Kin Guide).
- Aucun code d'application écrit. Aucun push vers un dépôt distant.
- À décider par le propriétaire : garder Kin Guide dans ce dépôt ou lui créer un dépôt dédié.
- Prochaine étape, après validation : dossier d'architecture (Parties 1 à 12 du cahier des charges).
