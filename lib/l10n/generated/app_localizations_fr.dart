// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Rider Group';

  @override
  String get navHome => 'Accueil';

  @override
  String get navRides => 'Balades';

  @override
  String get navClubs => 'Clubs';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get homeWelcomeTitle => 'Bienvenue sur Rider Group';

  @override
  String get homeWelcomeBody =>
      'La communauté des motards de la RDC : clubs, balades, entraide et passion.';

  @override
  String get homeUpcomingRides => 'Prochaines balades';

  @override
  String get homeClubs => 'Clubs à découvrir';

  @override
  String get homeCommunity => 'Fil de la communauté';

  @override
  String get homeShortcuts => 'Accès rapides';

  @override
  String get homeNoRides => 'Aucune balade à venir pour le moment.';

  @override
  String get homeNoClubs => 'Aucun club à afficher pour le moment.';

  @override
  String get homeNoPosts => 'Aucune publication pour le moment.';

  @override
  String get garageTitle => 'Mon garage';

  @override
  String get garageSubtitle => 'Vos motos et leur entretien';

  @override
  String get garageEmptyTitle => 'Votre garage est vide';

  @override
  String get garageEmptyBody =>
      'Vous pourrez bientôt enregistrer vos motos et suivre leur entretien. Ces informations resteront privées par défaut.';

  @override
  String get marketplaceTitle => 'Marketplace';

  @override
  String get marketplaceSubtitle => 'Motos, pièces et équipements';

  @override
  String get marketplaceEmptyTitle => 'Aucune annonce pour le moment';

  @override
  String get marketplaceEmptyBody =>
      'Les petites annonces entre motards arrivent bientôt. Aucun paiement n\'est effectué dans l\'application : les échanges se concluent directement entre utilisateurs.';

  @override
  String get ridesTitle => 'Balades';

  @override
  String get ridesEmptyTitle => 'Aucune balade pour le moment';

  @override
  String get ridesEmptyBody =>
      'Vous pourrez bientôt créer, rechercher et rejoindre des balades, seul ou avec votre club.';

  @override
  String get clubsTitle => 'Clubs';

  @override
  String get clubsEmptyTitle => 'Aucun club pour le moment';

  @override
  String get clubsEmptyBody =>
      'Vous pourrez bientôt créer un club ou rejoindre des clubs publics et privés.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesEmptyTitle => 'Aucune conversation';

  @override
  String get messagesEmptyBody =>
      'La messagerie privée, les groupes et les discussions de balade arrivent bientôt.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignedOutTitle => 'Vous n\'êtes pas connecté';

  @override
  String get profileSignedOutBody =>
      'La création de compte et la connexion seront disponibles prochainement.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsServer => 'Serveur';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAboutBody =>
      'Rider Group — application communautaire pour motards.';

  @override
  String environmentLabel(String environment) {
    return 'Environnement : $environment';
  }

  @override
  String get backendNotConfiguredTitle => 'Serveur non configuré';

  @override
  String get backendNotConfiguredBody =>
      'Aucune donnée n\'est synchronisée : les identifiants Supabase n\'ont pas été fournis à cette version de l\'application.';

  @override
  String get backendReadyTitle => 'Client Supabase initialisé';

  @override
  String get backendReadyBody =>
      'La configuration du serveur est chargée. La disponibilité réelle du serveur sera vérifiée lors des premières requêtes.';

  @override
  String get backendFailedTitle => 'Échec d\'initialisation du serveur';

  @override
  String get backendFailedBody =>
      'La configuration du serveur n\'a pas pu être chargée. Les fonctionnalités en ligne sont indisponibles.';

  @override
  String get safetyNotice =>
      'Ne manipulez jamais votre téléphone en roulant. Arrêtez-vous en lieu sûr avant d\'utiliser l\'application.';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String get notFoundBody => 'La page demandée n\'existe pas.';

  @override
  String get backToHome => 'Retour à l\'accueil';
}
