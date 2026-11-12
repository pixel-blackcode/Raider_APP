# Kin Guide — instructions pour Claude Code

## Produit

Kin Guide est une application mobile de guide urbain pour Kinshasa (RDC), Android en priorité et compatible iOS.
Elle permet de découvrir établissements et lieux (sites touristiques, restaurants, bars et lounges, supermarchés), avec recherche, carte et géolocalisation facultative.
Elle publie les événements (« Quoi de neuf à Kin ? ») et les promotions (« Bons plans à Kinshasa ») des établissements, avec favoris, notes et avis.
Elle doit rester utilisable hors ligne (offline-first) et sobre en données mobiles.
Elle se finance par les abonnements professionnels et les campagnes sponsorisées, gérés depuis un espace gérant et un back-office d'administration.

Référence complète : [docs/00-cahier-des-charges.md](docs/00-cahier-des-charges.md).

> **Attention — dépôt partagé.** Ce dépôt contenait déjà, avant Kin Guide, le code de l'application « Rider Group »
> (`lib/`, `android/`, `ios/`, `supabase/`, `test/`, `README.md`, `docs/*.md` en majuscules). Ce code n'appartient pas à
> Kin Guide : ne pas le supprimer, ne pas le modifier et ne pas s'en servir comme base sans décision écrite du
> propriétaire du projet.

## Langue

- Code en anglais : noms (fichiers, classes, variables, tables, colonnes) et commentaires techniques.
- Interface utilisateur et documentation en français.

## Règles de travail

- Une mission à la fois.
- Mode plan avant toute modification importante.
- Ne jamais commencer la mission suivante sans validation écrite du propriétaire du projet.
- Ne jamais prétendre qu'un test a été exécuté ou qu'un déploiement a eu lieu si ce n'est pas vrai.
- Signaler précisément les tests impossibles à exécuter (lequel, pourquoi, ce qu'il faudrait pour l'exécuter).

## Règles Git

- Une branche par mission : `mission/NN-nom-court`.
- Commits conventionnels en anglais (`feat:`, `fix:`, `docs:`, `test:`, `chore:`…).
- Jamais de push forcé.
- Jamais de secret dans le dépôt (`.env`, clés, fichiers de signature).

## Sécurité

- Aucune clé `service_role` ni aucun secret dans le code client.
- Permissions appliquées en base (RLS) et côté serveur, jamais seulement dans l'interface.
- MCP Supabase connecté uniquement au projet de développement.

## Conventions métier

- Fuseau horaire : `Africa/Kinshasa` (UTC+1, sans heure d'été).
- Montants : entiers dans la plus petite unité de la devise.
- Devises : USD et CDF.
- Dates : `timestamptz`.
- Horaires d'ouverture : en heure locale.

## Documentation

| Emplacement | Contenu |
| --- | --- |
| `docs/00-cahier-des-charges.md` | Cahier des charges d'origine (ne pas modifier) |
| `docs/architecture/` | Dossier d'architecture |
| `docs/adr/` | Décisions d'architecture (modèle : `ADR-000-modele.md`) |
| `docs/missions/` | Rapports de mission |
| `docs/JOURNAL.md` | Journal des sessions |

## Skills à utiliser

| Type de tâche | Skill(s) |
| --- | --- |
| Design (conception, refonte, critique) | `impeccable` |
| Finition UI | `emil-design-eng` |
| Mouvement et animations | `apple-design` |
| Test de robustesse UI | `break-ui` |
| Back-office web | `frontend-design`, `pick-ui-library`, `mobile-native` |
| Données (collecte, tableurs) | `apify-ultimate-scraper`, `xlsx` |
| Factures | `pdf` |
| Recherche fournisseurs | `deep-research` |

Si une skill de cette table est absente de la session, le signaler au lieu de la remplacer silencieusement.
