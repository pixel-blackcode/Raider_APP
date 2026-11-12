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
  /// **'Demander le badge Vérifié'**
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
  /// **'Le badge est facultatif et accordé après examen par l\'équipe Rider Group. Il ne donne accès à aucune donnée privée.'**
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
