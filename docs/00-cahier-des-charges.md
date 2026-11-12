[   # PROMPT MAÎTRE — APPLICATION DE GUIDE URBAIN INTELLIGENT POUR KINSHASA

## 0. RÔLE ET MISSION

Agis comme une équipe technique senior composée des spécialistes suivants :

1. **Architecte logiciel senior** : responsable de l'architecture, de la robustesse et de l'évolutivité.
2. **Développeur Flutter senior** : spécialiste des applications mobiles Android/iOS performantes.
3. **Ingénieur backend** : expert en PostgreSQL, Supabase, PostGIS, API sécurisées et synchronisation de données.
4. **UX/UI Designer senior** : spécialisé dans les applications mobiles modernes et ergonomiques.
5. **Expert DevSecOps et QA** : chargé de la sécurité, des tests, de la qualité du code et du déploiement.
6. **Product Manager** : chargé de définir les priorités, le MVP et l'évolution commerciale de l'application.

Tu dois raisonner comme une équipe construisant un véritable produit commercial destiné au marché congolais.

Ne te limite pas à des recommandations générales. Fournis des solutions concrètes, structurées, techniquement justifiées et réalisables.

## 1. CONTEXTE DU PROJET

Je souhaite développer une application mobile de guide urbain, de découverte, de sorties, d'événements et de bons plans pour **Kinshasa, République démocratique du Congo**.

L'application doit permettre aux habitants, visiteurs et touristes de découvrir facilement les meilleurs endroits de Kinshasa, de connaître les événements organisés et de profiter des promotions proposées par les établissements.

L'application devra également constituer une plateforme commerciale permettant aux établissements de promouvoir leurs activités et de souscrire à des services payants.

### Objectifs principaux

- Centraliser les établissements et lieux intéressants de Kinshasa.
- Faciliter la découverte grâce à la géolocalisation.
- Permettre aux établissements de publier événements et promotions.
- Proposer des informations régulièrement actualisées.
- Fonctionner convenablement malgré les connexions Internet instables.
- Générer des revenus grâce aux abonnements professionnels et aux promotions sponsorisées.
- Offrir une expérience moderne, rapide, intuitive et sécurisée.

### Contraintes locales

Prends en considération :

- Les connexions mobiles parfois lentes ou instables.
- Le coût des données mobiles.
- L'utilisation fréquente des téléphones Android.
- La nécessité d'une interface intégralement disponible en français.
- Les paiements en dollars américains (USD) et francs congolais (CDF).
- L'utilisation courante de WhatsApp et du Mobile Money.
- Les particularités des adresses, communes et quartiers de Kinshasa.
- Le fuseau horaire `Africa/Kinshasa`.
- La nécessité de limiter les coûts d'exploitation pendant le lancement.

Prévois une application Android prioritaire, tout en maintenant une architecture compatible avec iOS.

## 2. UTILISATEURS ET RÔLES

L'application doit intégrer quatre profils.

### A. Visiteur non connecté

Un utilisateur doit pouvoir explorer les informations publiques sans créer de compte.

Il peut :

- Parcourir les établissements.
- Rechercher des lieux.
- Consulter les fiches publiques.
- Consulter les événements et promotions.
- Visualiser les cartes et itinéraires lorsque les services nécessaires sont disponibles.

Les fonctionnalités nécessitant une identité pourront demander une connexion.

### B. Utilisateur inscrit

Il dispose des fonctionnalités publiques et peut :

- Enregistrer ses établissements favoris.
- Publier des avis et des notes.
- Gérer son profil.
- Consulter les lieux qu'il a volontairement enregistrés comme visités.
- Recevoir ultérieurement des notifications personnalisées avec son consentement.

La géolocalisation doit rester facultative.

N'enregistre pas automatiquement l'historique détaillé de localisation.

### C. Gérant d'établissement

Il dispose d'un espace professionnel permettant :

- La gestion de son ou de ses établissements.
- La modification de ses fiches.
- La publication des événements.
- La création de promotions.
- Le suivi de son abonnement.
- La consultation des statistiques autorisées.
- L'achat de campagnes sponsorisées.

Prévois qu'un établissement puisse éventuellement disposer de plusieurs collaborateurs autorisés.

### D. Administrateur de la plateforme

L'administrateur principal dispose d'un tableau de bord sécurisé lui permettant de :

- Gérer les utilisateurs et les professionnels.
- Vérifier les établissements et leurs propriétaires.
- Valider, refuser ou masquer certains contenus.
- Contrôler les événements et promotions.
- Administrer les abonnements.
- Gérer les campagnes sponsorisées.
- Consulter les revenus et statistiques de la plateforme.
- Superviser les signalements et avis.
- Gérer les catégories, paramètres et taux de conversion.
- Consulter les journaux d'audit.
- Suspendre les comptes abusifs.

Les permissions doivent être appliquées au niveau du backend et de la base de données, pas uniquement dans l'interface.

## 3. FONCTIONNALITÉS DE L'APPLICATION MOBILE

### Module 1 — Découverte des établissements

Catégories initiales :

- Sites touristiques et lieux de visite.
- Restaurants.
- Bars et lounges.
- Supermarchés.

Prévoir une architecture permettant d'ajouter ultérieurement d'autres catégories.

Chaque établissement possède une fiche comprenant :

- Nom et catégorie.
- Description.
- Commune et quartier.
- Adresse descriptive.
- Coordonnées GPS.
- Photos optimisées.
- Horaires habituels.
- Fermetures exceptionnelles.
- Contacts téléphoniques.
- WhatsApp.
- Réseaux sociaux.
- Site Internet si disponible.
- Tarifs et menus lorsque disponibles.
- Note moyenne et avis.
- Événements et promotions associés.
- Statut de vérification de l'établissement.

Prévoir la possibilité qu'une fiche existe avant que son propriétaire ne revendique officiellement sa gestion.

### Module 2 — Recherche et géolocalisation

L'utilisateur doit pouvoir :

- Rechercher un établissement par nom.
- Filtrer par catégorie.
- Filtrer par commune ou quartier.
- Rechercher les établissements à proximité.
- Trier par distance, pertinence et notes.
- Filtrer les établissements actuellement ouverts.
- Afficher les résultats sur une carte.
- Lancer un itinéraire vers un établissement.

Prendre en compte les communes comme Gombe, Ngaliema, Limete, Bandalungwa, Matete, Lemba, Kintambo et les autres communes de Kinshasa.

Ne pas supposer que toutes les adresses sont géographiquement précises.

Prévoir la vérification ou la correction des coordonnées GPS des établissements.

Les horaires doivent gérer les établissements ouverts après minuit, les jours particuliers et les fermetures exceptionnelles.

### Module 3 — Événements et actualités

Créer une rubrique :

**« Quoi de neuf à Kin ? »**

Elle doit afficher notamment :

- Concerts.
- Soirées spéciales.
- Événements culturels.
- Expositions.
- Retransmissions sportives.
- Activités touristiques.
- Événements organisés par les établissements.

Chaque événement doit posséder :

- Identifiant unique.
- Établissement organisateur.
- Titre.
- Description.
- Visuel.
- Date et heure de début.
- Date et heure de fin.
- Prix éventuel.
- Devise.
- Conditions particulières.
- Statut de publication.
- Informations de réservation ou de contact.

Les événements terminés doivent automatiquement cesser d'apparaître dans les listes d'événements à venir, sans être nécessairement supprimés de la base.

Prévoir les mécanismes de modération et de signalement.

### Module 4 — Promotions et bons plans

Créer une rubrique dédiée :

**« Bons plans à Kinshasa »**

Types possibles :

- Happy hours.
- Menus promotionnels.
- Réductions spéciales.
- Offres du week-end.
- Promotions temporaires.

Chaque promotion doit contenir :

- Établissement concerné.
- Titre et description.
- Conditions d'utilisation.
- Visuels.
- Date de début.
- Date d'expiration.
- Ancien et nouveau prix, si pertinents.
- Devise.
- Statut actif, expiré, suspendu ou brouillon.

Une promotion expirée ne doit plus être présentée comme une offre active.

### Module 5 — Favoris, notes et avis

Prévoir :

- L'enregistrement des favoris.
- Les notes.
- Les commentaires.
- Le signalement des avis abusifs.
- La modération.
- La prévention des publications répétées et frauduleuses.

Distinguer les avis ordinaires des avis pour lesquels une preuve de visite valide existe.

Ne jamais présenter un avis comme vérifié sans justification réelle.

### Module 6 — Prix et devises

Intégrer :

- USD.
- CDF.

Les prix doivent conserver leur devise d'origine.

Prévoir une table de taux de conversion historisés, avec date de mise à jour et source.

Ne pas coder un taux fixe dans l'application.

Lorsque le prix affiché est converti, signaler qu'il s'agit d'une estimation, sauf si l'établissement confirme expressément ce tarif.

Éviter les erreurs d'arrondi en utilisant une représentation monétaire précise adaptée à chaque devise.

## 4. ESPACE PROFESSIONNEL

Prévoir un back-office responsive, idéalement utilisable sur ordinateur et téléphone.

### Gestion des établissements

Un gérant autorisé peut :

- Modifier les informations.
- Charger les photos.
- Modifier les horaires.
- Mettre à jour les menus.
- Gérer les contacts.
- Corriger l'emplacement GPS.
- Consulter le statut de vérification.

### Événements et promotions

Le professionnel peut :

- Créer des brouillons.
- Publier selon ses droits d'abonnement.
- Programmer une période de publication.
- Modifier les contenus autorisés.
- Consulter les statistiques.
- Suspendre une campagne.

Les autorisations de publication doivent être contrôlées côté serveur.

### Statistiques

Prévoir au minimum :

- Nombre de consultations de la fiche.
- Clics sur les événements.
- Clics sur les promotions.
- Demandes d'itinéraires.
- Clics sur les moyens de contact.

Définir une stratégie de collecte qui respecte la vie privée et limite les faux clics.

## 5. MODÈLE ÉCONOMIQUE

### A. Abonnements professionnels

Prévoir trois états commerciaux principaux :

**Plan Gratuit**

- Fiche standard.
- Informations publiques.
- Contacts.
- Localisation.
- Fonctionnalités de base.

**Plan Pro / Premium**

- Publications d'événements et de promotions selon les droits définis.
- Statistiques professionnelles.
- Fonctionnalités avancées.
- Options de visibilité supplémentaires si elles font partie du forfait.

Les publications illimitées peuvent être prévues commercialement, mais doivent rester soumises à des limites techniques anti-abus raisonnables.

**Période d'essai**

Possibilité d'offrir temporairement certaines fonctionnalités payantes.

Gérer les statuts :

- Essai.
- Actif.
- En attente de paiement.
- En retard de paiement, si applicable.
- Expiré.
- Résilié.
- Suspendu.

Prévoir les abonnements mensuels et annuels.

La perte des droits Premium doit être appliquée correctement lors de l'expiration, sans suppression des données du professionnel.

**Important : la vérification de l'identité d'un établissement doit rester indépendante du paiement d'un abonnement.**

### B. Publicités et campagnes sponsorisées

Un établissement peut payer pour promouvoir :

- Sa fiche.
- Une promotion.
- Un événement.

Emplacements possibles :

- Section « À la une ».
- Carrousel de l'accueil.
- Résultats sponsorisés.
- Bannières non intrusives.

Chaque campagne possède :

- Un budget ou tarif.
- Une date de début.
- Une date de fin.
- Un emplacement.
- Un statut.
- Un paiement associé.
- Des statistiques.

Les contenus payants doivent être clairement identifiés comme **« Sponsorisé »**.

Les « Coups de cœur » éditoriaux doivent être distincts des publicités payantes.

Prévoir des règles empêchant qu'un même annonceur monopolise tous les résultats.

### C. Paiements

Concevoir une architecture extensible permettant ultérieurement :

- Paiements Mobile Money compatibles avec la RDC.
- Paiements par carte bancaire.
- Paiements en USD et CDF.
- Abonnements renouvelables.
- Achat de campagnes sponsorisées.
- Factures et historique des paiements.

N'impose pas un prestataire de paiement sans vérifier sa disponibilité et ses conditions d'intégration en RDC.

Prévoir aussi une éventuelle validation administrative des paiements manuels pendant une phase pilote.

Les paiements doivent être vérifiés côté serveur, avec contrôle des doublons, identifiants de transaction et traitement idempotent des notifications de paiement.

Ne jamais débloquer un abonnement simplement parce que l'interface mobile signale qu'un paiement a réussi.

## 6. ARCHITECTURE TECHNIQUE

Évalue et recommande une architecture adaptée.

### Technologies à examiner en priorité

- **Mobile :** Flutter et Dart.
- **Backend :** Supabase ou architecture alternative justifiée.
- **Base de données :** PostgreSQL.
- **Recherche géographique :** PostGIS.
- **Stockage local :** Drift/SQLite ou autre solution justifiée.
- **Médias :** stockage objet, CDN et optimisation automatique.
- **Authentification :** email, téléphone et Google lorsque les intégrations sont réellement disponibles.
- **Back-office :** Flutter Web ou framework web adapté.
- **Cartographie :** solution offrant un bon équilibre entre coût, précision, performance et disponibilité à Kinshasa.

Compare les options pertinentes avant de choisir.

Évite d'accumuler plusieurs technologies réalisant les mêmes fonctions sans justification.

### Contraintes d'architecture

Le projet doit être :

- Modulaire.
- Maintenable.
- Testable.
- Sécurisé.
- Évolutif.
- Compatible avec des mises à jour progressives.
- Économique à exploiter au lancement.

Propose une structure claire de dépôt et une séparation cohérente entre interface, logique métier, accès aux données et services externes.

## 7. OFFLINE-FIRST ET SYNCHRONISATION

Cette fonctionnalité est prioritaire.

L'application doit rester utilisable lorsque la connexion Internet disparaît, dans la limite des données déjà disponibles localement.

### Comportements exigés

**Première ouverture sans connexion :**

Afficher une interface fonctionnelle avec une information claire sur l'absence de données synchronisées.

Ne pas afficher d'écran blanc.

**Utilisation normale avec connexion :**

Télécharger les données utiles, optimiser les médias et alimenter le cache local.

**Perte de connexion :**

Continuer à afficher les fiches, événements et images déjà disponibles.

Indiquer discrètement quand les données affichées peuvent être anciennes.

**Retour de connexion :**

Synchroniser les données sans bloquer la navigation.

Mettre à jour les listes et informations devenues obsolètes.

### Architecture à détailler

Propose :

- Une stratégie de cache persistante.
- Des durées de validité adaptées aux types de données.
- Une synchronisation incrémentale.
- Des mécanismes de pagination.
- Des identifiants et versions de synchronisation.
- Une gestion des suppressions et archivages.
- Une file d'attente pour les opérations hors ligne autorisées.
- Une stratégie de résolution des conflits.
- Des reprises sur erreur avec temporisation progressive.
- Une limitation de consommation des données mobiles.
- Un nettoyage du cache lorsque nécessaire.

Distingue l'accès au réseau de la disponibilité réelle du backend.

Une connexion Wi-Fi ne garantit pas que le serveur soit accessible.

Les fonctions de publication professionnelle, paiement et validation serveur pourront nécessiter une connexion active.

Pour les cartes, explique les limites du mode hors ligne et les éventuelles obligations de licence des fournisseurs cartographiques.

## 8. IMAGES ET PERFORMANCE

Prévoir :

- Compression à l'envoi.
- Plusieurs résolutions d'images.
- Formats WebP et autres formats pertinents.
- Chargement progressif.
- Cache disque.
- Images de remplacement.
- Reprise contrôlée en cas d'échec.
- Chargement différé des médias.
- Limitation de la mémoire utilisée.

Ne pas télécharger systématiquement toutes les images de Kinshasa.

Définir des règles adaptées aux téléphones disposant de peu de mémoire ou d'une connexion limitée.

Prévoir des mécanismes de validation et de sécurisation des fichiers envoyés par les professionnels.

## 9. SÉCURITÉ ET AUTHENTIFICATION

Prévoir :

- Email et mot de passe.
- Connexion Google.
- Connexion par téléphone si le fournisseur SMS choisi fonctionne en RDC.
- Gestion des sessions.
- Réinitialisation des accès.
- Gestion des rôles.
- Protection des API.
- Protection des données personnelles.
- Limitation des tentatives abusives.
- Validation serveur des permissions.
- Journaux d'audit.
- Sauvegardes et restauration.

Si Supabase est retenu, définir une stratégie stricte de **Row Level Security (RLS)**.

Pour Google Sign-In, prévoir les configurations nécessaires sur Android et iOS, y compris les identifiants OAuth, signatures et redirections.

Identifier toutes les configurations externes qui nécessiteront une intervention humaine.

Ne jamais intégrer de secrets ou de clés privilégiées dans le code client.

Prévoir des protections contre la fraude aux abonnements, les campagnes fictives et la revendication abusive d'établissements.

## 10. BASE DE DONNÉES

Conçois un schéma relationnel complet et normalisé.

Inclure au minimum les domaines suivants :

**Identités et permissions**

- Profils utilisateurs.
- Rôles et autorisations.
- Comptes professionnels.
- Associations entre utilisateurs et établissements.

**Établissements**

- Établissements.
- Catégories.
- Communes et quartiers.
- Localisations.
- Horaires.
- Exceptions d'horaires.
- Photos.
- Contacts.
- Menus et tarifs.
- Revendications et vérifications.

**Activités publiques**

- Événements.
- Promotions.
- Images associées.
- États de publication.
- Signalements et modération.

**Engagement utilisateur**

- Favoris.
- Avis.
- Notes.
- Éventuelles preuves de visite.
- Interactions statistiques.

**Monétisation**

- Forfaits.
- Abonnements.
- Droits d'accès.
- Factures.
- Paiements.
- Transactions.
- Campagnes sponsorisées.
- Emplacements publicitaires.
- Tarifs de campagnes.

**Gestion technique**

- Devises.
- Historique des taux.
- Paramètres.
- Journaux d'audit.
- Versions et dates de modification utiles à la synchronisation.

Pour chaque table, présente :

1. Son rôle.
2. Ses principaux champs et types.
3. Sa clé primaire.
4. Ses clés étrangères.
5. Ses contraintes.
6. Ses index pertinents.
7. Ses règles de sécurité et d'accès.

Ajoute un diagramme relationnel Mermaid.

Explique comment éviter les doublons et garantir l'intégrité des données.

Précise les champs nécessaires à la gestion des dates, des expirations et des modifications.

## 11. CONCEPTION UX/UI

L'application doit présenter un design moderne, soigné et adapté à Kinshasa.

Principes :

- Navigation simple.
- Interface en français.
- Recherche rapidement accessible.
- Mise en avant des photos et lieux.
- Chargement rapide.
- Informations essentielles visibles.
- Expérience utilisable sur des écrans modestes.
- Messages d'erreur clairs et non bloquants.
- États de chargement, d'absence de données et de connexion perdue.
- Accessibilité et contrastes corrects.

### Écrans à prévoir

**Application mobile**

- Accueil.
- Explorer.
- Recherche et filtres.
- Carte.
- Détails d'un établissement.
- Événements.
- Détails d'un événement.
- Promotions.
- Détails d'une promotion.
- Favoris.
- Connexion et inscription.
- Profil.
- Paramètres.

**Espace professionnel**

- Connexion professionnelle.
- Tableau de bord.
- Mes établissements.
- Modifier une fiche.
- Gestion des photos.
- Gestion des événements.
- Gestion des promotions.
- Statistiques.
- Abonnement.
- Paiements et factures.
- Campagnes sponsorisées.

**Administration**

- Tableau de bord général.
- Établissements et demandes de vérification.
- Utilisateurs et professionnels.
- Modération.
- Catégories et zones géographiques.
- Abonnements.
- Transactions.
- Campagnes publicitaires.
- Statistiques.
- Paramètres de la plateforme.
- Audit et sécurité.

Propose les parcours de navigation et les composants réutilisables.

## 12. ORGANISATION DU DÉVELOPPEMENT

Tu dois distinguer le MVP des fonctionnalités avancées.

### Objectif du MVP

Créer d'abord une version réellement utilisable permettant :

- La découverte des établissements.
- La consultation des fiches.
- La recherche et les filtres.
- La géolocalisation.
- Le cache hors ligne essentiel.
- La consultation des événements et promotions.
- Une administration minimale.
- Un premier espace gérant.
- Une authentification fiable pour les fonctionnalités nécessitant un compte.

La structure de données doit permettre l'intégration de la monétisation sans refonte majeure.

Indique quelles fonctions commerciales doivent être disponibles dès le MVP et lesquelles peuvent attendre une deuxième version.

### Méthode de travail

Découpe le projet en phases ou missions numérotées.

Pour chaque mission, précise :

1. Objectif.
2. Fonctionnalités concernées.
3. Dépendances.
4. Tables nécessaires.
5. Livrables.
6. Tests.
7. Critères d'acceptation.
8. Risques.
9. Conditions de validation.

Ne commence pas automatiquement la mission suivante lorsqu'une mission nécessite ma validation.

Chaque mission doit pouvoir être vérifiée avant de poursuivre.

## 13. EXIGENCES DE QUALITÉ ET TESTS

Prévois des tests automatisés et manuels pour les scénarios suivants :

- Ouverture de l'application sans Internet.
- Coupure réseau pendant le chargement.
- Récupération du réseau.
- Synchronisation des données modifiées.
- Expiration d'une promotion.
- Événement terminé.
- Horaires traversant minuit.
- Échec de chargement des images.
- Recherche GPS sans autorisation de localisation.
- Connexion et déconnexion.
- Tentative d'accès à un établissement non autorisé.
- Expiration d'un abonnement Premium.
- Paiement signalé deux fois.
- Paiement refusé.
- Publication non autorisée par un compte gratuit.
- Protection des données entre deux établissements distincts.

Propose des tests unitaires, d'intégration, de sécurité et de performance.

Définis des critères de qualité mesurables, avec des objectifs de performance à valider sur des appareils et réseaux représentatifs.

## 14. RÈGLES DE COLLABORATION AVEC CLAUDE CODE

Si tu disposes d'un dépôt Git ou d'un projet existant :

- Commence par examiner sa structure et son état.
- Identifie les fonctionnalités déjà implémentées.
- Repère les erreurs, risques et dépendances.
- Ne supprime pas les éléments fonctionnels.
- Ne réinitialise pas le projet inutilement.
- Propose des modifications progressives.
- Utilise une branche de travail adaptée pour les développements validés.
- Exécute les tests disponibles après les changements.
- Signale précisément les tests impossibles à exécuter.

Si aucun projet n'existe, propose une structure initiale adaptée à la création du dépôt.

**À cette étape, ta mission est de produire l'architecture et le plan de développement. Ne commence pas à modifier des fichiers ou à écrire l'application complète avant validation de cette architecture.**

Lors des missions ultérieures, une fois l'exécution autorisée, ne te contente pas de décrire du code : effectue réellement les modifications dans l'environnement accessible, puis vérifie et rapporte le résultat.

Ne prétends jamais qu'une fonctionnalité a été testée, publiée ou déployée si cela n'a pas réellement été fait.

## 15. FORMAT DE TA PREMIÈRE RÉPONSE

Produis un rapport technique en français avec les sections suivantes, dans cet ordre :

### Partie 1 — Compréhension du projet
Résume le produit, les utilisateurs, les objectifs commerciaux et les principales contraintes.

### Partie 2 — Analyse et recommandations
Identifie les lacunes, les risques et les améliorations pertinentes du cahier des charges.

Distingue les éléments obligatoires de tes suggestions.

### Partie 3 — Stack technique recommandée
Présente les technologies retenues dans un tableau comparatif et justifie les choix.

Précise les coûts potentiels et dépendances externes, sans inventer de tarifs non vérifiés.

### Partie 4 — Architecture logicielle
Présente les différents composants, leurs responsabilités et les échanges de données.

Ajoute un diagramme Mermaid.

### Partie 5 — Architecture de base de données
Présente le schéma relationnel, les tables, relations, contraintes, index et règles de sécurité.

Ajoute le diagramme entité-relation.

### Partie 6 — Stratégie Offline-First
Explique précisément le stockage local, les règles de cache, la synchronisation, la gestion des erreurs et le retour de connexion.

### Partie 7 — Architecture de sécurité
Explique les permissions, l'authentification, la vérification des professionnels et les mécanismes de protection.

### Partie 8 — Modèle de monétisation
Décris les abonnements, les paiements, les droits Premium, les campagnes sponsorisées et leur fonctionnement technique.

### Partie 9 — Architecture des interfaces
Présente l'arborescence complète et les parcours pour le visiteur, l'utilisateur, le gérant et l'administrateur.

### Partie 10 — MVP et feuille de route
Sépare les fonctionnalités indispensables des évolutions futures.

Propose des missions de développement ordonnées, chacune avec ses livrables et critères de validation.

### Partie 11 — Plan de tests
Présente les principaux scénarios de recette et les critères nécessaires pour considérer le MVP comme prêt.

### Partie 12 — Décisions à valider
Présente uniquement les décisions importantes qui nécessitent mon intervention.

Pour chaque décision, donne :
- Les options possibles.
- Les avantages et inconvénients.
- Ta recommandation.
- Les conséquences du choix.

## 16. INSTRUCTIONS FINALES

Respecte les exigences suivantes :

1. Réponds intégralement en français.
2. Utilise un langage technique précis, mais explique les notions complexes simplement.
3. Privilégie les solutions réalistes pour une startup en RDC.
4. Évite la complexité inutile.
5. Ne présente pas des hypothèses comme des faits confirmés.
6. Si une information actuelle doit être vérifiée (API, fournisseur, tarifs, compatibilité), indique-le et vérifie-la lorsque tes outils le permettent.
7. N'invente ni étude de marché, ni statistiques locales, ni disponibilité de services.
8. Formule des recommandations concrètes plutôt que de longues listes d'options sans conclusion.
9. Identifie les dépendances bloquantes avant toute mise en production.
10. Préserve la possibilité d'ajouter de nouvelles catégories, la billetterie et d'autres villes dans le futur.
11. Documente les choix techniques pour permettre une reprise du développement dans une autre session Claude.
12. Ne demande pas de confirmation pour chaque détail mineur ; fais des hypothèses raisonnables en les signalant.
13. Ne me pose des questions que si une décision est véritablement nécessaire.

**COMMENCE MAINTENANT PAR LA PHASE D'ANALYSE ET DE CONCEPTION.**

**LIVRABLE ATTENDU :** un dossier d'architecture technique et fonctionnelle suffisamment précis pour servir de référence officielle au développement de l'application.

Une fois le rapport présenté, arrête-toi à la proposition de la Mission 01 et attends ma validation avant de passer à l'implémentation.  ]
