import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rider Group'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navRides.
  ///
  /// In fr, this message translates to:
  /// **'Balades'**
  String get navRides;

  /// No description provided for @navClubs.
  ///
  /// In fr, this message translates to:
  /// **'Clubs'**
  String get navClubs;

  /// No description provided for @navMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Rider Group'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'La communauté des motards de la RDC : clubs, balades, entraide et passion.'**
  String get homeWelcomeBody;

  /// No description provided for @homeUpcomingRides.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines balades'**
  String get homeUpcomingRides;

  /// No description provided for @homeClubs.
  ///
  /// In fr, this message translates to:
  /// **'Clubs à découvrir'**
  String get homeClubs;

  /// No description provided for @homeCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Fil de la communauté'**
  String get homeCommunity;

  /// No description provided for @homeShortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Accès rapides'**
  String get homeShortcuts;

  /// No description provided for @homeNoRides.
  ///
  /// In fr, this message translates to:
  /// **'Aucune balade à venir pour le moment.'**
  String get homeNoRides;

  /// No description provided for @homeNoClubs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun club à afficher pour le moment.'**
  String get homeNoClubs;

  /// No description provided for @homeNoPosts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication pour le moment.'**
  String get homeNoPosts;

  /// No description provided for @garageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon garage'**
  String get garageTitle;

  /// No description provided for @garageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos motos et leur entretien'**
  String get garageSubtitle;

  /// No description provided for @garageEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage est vide'**
  String get garageEmptyTitle;

  /// No description provided for @garageEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez bientôt enregistrer vos motos et suivre leur entretien. Ces informations resteront privées par défaut.'**
  String get garageEmptyBody;

  /// No description provided for @marketplaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Motos, pièces et équipements'**
  String get marketplaceSubtitle;

  /// No description provided for @marketplaceEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce pour le moment'**
  String get marketplaceEmptyTitle;

  /// No description provided for @marketplaceEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les petites annonces entre motards arrivent bientôt. Aucun paiement n\'est effectué dans l\'application : les échanges se concluent directement entre utilisateurs.'**
  String get marketplaceEmptyBody;

  /// No description provided for @ridesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Balades'**
  String get ridesTitle;

  /// No description provided for @ridesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune balade pour le moment'**
  String get ridesEmptyTitle;

  /// No description provided for @ridesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez bientôt créer, rechercher et rejoindre des balades, seul ou avec votre club.'**
  String get ridesEmptyBody;

  /// No description provided for @clubsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clubs'**
  String get clubsTitle;

  /// No description provided for @clubsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun club pour le moment'**
  String get clubsEmptyTitle;

  /// No description provided for @clubsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez bientôt créer un club ou rejoindre des clubs publics et privés.'**
  String get clubsEmptyBody;

  /// No description provided for @messagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'La messagerie privée, les groupes et les discussions de balade arrivent bientôt.'**
  String get messagesEmptyBody;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileSignedOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'êtes pas connecté'**
  String get profileSignedOutTitle;

  /// No description provided for @profileSignedOutBody.
  ///
  /// In fr, this message translates to:
  /// **'La création de compte et la connexion seront disponibles prochainement.'**
  String get profileSignedOutBody;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsServer.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get settingsServer;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In fr, this message translates to:
  /// **'Rider Group — application communautaire pour motards.'**
  String get settingsAboutBody;

  /// No description provided for @environmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Environnement : {environment}'**
  String environmentLabel(String environment);

  /// No description provided for @backendNotConfiguredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Serveur non configuré'**
  String get backendNotConfiguredTitle;

  /// No description provided for @backendNotConfiguredBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée n\'est synchronisée : les identifiants Supabase n\'ont pas été fournis à cette version de l\'application.'**
  String get backendNotConfiguredBody;

  /// No description provided for @backendReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Client Supabase initialisé'**
  String get backendReadyTitle;

  /// No description provided for @backendReadyBody.
  ///
  /// In fr, this message translates to:
  /// **'La configuration du serveur est chargée. La disponibilité réelle du serveur sera vérifiée lors des premières requêtes.'**
  String get backendReadyBody;

  /// No description provided for @backendFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échec d\'initialisation du serveur'**
  String get backendFailedTitle;

  /// No description provided for @backendFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'La configuration du serveur n\'a pas pu être chargée. Les fonctionnalités en ligne sont indisponibles.'**
  String get backendFailedBody;

  /// No description provided for @safetyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ne manipulez jamais votre téléphone en roulant. Arrêtez-vous en lieu sûr avant d\'utiliser l\'application.'**
  String get safetyNotice;

  /// No description provided for @notFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'La page demandée n\'existe pas.'**
  String get notFoundBody;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
