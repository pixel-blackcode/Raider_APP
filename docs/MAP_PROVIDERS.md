# Fournisseur de cartographie — comparaison (décision O-02)

> Document de décision pour la Mission 05 (GPS et mode Convoi). Rédigé le 11 novembre 2026.
>
> ⚠️ **Fiabilité des chiffres.** Les pages officielles de Mapbox et de Google n'étaient pas accessibles depuis l'environnement de travail : leur domaine était bloqué par le réseau. Les tarifs ci-dessous viennent de recherches web recoupant plusieurs sources, listées en bas de page. Il faut les **revérifier sur les pages officielles avant tout engagement payant**.

## Besoins de Rider Group

| Besoin | Pourquoi c'est important ici |
| --- | --- |
| **Cartes hors ligne** | Les balades entre villes traversent des zones sans réseau. Le mode Convoi doit continuer d'afficher la carte. |
| **Faible consommation de données** | Les forfaits mobiles sont chers en RDC (exigence du cahier des charges). |
| **Coût maîtrisé quand le nombre d'utilisateurs augmente** | Application communautaire sans paiement intégré : les revenus ne suivent pas forcément le nombre d'utilisateurs. |
| **Beaucoup de marqueurs mis à jour souvent** | Positions des participants en temps réel, chef de convoi, serre-file. |
| **Qualité des cartes en RDC** | Kinshasa, Lubumbashi et les routes entre les villes. |
| **Support Flutter Android / iOS** | Stack du projet. |
| **Usage commercial autorisé** | Rider Group est un produit, même gratuit pour les utilisateurs. |

## Les options

| Critère | **Google Maps** (`google_maps_flutter`) | **Mapbox** (`mapbox_maps_flutter`) | **MapLibre + OpenStreetMap hébergé par nous** (`maplibre_gl` + fichiers PMTiles) | **MapLibre + hébergeur de tuiles** (MapTiler, Stadia Maps) |
| --- | --- | --- | --- | --- |
| Coût de l'affichage des cartes sur mobile | **Gratuit et illimité**, mais un compte de facturation (carte bancaire) est obligatoire | **Gratuit jusqu'à 25 000 utilisateurs actifs par mois**, puis environ 4 $ par tranche de 1 000 | **Aucune licence.** Seuls le stockage et la bande passante sont payants (quelques dollars par mois, à mesurer) | Offres gratuites **interdites en usage commercial**. Offres payantes à partir d'environ 20 à 30 $ par mois |
| Cartes hors ligne | ❌ Pas de téléchargement de zones pour les développeurs ; la mise en cache des tuiles est réputée interdite | ✅ Officiel, avec une limite de 750 « tile packs » par appareil. Redistribuer les cartes téléchargées est interdit | ✅ **Totalement libre** : on peut fournir ou télécharger le fichier de la RDC (licence ODbL, attribution OSM) | ✅ Zones hors ligne via MapLibre, selon les conditions de l'hébergeur |
| Consommation de données | Moyenne | Faible (tuiles vectorielles) | Faible (tuiles vectorielles) et **nulle une fois la zone téléchargée** | Faible (tuiles vectorielles) |
| Qualité en RDC | Probablement la meilleure à Kinshasa (non mesurée) | Données basées en partie sur OSM | OSM : Lubumbashi cartographiée par HOT (2014-2015) ; **lacunes signalées en périphérie de Kinshasa** | Identique à OSM |
| Itinéraires calculés | API Routes payante | API Directions payante, avec une offre gratuite | Moteur libre à héberger soi-même (OSRM, Valhalla), ou API tierce | Stadia inclut un calcul d'itinéraire dans ses crédits |
| Dépendance | Forte (Google, carte bancaire) | Forte (Mapbox) | **Aucune** (open source) | Moyenne : on peut changer d'hébergeur sans réécrire l'application |
| Effort de mise en place | Faible | Faible | **Moyen** : préparer et héberger le fichier PMTiles de la RDC | Faible |

### Coût estimé de l'affichage des cartes seul

Les itinéraires, la recherche d'adresses et les autres API sont exclus.

| Utilisateurs actifs par mois | Google Maps | Mapbox | MapLibre + PMTiles hébergé | MapTiler / Stadia |
| --- | --- | --- | --- | --- |
| 1 000 | 0 $ | 0 $ | ≈ 0 $ | ≈ 20–30 $ |
| 10 000 | 0 $ | 0 $ | ≈ 0–10 $ | ≈ 30–80 $ |
| 50 000 | 0 $ | ≈ 100 $ / mois | ≈ 5–20 $ | ≈ 80–250 $ |

Ces chiffres sont des estimations. Pour MapLibre + PMTiles, le coût dépend surtout de la bande passante. Un stockage objet sans frais de sortie, comme Cloudflare R2, le rendrait presque nul. **À mesurer** avec la taille réelle du fichier de la RDC.

## Recommandation

**MapLibre (`maplibre_gl`) avec des tuiles vectorielles OpenStreetMap au format PMTiles, que nous hébergeons nous-mêmes.** L'application est conçue pour pouvoir changer de source de cartes sans être réécrite.

Pourquoi :
1. **Le hors ligne est indispensable pour le mode Convoi, et c'est la seule option qui l'autorise sans restriction.** Google ne propose pas de téléchargement de zones aux développeurs, et Mapbox limite et encadre le contenu hors ligne.
2. **Le coût ne croît pas avec le nombre d'utilisateurs**, ce qui convient à une application gratuite sur un marché où les revenus sont limités.
3. **Pas de carte bancaire obligatoire**, contrairement à Google Maps Platform.
4. **Consommation de données minimale** : la zone de la balade se télécharge une seule fois, en Wi-Fi.

Risques et parades :
- **Lacunes d'OpenStreetMap en périphérie de Kinshasa.** On mesurera la couverture sur les itinéraires réels avant de lancer. La communauté OSM RDC est active, et Rider Group pourrait même contribuer en complétant les routes que les motards empruntent.
- **Plus de travail au départ** : extraire la RDC, l'héberger, définir un style de carte. On peut commencer par une offre de démonstration (MapTiler ou Stadia, gratuites pour le développement) pendant la préparation du fichier.
- **Maturité du module Flutter** (`maplibre_gl` 0.28) : il sera validé sur un vrai téléphone dès le début de la Mission 05.

**Alternative si l'on privilégie la rapidité et la finition :** Mapbox. C'est gratuit jusqu'à 25 000 utilisateurs actifs par mois, et le hors ligne est officiel mais limité. On l'envisagerait si les tests révèlent une qualité OSM insuffisante dans les zones clés.

**Déconseillé pour Rider Group :** Google Maps. C'est gratuit, mais sans hors ligne pour les développeurs, et la carte bancaire est obligatoire.

## Ce que la décision déclenche (Mission 05)

1. Valider `maplibre_gl` sur Android et iOS, avec une source de démonstration.
2. Produire l'extrait PMTiles de la RDC, mesurer sa taille et choisir où l'héberger.
3. Proposer le téléchargement de la zone de la balade avant le départ, en Wi-Fi.
4. Prévoir une source interchangeable (`MapTileSource`) pour pouvoir passer à MapTiler ou Mapbox.

## Sources

- Mapbox : [tarifs officiels](https://www.mapbox.com/pricing), [Woosmap — Mapbox Pricing 2026](https://www.woosmap.com/blog/mapbox-pricing), [StoreRocket — Is Mapbox Free?](https://storerocket.io/learn/mapbox-pricing), [APIbenchmarks — Mapbox](https://apibenchmarks.com/maps/mapbox), [apis.io — Mapbox plans](https://apis.io/plans/mapbox/mapbox-plans-pricing/)
- Mapbox hors ligne : [Mobile offline (limite de 750 tile packs)](https://docs.mapbox.com/help/dive-deeper/mobile-offline.md), [Concepts hors ligne Android](https://docs.mapbox.com/android/maps/guides/offline/concepts/)
- Google : [tarifs officiels](https://developers.google.com/maps/billing-and-pricing/pricing), [Woosmap — Google Maps API Pricing 2026](https://www.woosmap.com/blog/google-maps-api-pricing-breakdown), [StoreRocket — Google Maps API Pricing](https://storerocket.io/learn/google-maps-api-pricing), [Conditions des services](https://cloud.google.com/maps-platform/terms/maps-service-terms/)
- MapLibre Flutter : [maplibre_gl sur pub.dev](https://pub.dev/packages/maplibre_gl), [Zones hors ligne](https://maplibre.org/flutter-maplibre-gl/advanced/offline-regions/), [PMTiles](https://maplibre.org/flutter-maplibre-gl/advanced/pmtiles/), [Matrice des fonctionnalités](https://maplibre.org/flutter-maplibre-gl/compare/feature-matrix/)
- Protomaps / PMTiles : [Supabase — Self-host Maps with Protomaps](https://supabase.com/blog/self-host-maps-storage-protomaps), [Protomaps — Getting started](https://docs.protomaps.com/guide/getting-started), [Téléchargements de fonds de carte](https://docs.protomaps.com/basemaps/downloads)
- MapTiler : [tarifs](https://www.maptiler.com/cloud/pricing/), [Geoapify — Free Map Tiles APIs 2026](https://www.geoapify.com/free-maps-api/)
- Stadia Maps : [tarifs](https://stadiamaps.com/pricing/), [FAQ (usage commercial)](https://stadiamaps.com/faqs/)
- OpenStreetMap en RDC : [Wiki OSM — RDC](https://wiki.openstreetmap.org/wiki/DRC), [Wiki OSM — Lubumbashi](https://wiki.openstreetmap.org/wiki/Lubumbashi), [Présentation OSM RDC à l'OSMF (2023)](https://osmfoundation.org/w/images/a/a0/OSM_DRC_presentation_during_2023-07_OSMF_board_meeting.pdf)
