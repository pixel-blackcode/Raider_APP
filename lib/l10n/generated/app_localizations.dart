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
  /// **'Aucune annonce'**
  String get marketplaceEmptyTitle;

  /// No description provided for @marketplaceEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce ne correspond. Touchez « Vendre » pour publier la vôtre.'**
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
  /// **'Connectez-vous pour accéder à votre profil.'**
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

  /// No description provided for @actionAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get actionAccept;

  /// No description provided for @actionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get actionCancel;

  /// No description provided for @actionDecline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get actionDecline;

  /// No description provided for @actionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get actionSave;

  /// No description provided for @actionRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get actionRetry;

  /// No description provided for @errorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorTitle;

  /// No description provided for @signInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez votre communauté de motards.'**
  String get signInSubtitle;

  /// No description provided for @signInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signInAction;

  /// No description provided for @signInNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get signInNoAccount;

  /// No description provided for @signUpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un seul compte, même si vous rejoignez plusieurs clubs.'**
  String get signUpSubtitle;

  /// No description provided for @signUpAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get signUpAction;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà inscrit ? Se connecter'**
  String get signUpHaveAccount;

  /// No description provided for @signUpCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Confirmez votre adresse e-mail grâce au lien reçu, puis connectez-vous.'**
  String get signUpCheckEmail;

  /// No description provided for @signOutAction.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOutAction;

  /// No description provided for @fieldEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum, dont une lettre et un chiffre'**
  String get fieldPasswordHelp;

  /// No description provided for @fieldPasswordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get fieldPasswordConfirm;

  /// No description provided for @fieldDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get fieldDisplayName;

  /// No description provided for @fieldUsername.
  ///
  /// In fr, this message translates to:
  /// **'Pseudonyme'**
  String get fieldUsername;

  /// No description provided for @fieldUsernameHelp.
  ///
  /// In fr, this message translates to:
  /// **'3 à 30 caractères : minuscules, chiffres, _'**
  String get fieldUsernameHelp;

  /// No description provided for @fieldCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get fieldCity;

  /// No description provided for @fieldBio.
  ///
  /// In fr, this message translates to:
  /// **'Présentation'**
  String get fieldBio;

  /// No description provided for @validationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum, dont une lettre et un chiffre'**
  String get validationPassword;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get validationPasswordMismatch;

  /// No description provided for @validationDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Entre 1 et 60 caractères'**
  String get validationDisplayName;

  /// No description provided for @validationUsername.
  ///
  /// In fr, this message translates to:
  /// **'3 à 30 caractères : lettres minuscules, chiffres ou _'**
  String get validationUsername;

  /// No description provided for @validationClubName.
  ///
  /// In fr, this message translates to:
  /// **'Entre 3 et 80 caractères'**
  String get validationClubName;

  /// No description provided for @validationCity.
  ///
  /// In fr, this message translates to:
  /// **'Entre 2 et 80 caractères'**
  String get validationCity;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEdit;

  /// No description provided for @profileMissingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil introuvable'**
  String get profileMissingTitle;

  /// No description provided for @profileMissingBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil n\'a pas pu être chargé. Réessayez dans un instant.'**
  String get profileMissingBody;

  /// No description provided for @clubsOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Les clubs nécessitent une connexion au serveur Rider Group.'**
  String get clubsOfflineBody;

  /// No description provided for @clubsTabMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes clubs'**
  String get clubsTabMine;

  /// No description provided for @clubsTabDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get clubsTabDiscover;

  /// No description provided for @clubsMineEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez rejoint aucun club'**
  String get clubsMineEmptyTitle;

  /// No description provided for @clubsMineEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les clubs de votre ville ou créez le vôtre.'**
  String get clubsMineEmptyBody;

  /// No description provided for @clubsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un club ou une ville'**
  String get clubsSearchHint;

  /// No description provided for @clubsDiscoverEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun club trouvé'**
  String get clubsDiscoverEmptyTitle;

  /// No description provided for @clubsDiscoverEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre nom ou une autre ville, ou créez le premier club.'**
  String get clubsDiscoverEmptyBody;

  /// No description provided for @clubCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un club'**
  String get clubCreate;

  /// No description provided for @clubEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le club'**
  String get clubEdit;

  /// No description provided for @clubEditNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les administrateurs peuvent modifier ce club.'**
  String get clubEditNotAllowed;

  /// No description provided for @clubDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le club'**
  String get clubDelete;

  /// No description provided for @clubDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement « {name} » ? Les membres, demandes et invitations seront supprimés.'**
  String clubDeleteConfirm(String name);

  /// No description provided for @clubNotFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce club n\'existe pas ou n\'est pas accessible.'**
  String get clubNotFoundBody;

  /// No description provided for @clubFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du club'**
  String get clubFieldName;

  /// No description provided for @clubFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get clubFieldDescription;

  /// No description provided for @clubFieldRules.
  ///
  /// In fr, this message translates to:
  /// **'Règlement'**
  String get clubFieldRules;

  /// No description provided for @clubSectionAccess.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité et adhésion'**
  String get clubSectionAccess;

  /// No description provided for @clubSettingsOwnerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Seul le propriétaire peut modifier ces réglages.'**
  String get clubSettingsOwnerOnly;

  /// No description provided for @clubVisibilityPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get clubVisibilityPublic;

  /// No description provided for @clubVisibilityPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get clubVisibilityPrivate;

  /// No description provided for @clubVisibilityPublicHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le club et sa liste de membres sont visibles par tous les motards connectés.'**
  String get clubVisibilityPublicHelp;

  /// No description provided for @clubVisibilityPrivateHelp.
  ///
  /// In fr, this message translates to:
  /// **'La liste des membres est réservée aux membres. Vous choisissez si le club apparaît dans la recherche.'**
  String get clubVisibilityPrivateHelp;

  /// No description provided for @clubFieldListed.
  ///
  /// In fr, this message translates to:
  /// **'Apparaître dans la recherche'**
  String get clubFieldListed;

  /// No description provided for @clubFieldListedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, seuls les membres et les personnes invitées voient le club.'**
  String get clubFieldListedHelp;

  /// No description provided for @clubFieldJoinPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'adhésion'**
  String get clubFieldJoinPolicy;

  /// No description provided for @clubJoinOpen.
  ///
  /// In fr, this message translates to:
  /// **'Adhésion libre'**
  String get clubJoinOpen;

  /// No description provided for @clubJoinApproval.
  ///
  /// In fr, this message translates to:
  /// **'Sur approbation'**
  String get clubJoinApproval;

  /// No description provided for @clubJoinInviteOnly.
  ///
  /// In fr, this message translates to:
  /// **'Sur invitation uniquement'**
  String get clubJoinInviteOnly;

  /// No description provided for @clubRoleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get clubRoleOwner;

  /// No description provided for @clubRoleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get clubRoleAdmin;

  /// No description provided for @clubRoleModerator.
  ///
  /// In fr, this message translates to:
  /// **'Modérateur'**
  String get clubRoleModerator;

  /// No description provided for @clubRoleMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get clubRoleMember;

  /// No description provided for @clubVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get clubVerified;

  /// No description provided for @clubMembersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get clubMembersTitle;

  /// No description provided for @clubMembersPrivate.
  ///
  /// In fr, this message translates to:
  /// **'La liste des membres est réservée aux membres du club.'**
  String get clubMembersPrivate;

  /// No description provided for @clubMembersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre à afficher.'**
  String get clubMembersEmpty;

  /// No description provided for @clubJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le club'**
  String get clubJoin;

  /// No description provided for @clubJoined.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans le club !'**
  String get clubJoined;

  /// No description provided for @clubRequestJoin.
  ///
  /// In fr, this message translates to:
  /// **'Demander à rejoindre'**
  String get clubRequestJoin;

  /// No description provided for @clubRequestMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message (facultatif)'**
  String get clubRequestMessage;

  /// No description provided for @clubRequestSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get clubRequestSend;

  /// No description provided for @clubRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get clubRequestSent;

  /// No description provided for @clubRequestPending.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande d\'adhésion est en attente de validation.'**
  String get clubRequestPending;

  /// No description provided for @clubRequestCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ma demande'**
  String get clubRequestCancel;

  /// No description provided for @clubInviteOnlyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ce club accepte uniquement les membres invités.'**
  String get clubInviteOnlyNotice;

  /// No description provided for @clubLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le club'**
  String get clubLeave;

  /// No description provided for @clubLeaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String clubLeaveConfirm(String name);

  /// No description provided for @clubAdminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Administration du club'**
  String get clubAdminTitle;

  /// No description provided for @clubInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un motard'**
  String get clubInvite;

  /// No description provided for @clubInviteSend.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get clubInviteSend;

  /// No description provided for @clubInviteSent.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée à {name}'**
  String clubInviteSent(String name);

  /// No description provided for @clubRequestsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande d\'adhésion en attente.'**
  String get clubRequestsNone;

  /// No description provided for @clubInvitationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitation à rejoindre « {club} »'**
  String clubInvitationTitle(String club);

  /// No description provided for @clubInvitationFrom.
  ///
  /// In fr, this message translates to:
  /// **'De la part de {name}'**
  String clubInvitationFrom(String name);

  /// No description provided for @clubSetRole.
  ///
  /// In fr, this message translates to:
  /// **'Nommer {role}'**
  String clubSetRole(String role);

  /// No description provided for @clubRemoveMember.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du club'**
  String get clubRemoveMember;

  /// No description provided for @clubRemoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} du club ?'**
  String clubRemoveConfirm(String name);

  /// No description provided for @clubTransferOwnership.
  ///
  /// In fr, this message translates to:
  /// **'Transférer la propriété'**
  String get clubTransferOwnership;

  /// No description provided for @clubTransferConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Faire de {name} le propriétaire du club ? Vous deviendrez administrateur.'**
  String clubTransferConfirm(String name);

  /// No description provided for @clubVerificationRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demander la vérification'**
  String get clubVerificationRequest;

  /// No description provided for @clubVerificationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Présentez votre club (ancienneté, références…)'**
  String get clubVerificationMessage;

  /// No description provided for @clubVerificationSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande de vérification envoyée'**
  String get clubVerificationSent;

  /// No description provided for @clubVerificationPending.
  ///
  /// In fr, this message translates to:
  /// **'Demande de vérification en cours d\'examen par l\'équipe Rider Group.'**
  String get clubVerificationPending;

  /// No description provided for @clubVerificationRejected.
  ///
  /// In fr, this message translates to:
  /// **'La précédente demande de vérification a été refusée.'**
  String get clubVerificationRejected;

  /// No description provided for @clubVerificationHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le badge est facultatif et accordé après examen par l\'équipe Rider Group.'**
  String get clubVerificationHelp;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre accès Internet et réessayez.'**
  String get errorNetwork;

  /// No description provided for @errorBackendUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n\'est pas configuré sur cette version de l\'application.'**
  String get errorBackendUnavailable;

  /// No description provided for @errorNotAuthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous.'**
  String get errorNotAuthenticated;

  /// No description provided for @errorNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée'**
  String get errorNotAllowed;

  /// No description provided for @errorInvalidInput.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides'**
  String get errorInvalidInput;

  /// No description provided for @errorAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Cette valeur est déjà utilisée.'**
  String get errorAlreadyExists;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre adresse e-mail avant de vous connecter.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorUserAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse e-mail.'**
  String get errorUserAlreadyExists;

  /// No description provided for @errorWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible.'**
  String get errorWeakPassword;

  /// No description provided for @errorRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez plus tard.'**
  String get errorRateLimited;

  /// No description provided for @errorClubNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Club introuvable'**
  String get errorClubNotFound;

  /// No description provided for @errorClubNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom de club est déjà pris.'**
  String get errorClubNameTaken;

  /// No description provided for @errorClubSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Ce club est suspendu.'**
  String get errorClubSuspended;

  /// No description provided for @errorAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déjà membre de ce club.'**
  String get errorAlreadyMember;

  /// No description provided for @errorNotMember.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne n\'est pas membre du club.'**
  String get errorNotMember;

  /// No description provided for @errorInvitationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce club n\'accepte que les membres invités.'**
  String get errorInvitationRequired;

  /// No description provided for @errorRequestNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande n\'existe plus.'**
  String get errorRequestNotFound;

  /// No description provided for @errorInvitationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation n\'est plus valide.'**
  String get errorInvitationNotFound;

  /// No description provided for @errorOwnerCannotLeave.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire doit transférer la propriété avant de quitter le club.'**
  String get errorOwnerCannotLeave;

  /// No description provided for @errorUseTransferOwnership.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le transfert de propriété.'**
  String get errorUseTransferOwnership;

  /// No description provided for @errorUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motard trouvé avec ce pseudonyme.'**
  String get errorUserNotFound;

  /// No description provided for @errorAlreadyVerified.
  ///
  /// In fr, this message translates to:
  /// **'Ce club est déjà vérifié.'**
  String get errorAlreadyVerified;

  /// No description provided for @errorVerificationPending.
  ///
  /// In fr, this message translates to:
  /// **'Une demande de vérification est déjà en cours.'**
  String get errorVerificationPending;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue.'**
  String get errorUnknown;

  /// No description provided for @clubMemberCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun membre} =1{1 membre} other{{count} membres}}'**
  String clubMemberCount(int count);

  /// No description provided for @homeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeSeeAll;

  /// No description provided for @signInForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get signInForgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre adresse e-mail : vous recevrez un lien pour choisir un nouveau mot de passe.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordAction.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPasswordAction;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte correspond à cette adresse, un e-mail vient d\'être envoyé. Ouvrez le lien depuis ce téléphone.'**
  String get forgotPasswordSent;

  /// No description provided for @backToSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToSignIn;

  /// No description provided for @newPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot de passe que vous n\'utilisez nulle part ailleurs.'**
  String get newPasswordSubtitle;

  /// No description provided for @fieldNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get fieldNewPassword;

  /// No description provided for @newPasswordSaved.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour.'**
  String get newPasswordSaved;

  /// No description provided for @profileHidden.
  ///
  /// In fr, this message translates to:
  /// **'Profil masqué'**
  String get profileHidden;

  /// No description provided for @profilePhotoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get profilePhotoRemove;

  /// No description provided for @profileAccountSection.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileAccountSection;

  /// No description provided for @profileChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer de mot de passe'**
  String get profileChangePassword;

  /// No description provided for @privacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get privacyTitle;

  /// No description provided for @privacyDiscoverable.
  ///
  /// In fr, this message translates to:
  /// **'Profil visible par tous les motards'**
  String get privacyDiscoverable;

  /// No description provided for @privacyDiscoverableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, seuls les membres de vos clubs voient votre profil, et personne ne peut vous trouver par pseudonyme.'**
  String get privacyDiscoverableHelp;

  /// No description provided for @privacyInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Accepter les invitations de clubs'**
  String get privacyInvitations;

  /// No description provided for @privacyInvitationsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, aucun club ne peut vous inviter. Vous pouvez toujours demander à rejoindre un club.'**
  String get privacyInvitationsHelp;

  /// No description provided for @privacyEmailNotice.
  ///
  /// In fr, this message translates to:
  /// **'Votre adresse e-mail n\'est jamais visible par les autres utilisateurs.'**
  String get privacyEmailNotice;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountIntro.
  ///
  /// In fr, this message translates to:
  /// **'La suppression de votre compte est définitive.'**
  String get deleteAccountIntro;

  /// No description provided for @deleteAccountConsequences.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil, votre photo, vos adhésions, vos participations, vos demandes et vos invitations seront supprimés. Les balades terminées que vous avez organisées restent dans l\'historique des participants, sans votre nom. Cette action est irréversible.'**
  String get deleteAccountConsequences;

  /// No description provided for @deleteAccountSoloClubs.
  ///
  /// In fr, this message translates to:
  /// **'Ces clubs, dont vous êtes le seul membre, seront supprimés : {clubs}'**
  String deleteAccountSoloClubs(String clubs);

  /// No description provided for @deleteAccountBlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transférez d\'abord vos clubs'**
  String get deleteAccountBlockedTitle;

  /// No description provided for @deleteAccountBlockedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes propriétaire de clubs qui comptent d\'autres membres : {clubs}. Transférez-en la propriété depuis la fiche du club avant de supprimer votre compte.'**
  String deleteAccountBlockedBody(String clubs);

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tapez {word} pour confirmer'**
  String deleteAccountTypeToConfirm(String word);

  /// No description provided for @deleteAccountAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountDone.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a été supprimé.'**
  String get deleteAccountDone;

  /// No description provided for @clubImagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Logo et couverture'**
  String get clubImagesTitle;

  /// No description provided for @clubLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get clubLogo;

  /// No description provided for @clubCover.
  ///
  /// In fr, this message translates to:
  /// **'Image de couverture'**
  String get clubCover;

  /// No description provided for @clubImageNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image'**
  String get clubImageNone;

  /// No description provided for @clubImageSet.
  ///
  /// In fr, this message translates to:
  /// **'Image enregistrée'**
  String get clubImageSet;

  /// No description provided for @clubImageChange.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get clubImageChange;

  /// No description provided for @errorInvitationsDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce motard n\'accepte pas les invitations de clubs.'**
  String get errorInvitationsDisabled;

  /// No description provided for @errorOwnsClubsWithMembers.
  ///
  /// In fr, this message translates to:
  /// **'Transférez d\'abord la propriété de vos clubs qui comptent d\'autres membres.'**
  String get errorOwnsClubsWithMembers;

  /// No description provided for @errorSamePassword.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe doit être différent de l\'ancien.'**
  String get errorSamePassword;

  /// No description provided for @errorUnsupportedImage.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'image non pris en charge (JPEG, PNG ou WebP).'**
  String get errorUnsupportedImage;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Image trop volumineuse.'**
  String get errorImageTooLarge;

  /// No description provided for @bikeAny.
  ///
  /// In fr, this message translates to:
  /// **'Toutes motos'**
  String get bikeAny;

  /// No description provided for @bikeScooter.
  ///
  /// In fr, this message translates to:
  /// **'Scooter'**
  String get bikeScooter;

  /// No description provided for @bikeRoadster.
  ///
  /// In fr, this message translates to:
  /// **'Roadster'**
  String get bikeRoadster;

  /// No description provided for @bikeSport.
  ///
  /// In fr, this message translates to:
  /// **'Sportive'**
  String get bikeSport;

  /// No description provided for @bikeTrail.
  ///
  /// In fr, this message translates to:
  /// **'Trail'**
  String get bikeTrail;

  /// No description provided for @bikeEnduro.
  ///
  /// In fr, this message translates to:
  /// **'Enduro / tout-terrain'**
  String get bikeEnduro;

  /// No description provided for @bikeCustom.
  ///
  /// In fr, this message translates to:
  /// **'Custom'**
  String get bikeCustom;

  /// No description provided for @bikeTouring.
  ///
  /// In fr, this message translates to:
  /// **'Routière'**
  String get bikeTouring;

  /// No description provided for @bikeQuad.
  ///
  /// In fr, this message translates to:
  /// **'Quad'**
  String get bikeQuad;

  /// No description provided for @clubRidesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Balades du club'**
  String get clubRidesTitle;

  /// No description provided for @clubRidesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune balade du club à venir.'**
  String get clubRidesEmpty;

  /// No description provided for @clubOrganizeRide.
  ///
  /// In fr, this message translates to:
  /// **'Organiser une balade du club'**
  String get clubOrganizeRide;

  /// No description provided for @errorRideNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Balade introuvable'**
  String get errorRideNotFound;

  /// No description provided for @errorRideNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'Cette balade ne peut plus être modifiée.'**
  String get errorRideNotEditable;

  /// No description provided for @errorRideNotJoinable.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions à cette balade sont fermées.'**
  String get errorRideNotJoinable;

  /// No description provided for @errorRideFull.
  ///
  /// In fr, this message translates to:
  /// **'Cette balade est complète.'**
  String get errorRideFull;

  /// No description provided for @errorInvalidTransition.
  ///
  /// In fr, this message translates to:
  /// **'Ce changement de statut n\'est pas possible.'**
  String get errorInvalidTransition;

  /// No description provided for @errorAlreadyParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Vous participez déjà à cette balade.'**
  String get errorAlreadyParticipant;

  /// No description provided for @errorNotParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne ne participe pas à la balade.'**
  String get errorNotParticipant;

  /// No description provided for @errorRemovedFromRide.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez été retiré de cette balade par l\'organisateur.'**
  String get errorRemovedFromRide;

  /// No description provided for @errorOrganizerCannotLeave.
  ///
  /// In fr, this message translates to:
  /// **'L\'organisateur ne peut pas quitter sa balade : annulez-la si nécessaire.'**
  String get errorOrganizerCannotLeave;

  /// No description provided for @errorClubMembersOnly.
  ///
  /// In fr, this message translates to:
  /// **'Balade réservée aux membres du club.'**
  String get errorClubMembersOnly;

  /// No description provided for @errorStartInPast.
  ///
  /// In fr, this message translates to:
  /// **'La date de départ doit être dans le futur.'**
  String get errorStartInPast;

  /// No description provided for @errorCapacityBelowParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Le nombre maximal ne peut pas être inférieur au nombre de participants inscrits.'**
  String get errorCapacityBelowParticipants;

  /// No description provided for @privacyRideInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Accepter les invitations aux balades'**
  String get privacyRideInvitations;

  /// No description provided for @privacyRideInvitationsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, aucun organisateur ne peut vous inviter à une balade.'**
  String get privacyRideInvitationsHelp;

  /// No description provided for @ridesOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Les balades nécessitent une connexion au serveur Rider Group.'**
  String get ridesOfflineBody;

  /// No description provided for @ridesTabUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get ridesTabUpcoming;

  /// No description provided for @ridesTabMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes balades'**
  String get ridesTabMine;

  /// No description provided for @ridesSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher : titre, ville, lieu'**
  String get ridesSearchHint;

  /// No description provided for @ridesUpcomingEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune balade à venir'**
  String get ridesUpcomingEmptyTitle;

  /// No description provided for @ridesUpcomingEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Organisez la première balade de votre ville !'**
  String get ridesUpcomingEmptyBody;

  /// No description provided for @ridesMineEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune balade pour vous'**
  String get ridesMineEmptyTitle;

  /// No description provided for @ridesMineEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez une balade ou organisez la vôtre.'**
  String get ridesMineEmptyBody;

  /// No description provided for @ridesSectionUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir et en cours'**
  String get ridesSectionUpcoming;

  /// No description provided for @ridesSectionDrafts.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get ridesSectionDrafts;

  /// No description provided for @ridesSectionPast.
  ///
  /// In fr, this message translates to:
  /// **'Terminées ou annulées'**
  String get ridesSectionPast;

  /// No description provided for @rideCreate.
  ///
  /// In fr, this message translates to:
  /// **'Organiser une balade'**
  String get rideCreate;

  /// No description provided for @rideEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la balade'**
  String get rideEdit;

  /// No description provided for @rideEditNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Seul l\'organisateur (ou un administrateur du club) peut modifier cette balade avant son départ.'**
  String get rideEditNotAllowed;

  /// No description provided for @rideNotFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette balade n\'existe pas ou ne vous est pas accessible.'**
  String get rideNotFoundBody;

  /// No description provided for @rideDeleteDraft.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le brouillon'**
  String get rideDeleteDraft;

  /// No description provided for @rideDeleteDraftConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ce brouillon ?'**
  String get rideDeleteDraftConfirm;

  /// No description provided for @rideFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la balade'**
  String get rideFieldTitle;

  /// No description provided for @rideSectionWhen.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get rideSectionWhen;

  /// No description provided for @rideFieldTimezone.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau horaire'**
  String get rideFieldTimezone;

  /// No description provided for @timezoneKinshasa.
  ///
  /// In fr, this message translates to:
  /// **'Heure de Kinshasa (UTC+1)'**
  String get timezoneKinshasa;

  /// No description provided for @timezoneLubumbashi.
  ///
  /// In fr, this message translates to:
  /// **'Heure de Lubumbashi (UTC+2)'**
  String get timezoneLubumbashi;

  /// No description provided for @rideSectionWhere.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get rideSectionWhere;

  /// No description provided for @rideFieldStart.
  ///
  /// In fr, this message translates to:
  /// **'Point de départ'**
  String get rideFieldStart;

  /// No description provided for @rideFieldDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get rideFieldDestination;

  /// No description provided for @rideFieldItinerary.
  ///
  /// In fr, this message translates to:
  /// **'Étapes et pauses'**
  String get rideFieldItinerary;

  /// No description provided for @rideFieldItineraryHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : départ 8 h, pause carburant à Maluku, déjeuner à Kinkole.'**
  String get rideFieldItineraryHelp;

  /// No description provided for @rideSectionRiders.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get rideSectionRiders;

  /// No description provided for @rideFieldDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de difficulté'**
  String get rideFieldDifficulty;

  /// No description provided for @rideDifficultyEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get rideDifficultyEasy;

  /// No description provided for @rideDifficultyModerate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get rideDifficultyModerate;

  /// No description provided for @rideDifficultyHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get rideDifficultyHard;

  /// No description provided for @rideDifficultyExpert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get rideDifficultyExpert;

  /// No description provided for @rideFieldBikeTypes.
  ///
  /// In fr, this message translates to:
  /// **'Motos recommandées'**
  String get rideFieldBikeTypes;

  /// No description provided for @rideFieldMaxParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximal de participants'**
  String get rideFieldMaxParticipants;

  /// No description provided for @rideFieldMaxParticipantsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif, organisateur compris (2 à 500).'**
  String get rideFieldMaxParticipantsHelp;

  /// No description provided for @rideFieldConditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions de participation'**
  String get rideFieldConditions;

  /// No description provided for @rideFieldConditionsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : casque et gants obligatoires, permis valide, réservoir plein au départ.'**
  String get rideFieldConditionsHelp;

  /// No description provided for @rideFieldOrganizedBy.
  ///
  /// In fr, this message translates to:
  /// **'Organisée par'**
  String get rideFieldOrganizedBy;

  /// No description provided for @rideOrganizedByMe.
  ///
  /// In fr, this message translates to:
  /// **'Moi (balade personnelle)'**
  String get rideOrganizedByMe;

  /// No description provided for @rideFieldOpenToNonMembers.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte aux motards hors du club'**
  String get rideFieldOpenToNonMembers;

  /// No description provided for @rideFieldOpenToNonMembersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, seuls les membres du club voient la balade et peuvent la rejoindre.'**
  String get rideFieldOpenToNonMembersHelp;

  /// No description provided for @rideFieldJoinPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Mode d\'adhésion'**
  String get rideFieldJoinPolicy;

  /// No description provided for @rideJoinOpen.
  ///
  /// In fr, this message translates to:
  /// **'Participation libre'**
  String get rideJoinOpen;

  /// No description provided for @rideJoinApproval.
  ///
  /// In fr, this message translates to:
  /// **'Sur approbation de l\'organisateur'**
  String get rideJoinApproval;

  /// No description provided for @rideJoinInviteOnly.
  ///
  /// In fr, this message translates to:
  /// **'Sur invitation uniquement'**
  String get rideJoinInviteOnly;

  /// No description provided for @rideSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer en brouillon'**
  String get rideSaveDraft;

  /// No description provided for @rideVisibilityPublic.
  ///
  /// In fr, this message translates to:
  /// **'Publique'**
  String get rideVisibilityPublic;

  /// No description provided for @rideVisibilityPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privée'**
  String get rideVisibilityPrivate;

  /// No description provided for @rideVisibilityClub.
  ///
  /// In fr, this message translates to:
  /// **'Balade de club'**
  String get rideVisibilityClub;

  /// No description provided for @rideOpenToAll.
  ///
  /// In fr, this message translates to:
  /// **'ouverte à tous'**
  String get rideOpenToAll;

  /// No description provided for @rideStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get rideStatusDraft;

  /// No description provided for @rideStatusPublished.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get rideStatusPublished;

  /// No description provided for @rideStatusLocked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillée'**
  String get rideStatusLocked;

  /// No description provided for @rideStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get rideStatusInProgress;

  /// No description provided for @rideStatusFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get rideStatusFinished;

  /// No description provided for @rideStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get rideStatusCancelled;

  /// No description provided for @rideJoinsClosed.
  ///
  /// In fr, this message translates to:
  /// **'inscriptions fermées'**
  String get rideJoinsClosed;

  /// No description provided for @rideActionPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get rideActionPublish;

  /// No description provided for @rideActionLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller'**
  String get rideActionLock;

  /// No description provided for @rideActionUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get rideActionUnlock;

  /// No description provided for @rideActionStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get rideActionStart;

  /// No description provided for @rideActionFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get rideActionFinish;

  /// No description provided for @rideActionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la balade'**
  String get rideActionCancel;

  /// No description provided for @rideCancelReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif, visible des participants)'**
  String get rideCancelReason;

  /// No description provided for @rideCancelledNoReason.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motif indiqué.'**
  String get rideCancelledNoReason;

  /// No description provided for @rideStartConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la balade maintenant ? Les participants verront qu\'elle est en cours.'**
  String get rideStartConfirm;

  /// No description provided for @rideFinishConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Marquer la balade comme terminée ? Cette action est définitive.'**
  String get rideFinishConfirm;

  /// No description provided for @rideClubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Club : {club}'**
  String rideClubLabel(String club);

  /// No description provided for @rideOrganizerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur : {name}'**
  String rideOrganizerLabel(String name);

  /// No description provided for @rideOrganizerRole.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get rideOrganizerRole;

  /// No description provided for @rideParticipantCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 participant} other{{count} participants}}'**
  String rideParticipantCount(int count);

  /// No description provided for @rideParticipantCapacity.
  ///
  /// In fr, this message translates to:
  /// **'{count} / {max} participants'**
  String rideParticipantCapacity(int count, int max);

  /// No description provided for @rideDraftNotice.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon : visible uniquement par vous. Publiez-le pour ouvrir les inscriptions.'**
  String get rideDraftNotice;

  /// No description provided for @rideYouOrganize.
  ///
  /// In fr, this message translates to:
  /// **'Vous organisez cette balade.'**
  String get rideYouOrganize;

  /// No description provided for @rideYouParticipate.
  ///
  /// In fr, this message translates to:
  /// **'Vous participez à cette balade.'**
  String get rideYouParticipate;

  /// No description provided for @rideRemovedNotice.
  ///
  /// In fr, this message translates to:
  /// **'L\'organisateur vous a retiré de cette balade.'**
  String get rideRemovedNotice;

  /// No description provided for @rideRequestPending.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande de participation attend la décision de l\'organisateur.'**
  String get rideRequestPending;

  /// No description provided for @rideRequestPendingShort.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get rideRequestPendingShort;

  /// No description provided for @rideJoinsClosedNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions sont fermées (balade verrouillée par l\'organisateur).'**
  String get rideJoinsClosedNotice;

  /// No description provided for @rideJoin.
  ///
  /// In fr, this message translates to:
  /// **'Participer'**
  String get rideJoin;

  /// No description provided for @rideJoined.
  ///
  /// In fr, this message translates to:
  /// **'Vous participez à la balade !'**
  String get rideJoined;

  /// No description provided for @rideRequestJoin.
  ///
  /// In fr, this message translates to:
  /// **'Demander à participer'**
  String get rideRequestJoin;

  /// No description provided for @rideInviteOnlyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Cette balade accepte uniquement les motards invités par l\'organisateur.'**
  String get rideInviteOnlyNotice;

  /// No description provided for @rideLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la balade'**
  String get rideLeave;

  /// No description provided for @rideLeaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus participer à « {title} » ?'**
  String rideLeaveConfirm(String title);

  /// No description provided for @rideManageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de la balade'**
  String get rideManageTitle;

  /// No description provided for @rideNoMoreActions.
  ///
  /// In fr, this message translates to:
  /// **'La balade est close : plus aucune action n\'est possible.'**
  String get rideNoMoreActions;

  /// No description provided for @rideLockedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillée : aucune nouvelle inscription (y compris par invitation ou approbation). Les participants inscrits restent.'**
  String get rideLockedHelp;

  /// No description provided for @rideInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un motard'**
  String get rideInvite;

  /// No description provided for @rideRequestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de participation'**
  String get rideRequestsTitle;

  /// No description provided for @rideParticipantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get rideParticipantsTitle;

  /// No description provided for @rideParticipantsHidden.
  ///
  /// In fr, this message translates to:
  /// **'La liste des participants est réservée aux participants de cette balade.'**
  String get rideParticipantsHidden;

  /// No description provided for @rideRemoveParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la balade'**
  String get rideRemoveParticipant;

  /// No description provided for @rideRemoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} de la balade ? Cette personne ne pourra pas revenir d\'elle-même.'**
  String rideRemoveConfirm(String name);

  /// No description provided for @rideInvitationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitation à la balade « {title} »'**
  String rideInvitationTitle(String title);

  /// No description provided for @validationRideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre 3 et 100 caractères'**
  String get validationRideTitle;

  /// No description provided for @validationRidePlace.
  ///
  /// In fr, this message translates to:
  /// **'Entre 2 et 120 caractères'**
  String get validationRidePlace;

  /// No description provided for @validationMaxParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Entre 2 et 500, ou laisser vide'**
  String get validationMaxParticipants;

  /// No description provided for @validationBikeTypes.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un type de moto.'**
  String get validationBikeTypes;

  /// No description provided for @rideOrganizerDeleted.
  ///
  /// In fr, this message translates to:
  /// **'compte supprimé'**
  String get rideOrganizerDeleted;

  /// No description provided for @errorOrganizesActiveRides.
  ///
  /// In fr, this message translates to:
  /// **'Annulez d\'abord les balades que vous organisez et qui comptent d\'autres inscrits.'**
  String get errorOrganizesActiveRides;

  /// No description provided for @deleteAccountBlockedRidesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annulez d\'abord vos balades actives'**
  String get deleteAccountBlockedRidesTitle;

  /// No description provided for @deleteAccountBlockedRidesBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous organisez des balades qui comptent d\'autres inscrits : {rides}. Annulez-les depuis leur fiche avant de supprimer votre compte.'**
  String deleteAccountBlockedRidesBody(String rides);

  /// No description provided for @errorSignupDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions par e-mail sont désactivées sur le serveur. Contactez l\'administrateur de Rider Group.'**
  String get errorSignupDisabled;

  /// No description provided for @convoyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode Convoi'**
  String get convoyTitle;

  /// No description provided for @convoyOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le mode Convoi'**
  String get convoyOpen;

  /// No description provided for @convoySafety.
  ///
  /// In fr, this message translates to:
  /// **'Ne manipulez pas le téléphone en roulant : arrêtez-vous en lieu sûr.'**
  String get convoySafety;

  /// No description provided for @convoyStartSharing.
  ///
  /// In fr, this message translates to:
  /// **'Partager ma position'**
  String get convoyStartSharing;

  /// No description provided for @convoyStopSharing.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le partage'**
  String get convoyStopSharing;

  /// No description provided for @convoySharingOff.
  ///
  /// In fr, this message translates to:
  /// **'Votre position n\'est pas partagée.'**
  String get convoySharingOff;

  /// No description provided for @convoySharingStarting.
  ///
  /// In fr, this message translates to:
  /// **'Activation du partage…'**
  String get convoySharingStarting;

  /// No description provided for @convoyWaitingFix.
  ///
  /// In fr, this message translates to:
  /// **'Partage actif — recherche du signal GPS…'**
  String get convoyWaitingFix;

  /// No description provided for @convoyLastSent.
  ///
  /// In fr, this message translates to:
  /// **'Partage actif — dernière position envoyée à {time}. Il s\'arrête si vous quittez cet écran.'**
  String convoyLastSent(String time);

  /// No description provided for @convoyNotSent.
  ///
  /// In fr, this message translates to:
  /// **'Position NON transmise (réseau ?). Nouvel essai automatique.'**
  String get convoyNotSent;

  /// No description provided for @convoyLocationOff.
  ///
  /// In fr, this message translates to:
  /// **'La localisation du téléphone est désactivée. Activez-la dans les réglages.'**
  String get convoyLocationOff;

  /// No description provided for @convoyLocationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Rider Group n\'a pas l\'autorisation d\'utiliser votre position.'**
  String get convoyLocationDenied;

  /// No description provided for @convoyLocationDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation refusée définitivement : modifiez-la dans les réglages du téléphone.'**
  String get convoyLocationDeniedForever;

  /// No description provided for @convoyNotRunningTitle.
  ///
  /// In fr, this message translates to:
  /// **'La balade n\'est pas en cours'**
  String get convoyNotRunningTitle;

  /// No description provided for @convoyNotRunningBody.
  ///
  /// In fr, this message translates to:
  /// **'Le mode Convoi est disponible uniquement pendant la balade.'**
  String get convoyNotRunningBody;

  /// No description provided for @convoyParticipantsOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le mode Convoi est réservé aux participants confirmés.'**
  String get convoyParticipantsOnly;

  /// No description provided for @convoyYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get convoyYou;

  /// No description provided for @convoyRoleLeader.
  ///
  /// In fr, this message translates to:
  /// **'chef de convoi'**
  String get convoyRoleLeader;

  /// No description provided for @convoyRoleSweeper.
  ///
  /// In fr, this message translates to:
  /// **'serre-file'**
  String get convoyRoleSweeper;

  /// No description provided for @convoyNotSharing.
  ///
  /// In fr, this message translates to:
  /// **'Ne partage pas sa position'**
  String get convoyNotSharing;

  /// No description provided for @convoyLive.
  ///
  /// In fr, this message translates to:
  /// **'Position à jour'**
  String get convoyLive;

  /// No description provided for @convoyAging.
  ///
  /// In fr, this message translates to:
  /// **'Position de plus d\'une minute'**
  String get convoyAging;

  /// No description provided for @convoyStale.
  ///
  /// In fr, this message translates to:
  /// **'Position ancienne ({minutes} min) : réseau absent ou arrêt — à vérifier'**
  String convoyStale(int minutes);

  /// No description provided for @convoySeparated.
  ///
  /// In fr, this message translates to:
  /// **'À {km} km du chef de convoi — peut-être séparé'**
  String convoySeparated(String km);

  /// No description provided for @convoyAssignRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle de convoi'**
  String get convoyAssignRole;

  /// No description provided for @convoyMakeLeader.
  ///
  /// In fr, this message translates to:
  /// **'Nommer chef de convoi'**
  String get convoyMakeLeader;

  /// No description provided for @convoyMakeSweeper.
  ///
  /// In fr, this message translates to:
  /// **'Nommer serre-file'**
  String get convoyMakeSweeper;

  /// No description provided for @convoyClearRole.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le rôle de convoi'**
  String get convoyClearRole;

  /// No description provided for @errorRideNotInProgress.
  ///
  /// In fr, this message translates to:
  /// **'La balade n\'est pas en cours : le partage de position est arrêté.'**
  String get errorRideNotInProgress;

  /// No description provided for @errorSharingDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Le partage de position est désactivé.'**
  String get errorSharingDisabled;

  /// No description provided for @errorAlertClosed.
  ///
  /// In fr, this message translates to:
  /// **'Cette alerte est déjà close.'**
  String get errorAlertClosed;

  /// No description provided for @errorOwnAlert.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas accuser réception de votre propre alerte.'**
  String get errorOwnAlert;

  /// No description provided for @sosTitle.
  ///
  /// In fr, this message translates to:
  /// **'SOS et assistance'**
  String get sosTitle;

  /// No description provided for @sosOpen.
  ///
  /// In fr, this message translates to:
  /// **'SOS'**
  String get sosOpen;

  /// No description provided for @sosDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Rider Group prévient les participants de la balade. Ce n\'est pas un service de secours : en cas de danger, appelez les secours.'**
  String get sosDisclaimer;

  /// No description provided for @sosCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le {number}'**
  String sosCall(String number);

  /// No description provided for @sosCallFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le téléphone. Composez le {number} vous-même.'**
  String sosCallFailed(String number);

  /// No description provided for @sosChooseKind.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il ?'**
  String get sosChooseKind;

  /// No description provided for @sosKindBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Panne'**
  String get sosKindBreakdown;

  /// No description provided for @sosKindAccident.
  ///
  /// In fr, this message translates to:
  /// **'Accident'**
  String get sosKindAccident;

  /// No description provided for @sosKindAssistance.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide'**
  String get sosKindAssistance;

  /// No description provided for @sosKindDelay.
  ///
  /// In fr, this message translates to:
  /// **'Je suis en retard'**
  String get sosKindDelay;

  /// No description provided for @sosConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'alerte « {kind} » ?'**
  String sosConfirmTitle(String kind);

  /// No description provided for @sosConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Les participants de la balade recevront votre alerte et votre dernière position connue.'**
  String get sosConfirmBody;

  /// No description provided for @sosConfirmSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'alerte'**
  String get sosConfirmSend;

  /// No description provided for @sosSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours… L\'alerte n\'est PAS encore transmise.'**
  String get sosSending;

  /// No description provided for @sosFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'ALERTE NON TRANSMISE'**
  String get sosFailedTitle;

  /// No description provided for @sosFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a été prévenu. Réessayez ou appelez directement.'**
  String get sosFailedBody;

  /// No description provided for @sosRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer l\'envoi'**
  String get sosRetry;

  /// No description provided for @sosAbandon.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get sosAbandon;

  /// No description provided for @sosSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alerte transmise à {time}'**
  String sosSentTitle(String time);

  /// No description provided for @sosNoAckYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'accusé de réception.'**
  String get sosNoAckYet;

  /// No description provided for @sosAckedBy.
  ///
  /// In fr, this message translates to:
  /// **'Vu par : {names}'**
  String sosAckedBy(String names);

  /// No description provided for @sosPositionDevice.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS envoyée'**
  String get sosPositionDevice;

  /// No description provided for @sosPositionConvoy.
  ///
  /// In fr, this message translates to:
  /// **'Dernière position du mode Convoi envoyée'**
  String get sosPositionConvoy;

  /// No description provided for @sosPositionNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune position disponible'**
  String get sosPositionNone;

  /// No description provided for @sosCancelMine.
  ///
  /// In fr, this message translates to:
  /// **'Annuler (fausse alerte)'**
  String get sosCancelMine;

  /// No description provided for @sosResolveMine.
  ///
  /// In fr, this message translates to:
  /// **'Problème résolu'**
  String get sosResolveMine;

  /// No description provided for @sosIncomingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alertes en cours'**
  String get sosIncomingTitle;

  /// No description provided for @sosIncomingFrom.
  ///
  /// In fr, this message translates to:
  /// **'{kind} — {name}'**
  String sosIncomingFrom(String kind, String name);

  /// No description provided for @sosSince.
  ///
  /// In fr, this message translates to:
  /// **'Depuis {time}'**
  String sosSince(String time);

  /// No description provided for @sosAck.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai vu, je m\'en occupe'**
  String get sosAck;

  /// No description provided for @sosAcked.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez accusé réception'**
  String get sosAcked;

  /// No description provided for @sosOpenMap.
  ///
  /// In fr, this message translates to:
  /// **'Voir sur la carte'**
  String get sosOpenMap;

  /// No description provided for @sosResolveByManager.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme résolue'**
  String get sosResolveByManager;

  /// No description provided for @sosClosedResolved.
  ///
  /// In fr, this message translates to:
  /// **'Alerte résolue'**
  String get sosClosedResolved;

  /// No description provided for @sosClosedCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Alerte annulée'**
  String get sosClosedCancelled;

  /// No description provided for @sosParticipantsOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le SOS est réservé aux participants de la balade en cours.'**
  String get sosParticipantsOnly;

  /// No description provided for @sosNotRunningBody.
  ///
  /// In fr, this message translates to:
  /// **'Le SOS est disponible pendant une balade en cours. En dehors, appelez directement les secours.'**
  String get sosNotRunningBody;

  /// No description provided for @sosBanner.
  ///
  /// In fr, this message translates to:
  /// **'SOS : {kind} dans votre balade'**
  String sosBanner(String kind);

  /// No description provided for @sosBannerMore.
  ///
  /// In fr, this message translates to:
  /// **'+{count} autre(s)'**
  String sosBannerMore(int count);

  /// No description provided for @sosBannerView.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get sosBannerView;

  /// No description provided for @sosBannerDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get sosBannerDismiss;

  /// No description provided for @settingsSafety.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get settingsSafety;

  /// No description provided for @settingsEmergencyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'appel d\'urgence'**
  String get settingsEmergencyNumber;

  /// No description provided for @settingsEmergencyNumberHint.
  ///
  /// In fr, this message translates to:
  /// **'Proposé sur l\'écran SOS. Sa disponibilité dépend du pays et de l\'opérateur.'**
  String get settingsEmergencyNumberHint;

  /// No description provided for @settingsEmergencyNumberInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (chiffres uniquement, + autorisé au début).'**
  String get settingsEmergencyNumberInvalid;

  /// No description provided for @blockAction.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {name}'**
  String blockAction(String name);

  /// No description provided for @blockShort.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get blockShort;

  /// No description provided for @blockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {name} ?'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne verrez plus ses publications ni ses commentaires, et vous ne pourrez plus vous écrire. Cette personne n\'est pas prévenue. Vous pourrez débloquer à tout moment depuis votre profil.'**
  String get blockBody;

  /// No description provided for @blockConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get blockConfirm;

  /// No description provided for @blockDone.
  ///
  /// In fr, this message translates to:
  /// **'{name} est bloqué.'**
  String blockDone(String name);

  /// No description provided for @unblockAction.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get unblockAction;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motards bloqués'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motard bloqué'**
  String get blockedUsersEmptyTitle;

  /// No description provided for @blockedUsersEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Depuis une publication ou un profil, le menu permet de bloquer un motard.'**
  String get blockedUsersEmptyBody;

  /// No description provided for @chatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conversation'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get chatSend;

  /// No description provided for @chatSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get chatSending;

  /// No description provided for @chatFailed.
  ///
  /// In fr, this message translates to:
  /// **'Non envoyé — touchez pour réessayer'**
  String get chatFailed;

  /// No description provided for @chatDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Message supprimé'**
  String get chatDeleted;

  /// No description provided for @chatHiddenNotice.
  ///
  /// In fr, this message translates to:
  /// **'Message masqué par la modération'**
  String get chatHiddenNotice;

  /// No description provided for @chatNoMessages.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour l\'instant'**
  String get chatNoMessages;

  /// No description provided for @chatBlockedNotice.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas écrire dans cette conversation (motard bloqué).'**
  String get chatBlockedNotice;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce message ?'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Il sera remplacé par « Message supprimé » pour tout le monde.'**
  String get chatDeleteBody;

  /// No description provided for @chatLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get chatLeave;

  /// No description provided for @chatLeaveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce groupe ?'**
  String get chatLeaveTitle;

  /// No description provided for @chatLeaveBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne recevrez plus ses messages.'**
  String get chatLeaveBody;

  /// No description provided for @chatSeeProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get chatSeeProfile;

  /// No description provided for @chatSeeRide.
  ///
  /// In fr, this message translates to:
  /// **'Voir la balade'**
  String get chatSeeRide;

  /// No description provided for @clubPostsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publications du club'**
  String get clubPostsTitle;

  /// No description provided for @clubNewPost.
  ///
  /// In fr, this message translates to:
  /// **'Publier dans le club'**
  String get clubNewPost;

  /// No description provided for @clubPostsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication dans ce club pour l\'instant.'**
  String get clubPostsEmpty;

  /// No description provided for @commentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commentaire. Soyez le premier !'**
  String get commentsEmpty;

  /// No description provided for @commentHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre commentaire'**
  String get commentHint;

  /// No description provided for @commentSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le commentaire'**
  String get commentSend;

  /// No description provided for @commentNotSent.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire non envoyé.'**
  String get commentNotSent;

  /// No description provided for @commentHiddenNotice.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire masqué par la modération'**
  String get commentHiddenNotice;

  /// No description provided for @errorBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible : l\'un de vous a bloqué l\'autre.'**
  String get errorBlocked;

  /// No description provided for @errorContentHidden.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu est masqué par la modération.'**
  String get errorContentHidden;

  /// No description provided for @errorConversationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette conversation n\'existe pas ou ne vous est plus accessible.'**
  String get errorConversationNotFound;

  /// No description provided for @feedLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les publications. Vérifiez votre connexion.'**
  String get feedLoadError;

  /// No description provided for @messagesNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau message'**
  String get messagesNew;

  /// No description provided for @moderationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get moderationTitle;

  /// No description provided for @moderationEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien à traiter'**
  String get moderationEmptyTitle;

  /// No description provided for @moderationEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement en attente.'**
  String get moderationEmptyBody;

  /// No description provided for @moderationReports.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 signalement} other{{count} signalements}}'**
  String moderationReports(int count);

  /// No description provided for @moderationAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Auteur : {name}'**
  String moderationAuthor(String name);

  /// No description provided for @moderationCurrentlyHidden.
  ///
  /// In fr, this message translates to:
  /// **'Actuellement masqué'**
  String get moderationCurrentlyHidden;

  /// No description provided for @moderationHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get moderationHide;

  /// No description provided for @moderationRestore.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get moderationRestore;

  /// No description provided for @moderationDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Classer sans suite'**
  String get moderationDismiss;

  /// No description provided for @moderationDone.
  ///
  /// In fr, this message translates to:
  /// **'Décision enregistrée.'**
  String get moderationDone;

  /// No description provided for @newConvDirect.
  ///
  /// In fr, this message translates to:
  /// **'Privée'**
  String get newConvDirect;

  /// No description provided for @newConvGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get newConvGroup;

  /// No description provided for @newConvUsername.
  ///
  /// In fr, this message translates to:
  /// **'Pseudonyme du motard'**
  String get newConvUsername;

  /// No description provided for @newConvOpen.
  ///
  /// In fr, this message translates to:
  /// **'Écrire'**
  String get newConvOpen;

  /// No description provided for @newConvGroupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get newConvGroupTitle;

  /// No description provided for @newConvAddMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ce motard'**
  String get newConvAddMember;

  /// No description provided for @newConvCreateGroup.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get newConvCreateGroup;

  /// No description provided for @newConvUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motard visible avec ce pseudonyme.'**
  String get newConvUserNotFound;

  /// No description provided for @postTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get postTitle;

  /// No description provided for @postNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle publication'**
  String get postNewTitle;

  /// No description provided for @postNewClubTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier dans le club'**
  String get postNewClubTitle;

  /// No description provided for @postPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get postPublish;

  /// No description provided for @postBodyHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez une sortie, une photo, un conseil…'**
  String get postBodyHint;

  /// No description provided for @postEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez un texte ou ajoutez une photo.'**
  String get postEmpty;

  /// No description provided for @postNotSent.
  ///
  /// In fr, this message translates to:
  /// **'Publication NON envoyée.'**
  String get postNotSent;

  /// No description provided for @postPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publication partagée.'**
  String get postPublished;

  /// No description provided for @postGuidelines.
  ///
  /// In fr, this message translates to:
  /// **'Restez respectueux. Les contenus signalés par plusieurs motards sont masqués en attendant la modération.'**
  String get postGuidelines;

  /// No description provided for @postAudiencePublic.
  ///
  /// In fr, this message translates to:
  /// **'Tous les motards'**
  String get postAudiencePublic;

  /// No description provided for @postAudienceClub.
  ///
  /// In fr, this message translates to:
  /// **'Membres du club'**
  String get postAudienceClub;

  /// No description provided for @postAudienceClubShort.
  ///
  /// In fr, this message translates to:
  /// **'membres'**
  String get postAudienceClubShort;

  /// No description provided for @postHiddenNotice.
  ///
  /// In fr, this message translates to:
  /// **'Masquée par la modération : visible seulement par vous et les modérateurs.'**
  String get postHiddenNotice;

  /// No description provided for @postDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette publication ?'**
  String get postDeleteTitle;

  /// No description provided for @postDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'La publication, ses photos et ses commentaires seront supprimés.'**
  String get postDeleteBody;

  /// No description provided for @postDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Publication supprimée.'**
  String get postDeleted;

  /// No description provided for @postNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publication introuvable'**
  String get postNotFoundTitle;

  /// No description provided for @postNotFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle a été supprimée, masquée, ou ne vous est pas accessible.'**
  String get postNotFoundBody;

  /// No description provided for @reactionLike.
  ///
  /// In fr, this message translates to:
  /// **'J\'aime'**
  String get reactionLike;

  /// No description provided for @reactionFire.
  ///
  /// In fr, this message translates to:
  /// **'En feu'**
  String get reactionFire;

  /// No description provided for @reactionRespect.
  ///
  /// In fr, this message translates to:
  /// **'Respect'**
  String get reactionRespect;

  /// No description provided for @reportAction.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reportAction;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler : {target}'**
  String reportTitle(String target);

  /// No description provided for @reportDetails.
  ///
  /// In fr, this message translates to:
  /// **'Précisions (facultatif)'**
  String get reportDetails;

  /// No description provided for @reportSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé. Merci.'**
  String get reportSent;

  /// No description provided for @reportTargetPost.
  ///
  /// In fr, this message translates to:
  /// **'publication'**
  String get reportTargetPost;

  /// No description provided for @reportTargetComment.
  ///
  /// In fr, this message translates to:
  /// **'commentaire'**
  String get reportTargetComment;

  /// No description provided for @reportTargetMessage.
  ///
  /// In fr, this message translates to:
  /// **'message'**
  String get reportTargetMessage;

  /// No description provided for @reportTargetUser.
  ///
  /// In fr, this message translates to:
  /// **'motard'**
  String get reportTargetUser;

  /// No description provided for @reportReasonSpam.
  ///
  /// In fr, this message translates to:
  /// **'Spam ou publicité'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In fr, this message translates to:
  /// **'Harcèlement ou insulte'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonHate.
  ///
  /// In fr, this message translates to:
  /// **'Haine ou discrimination'**
  String get reportReasonHate;

  /// No description provided for @reportReasonViolence.
  ///
  /// In fr, this message translates to:
  /// **'Violence ou danger'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonNudity.
  ///
  /// In fr, this message translates to:
  /// **'Nudité ou contenu sexuel'**
  String get reportReasonNudity;

  /// No description provided for @reportReasonScam.
  ///
  /// In fr, this message translates to:
  /// **'Arnaque'**
  String get reportReasonScam;

  /// No description provided for @reportReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reportReasonOther;

  /// No description provided for @rideOpenChat.
  ///
  /// In fr, this message translates to:
  /// **'Discussion de la balade'**
  String get rideOpenChat;

  /// No description provided for @riderProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motard'**
  String get riderProfileTitle;

  /// No description provided for @riderSendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get riderSendMessage;

  /// No description provided for @riderPostsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publications'**
  String get riderPostsTitle;

  /// No description provided for @riderNoPosts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication visible.'**
  String get riderNoPosts;

  /// No description provided for @riderBlockedNotice.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez bloqué ce motard.'**
  String get riderBlockedNotice;

  /// No description provided for @riderNotVisibleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil non visible'**
  String get riderNotVisibleTitle;

  /// No description provided for @riderNotVisibleBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce motard a choisi de limiter la visibilité de son profil.'**
  String get riderNotVisibleBody;

  /// No description provided for @timeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {minutes} min'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {hours} h'**
  String timeHoursAgo(int hours);

  /// No description provided for @buildLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version : {build}'**
  String buildLabel(String build);

  /// No description provided for @convoyRoleButton.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get convoyRoleButton;

  /// No description provided for @actionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get actionClose;

  /// No description provided for @actionEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get actionEdit;

  /// No description provided for @validationTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins {min} caractères'**
  String validationTooShort(int min);

  /// No description provided for @marketSell.
  ///
  /// In fr, this message translates to:
  /// **'Vendre'**
  String get marketSell;

  /// No description provided for @marketSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher : casque, Honda, pneu…'**
  String get marketSearchHint;

  /// No description provided for @marketFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get marketFilters;

  /// No description provided for @marketMaxPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix maximum'**
  String get marketMaxPrice;

  /// No description provided for @marketAnyCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get marketAnyCurrency;

  /// No description provided for @marketApplyFilters.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get marketApplyFilters;

  /// No description provided for @marketAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get marketAll;

  /// No description provided for @marketMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes annonces'**
  String get marketMine;

  /// No description provided for @marketFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get marketFavorites;

  /// No description provided for @marketSafety.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement dans Rider Group : la vente se conclut directement entre vous. Voyez l\'article avant de payer et méfiez-vous des demandes d\'avance.'**
  String get marketSafety;

  /// No description provided for @listingCatMotorcycle.
  ///
  /// In fr, this message translates to:
  /// **'Motos'**
  String get listingCatMotorcycle;

  /// No description provided for @listingCatParts.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get listingCatParts;

  /// No description provided for @listingCatHelmet.
  ///
  /// In fr, this message translates to:
  /// **'Casques'**
  String get listingCatHelmet;

  /// No description provided for @listingCatProtection.
  ///
  /// In fr, this message translates to:
  /// **'Protections'**
  String get listingCatProtection;

  /// No description provided for @listingCatAccessories.
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get listingCatAccessories;

  /// No description provided for @listingCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get listingCatOther;

  /// No description provided for @listingCondNew.
  ///
  /// In fr, this message translates to:
  /// **'Neuf'**
  String get listingCondNew;

  /// No description provided for @listingCondLikeNew.
  ///
  /// In fr, this message translates to:
  /// **'Comme neuf'**
  String get listingCondLikeNew;

  /// No description provided for @listingCondGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon état'**
  String get listingCondGood;

  /// No description provided for @listingCondFair.
  ///
  /// In fr, this message translates to:
  /// **'État correct'**
  String get listingCondFair;

  /// No description provided for @listingCondForParts.
  ///
  /// In fr, this message translates to:
  /// **'Pour pièces'**
  String get listingCondForParts;

  /// No description provided for @listingStatusAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get listingStatusAvailable;

  /// No description provided for @listingStatusReserved.
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get listingStatusReserved;

  /// No description provided for @listingStatusSold.
  ///
  /// In fr, this message translates to:
  /// **'Vendu'**
  String get listingStatusSold;

  /// No description provided for @listingStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statut de l\'annonce'**
  String get listingStatusTitle;

  /// No description provided for @listingPriceOnRequest.
  ///
  /// In fr, this message translates to:
  /// **'Prix à discuter'**
  String get listingPriceOnRequest;

  /// No description provided for @listingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annonce'**
  String get listingTitle;

  /// No description provided for @listingNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle annonce'**
  String get listingNewTitle;

  /// No description provided for @listingEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'annonce'**
  String get listingEditTitle;

  /// No description provided for @listingTitleField.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get listingTitleField;

  /// No description provided for @listingCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get listingCategory;

  /// No description provided for @listingCondition.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get listingCondition;

  /// No description provided for @listingPriceField.
  ///
  /// In fr, this message translates to:
  /// **'Prix indicatif'**
  String get listingPriceField;

  /// No description provided for @listingPriceHelper.
  ///
  /// In fr, this message translates to:
  /// **'Vide : prix à discuter'**
  String get listingPriceHelper;

  /// No description provided for @listingPriceInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get listingPriceInvalid;

  /// No description provided for @listingCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get listingCity;

  /// No description provided for @listingArea.
  ///
  /// In fr, this message translates to:
  /// **'Quartier ou commune (facultatif)'**
  String get listingArea;

  /// No description provided for @listingAreaHelper.
  ///
  /// In fr, this message translates to:
  /// **'Jamais d\'adresse exacte'**
  String get listingAreaHelper;

  /// No description provided for @listingPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos ({count}/10)'**
  String listingPhotos(int count);

  /// No description provided for @listingPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'annonce'**
  String get listingPublish;

  /// No description provided for @listingPublishedDone.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publiée.'**
  String get listingPublishedDone;

  /// No description provided for @listingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Annonce enregistrée.'**
  String get listingSaved;

  /// No description provided for @listingNotSent.
  ///
  /// In fr, this message translates to:
  /// **'Annonce NON envoyée.'**
  String get listingNotSent;

  /// No description provided for @listingNoPayment.
  ///
  /// In fr, this message translates to:
  /// **'Le prix est indicatif : aucun paiement ne passe par l\'application.'**
  String get listingNoPayment;

  /// No description provided for @listingPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiée {time}'**
  String listingPublished(String time);

  /// No description provided for @listingSeller.
  ///
  /// In fr, this message translates to:
  /// **'Vendeur'**
  String get listingSeller;

  /// No description provided for @listingContact.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le vendeur'**
  String get listingContact;

  /// No description provided for @listingContactDraft.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, votre annonce « {title} » est-elle toujours disponible ?'**
  String listingContactDraft(String title);

  /// No description provided for @listingHiddenNotice.
  ///
  /// In fr, this message translates to:
  /// **'Masquée par la modération : visible seulement par vous.'**
  String get listingHiddenNotice;

  /// No description provided for @listingNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annonce introuvable'**
  String get listingNotFoundTitle;

  /// No description provided for @listingNotFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle a été supprimée, masquée, ou ne vous est pas accessible.'**
  String get listingNotFoundBody;

  /// No description provided for @listingDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette annonce ?'**
  String get listingDeleteTitle;

  /// No description provided for @listingDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'annonce et ses photos seront supprimées.'**
  String get listingDeleteBody;

  /// No description provided for @listingDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Annonce supprimée.'**
  String get listingDeleted;

  /// No description provided for @reportTargetListing.
  ///
  /// In fr, this message translates to:
  /// **'annonce'**
  String get reportTargetListing;

  /// No description provided for @mapMyPosition.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get mapMyPosition;

  /// No description provided for @rideMapPointSet.
  ///
  /// In fr, this message translates to:
  /// **'Point pointé sur la carte ✓ (modifier)'**
  String get rideMapPointSet;

  /// No description provided for @rideMapClear.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le point'**
  String get rideMapClear;

  /// No description provided for @rideDistance.
  ///
  /// In fr, this message translates to:
  /// **'≈ {distance} à vol d\'oiseau'**
  String rideDistance(String distance);

  /// No description provided for @rideSeeStart.
  ///
  /// In fr, this message translates to:
  /// **'Voir le départ'**
  String get rideSeeStart;

  /// No description provided for @rideSeeDestination.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'arrivée'**
  String get rideSeeDestination;

  /// No description provided for @rideCoverAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo de couverture (facultatif)'**
  String get rideCoverAdd;

  /// No description provided for @rideCoverNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Balade enregistrée, mais la photo n\'a pas pu être envoyée. Réessayez depuis « Modifier ».'**
  String get rideCoverNotSaved;

  /// No description provided for @convoyTrailInfo.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire du chef de convoi · dernier point à {time}'**
  String convoyTrailInfo(String time);

  /// No description provided for @convoyTrailJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get convoyTrailJoin;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsReadAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notificationsReadAll;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes, invitations, réactions et changements de balade apparaîtront ici.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsDone.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait.'**
  String get notificationsDone;

  /// No description provided for @notifApprove.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get notifApprove;

  /// No description provided for @notifReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get notifReject;

  /// No description provided for @notifAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get notifAccept;

  /// No description provided for @notifDecline.
  ///
  /// In fr, this message translates to:
  /// **'Décliner'**
  String get notifDecline;

  /// No description provided for @notifRideJoinRequest.
  ///
  /// In fr, this message translates to:
  /// **'{who} demande à rejoindre « {ride} »'**
  String notifRideJoinRequest(String who, String ride);

  /// No description provided for @notifRideJoined.
  ///
  /// In fr, this message translates to:
  /// **'{who} a rejoint « {ride} »'**
  String notifRideJoined(String who, String ride);

  /// No description provided for @notifRideRequestApproved.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande pour « {ride} » est acceptée'**
  String notifRideRequestApproved(String ride);

  /// No description provided for @notifRideRequestRejected.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande pour « {ride} » n\'a pas été retenue'**
  String notifRideRequestRejected(String ride);

  /// No description provided for @notifRideRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez été retiré de « {ride} »'**
  String notifRideRemoved(String ride);

  /// No description provided for @notifRideInvitation.
  ///
  /// In fr, this message translates to:
  /// **'{who} vous invite à « {ride} »'**
  String notifRideInvitation(String who, String ride);

  /// No description provided for @notifRideLocked.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions à « {ride} » sont fermées'**
  String notifRideLocked(String ride);

  /// No description provided for @notifRideStarted.
  ///
  /// In fr, this message translates to:
  /// **'« {ride} » a démarré : ouvrez le mode Convoi'**
  String notifRideStarted(String ride);

  /// No description provided for @notifRideFinished.
  ///
  /// In fr, this message translates to:
  /// **'« {ride} » est terminée'**
  String notifRideFinished(String ride);

  /// No description provided for @notifRideCancelled.
  ///
  /// In fr, this message translates to:
  /// **'« {ride} » est annulée'**
  String notifRideCancelled(String ride);

  /// No description provided for @notifClubJoinRequest.
  ///
  /// In fr, this message translates to:
  /// **'{who} demande à rejoindre {club}'**
  String notifClubJoinRequest(String who, String club);

  /// No description provided for @notifClubRequestApproved.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans {club} : votre demande est acceptée'**
  String notifClubRequestApproved(String club);

  /// No description provided for @notifClubRequestRejected.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande pour {club} n\'a pas été retenue'**
  String notifClubRequestRejected(String club);

  /// No description provided for @notifClubInvitation.
  ///
  /// In fr, this message translates to:
  /// **'{who} vous invite à rejoindre {club}'**
  String notifClubInvitation(String who, String club);

  /// No description provided for @notifPostComment.
  ///
  /// In fr, this message translates to:
  /// **'{who} a commenté votre publication'**
  String notifPostComment(String who);

  /// No description provided for @notifPostReaction.
  ///
  /// In fr, this message translates to:
  /// **'{who} a réagi à votre publication'**
  String notifPostReaction(String who);

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons des notifications et messages'**
  String get settingsSounds;

  /// No description provided for @settingsSoundsHint.
  ///
  /// In fr, this message translates to:
  /// **'Quand l\'application est ouverte. Les alertes SOS sonnent toujours.'**
  String get settingsSoundsHint;

  /// No description provided for @verificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du club'**
  String get verificationTitle;

  /// No description provided for @verificationAdvantagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi faire vérifier votre club ?'**
  String get verificationAdvantagesTitle;

  /// No description provided for @verificationAdvantageBadge.
  ///
  /// In fr, this message translates to:
  /// **'Le badge « Vérifié » s\'affiche sur la fiche du club et dans la liste des clubs.'**
  String get verificationAdvantageBadge;

  /// No description provided for @verificationAdvantageTrust.
  ///
  /// In fr, this message translates to:
  /// **'Les motards savent que votre club a été contrôlé par l\'équipe Rider Group.'**
  String get verificationAdvantageTrust;

  /// No description provided for @verificationAdvantageName.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom est protégé : en cas de litige sur le nom d\'un club, l\'équipe tranche en faveur du club vérifié.'**
  String get verificationAdvantageName;

  /// No description provided for @verificationAdvantageRenewal.
  ///
  /// In fr, this message translates to:
  /// **'Le badge est valable pour une durée définie et se renouvelle sur demande.'**
  String get verificationAdvantageRenewal;

  /// No description provided for @verificationProcess.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe Rider Group examine votre demande et peut vous contacter au numéro indiqué. Vous êtes prévenu dans l\'application dès qu\'une décision est prise.'**
  String get verificationProcess;

  /// No description provided for @verificationOfficialName.
  ///
  /// In fr, this message translates to:
  /// **'Nom officiel du club'**
  String get verificationOfficialName;

  /// No description provided for @verificationContactName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du responsable'**
  String get verificationContactName;

  /// No description provided for @verificationPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp du responsable'**
  String get verificationPhone;

  /// No description provided for @verificationPhoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Format international, ex. +243 81 234 5678'**
  String get verificationPhoneHelp;

  /// No description provided for @verificationPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (8 à 15 chiffres, + autorisé au début)'**
  String get verificationPhoneInvalid;

  /// No description provided for @verificationDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents justificatifs ({count}/5)'**
  String verificationDocuments(int count);

  /// No description provided for @verificationDocumentsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : statuts, récépissé, pièce d\'identité du responsable. Visibles uniquement par votre club et l\'équipe Rider Group.'**
  String get verificationDocumentsHelp;

  /// No description provided for @verificationAddDocument.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un document'**
  String get verificationAddDocument;

  /// No description provided for @verificationDocumentN.
  ///
  /// In fr, this message translates to:
  /// **'Document {n}'**
  String verificationDocumentN(int n);

  /// No description provided for @verificationSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get verificationSubmit;

  /// No description provided for @verificationRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler la vérification'**
  String get verificationRenew;

  /// No description provided for @verificationExpiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Votre vérification expire le {date}.'**
  String verificationExpiresOn(String date);

  /// No description provided for @verificationValidUntil.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié jusqu\'au {date}'**
  String verificationValidUntil(String date);

  /// No description provided for @verificationRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la vérification'**
  String get verificationRevoke;

  /// No description provided for @verificationAdminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifications (équipe)'**
  String get verificationAdminTitle;

  /// No description provided for @verificationAdminEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente'**
  String get verificationAdminEmptyTitle;

  /// No description provided for @verificationAdminEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les nouvelles demandes de vérification apparaîtront ici.'**
  String get verificationAdminEmptyBody;

  /// No description provided for @verificationOfficialNameValue.
  ///
  /// In fr, this message translates to:
  /// **'Nom officiel : {name}'**
  String verificationOfficialNameValue(String name);

  /// No description provided for @verificationContactValue.
  ///
  /// In fr, this message translates to:
  /// **'Responsable : {name}'**
  String verificationContactValue(String name);

  /// No description provided for @verificationRequester.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée par {name}'**
  String verificationRequester(String name);

  /// No description provided for @verificationContactWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp {phone}'**
  String verificationContactWhatsApp(String phone);

  /// No description provided for @verificationApprove.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get verificationApprove;

  /// No description provided for @verificationReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get verificationReject;

  /// No description provided for @verificationNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultative)'**
  String get verificationNote;

  /// No description provided for @verificationDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée de la vérification'**
  String get verificationDuration;

  /// No description provided for @verificationMonths.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 mois} other{{count} mois}}'**
  String verificationMonths(int count);

  /// No description provided for @notifVerificationApproved.
  ///
  /// In fr, this message translates to:
  /// **'Votre club {club} est maintenant vérifié'**
  String notifVerificationApproved(String club);

  /// No description provided for @notifVerificationRejected.
  ///
  /// In fr, this message translates to:
  /// **'La demande de vérification de {club} n\'a pas été retenue'**
  String notifVerificationRejected(String club);

  /// No description provided for @notifVerificationExpiring.
  ///
  /// In fr, this message translates to:
  /// **'La vérification de {club} expire bientôt. Contactez l\'équipe Rider Group pour la renouveler.'**
  String notifVerificationExpiring(String club);

  /// No description provided for @notifVerificationExpired.
  ///
  /// In fr, this message translates to:
  /// **'La vérification de {club} a expiré'**
  String notifVerificationExpired(String club);

  /// No description provided for @verificationOneYear.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get verificationOneYear;

  /// No description provided for @sosMute.
  ///
  /// In fr, this message translates to:
  /// **'Couper le son'**
  String get sosMute;

  /// No description provided for @mapStepStart.
  ///
  /// In fr, this message translates to:
  /// **'1/2 · Lieu de départ'**
  String get mapStepStart;

  /// No description provided for @mapStepDestination.
  ///
  /// In fr, this message translates to:
  /// **'2/2 · Lieu d\'arrivée'**
  String get mapStepDestination;

  /// No description provided for @mapConfirmStart.
  ///
  /// In fr, this message translates to:
  /// **'Valider le départ'**
  String get mapConfirmStart;

  /// No description provided for @mapConfirmDestination.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'arrivée'**
  String get mapConfirmDestination;

  /// No description provided for @mapNoDestination.
  ///
  /// In fr, this message translates to:
  /// **'Sans lieu d\'arrivée'**
  String get mapNoDestination;

  /// No description provided for @rideMapPickRoute.
  ///
  /// In fr, this message translates to:
  /// **'Pointer départ et arrivée sur la carte (facultatif)'**
  String get rideMapPickRoute;
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
