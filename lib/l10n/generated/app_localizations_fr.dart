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
      'Connectez-vous pour accéder à votre profil.';

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

  @override
  String get actionAccept => 'Accepter';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDecline => 'Refuser';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get errorTitle => 'Une erreur est survenue';

  @override
  String get signInTitle => 'Connexion';

  @override
  String get signInSubtitle => 'Retrouvez votre communauté de motards.';

  @override
  String get signInAction => 'Se connecter';

  @override
  String get signInNoAccount => 'Pas encore de compte ? Créer un compte';

  @override
  String get signUpTitle => 'Créer un compte';

  @override
  String get signUpSubtitle =>
      'Un seul compte, même si vous rejoignez plusieurs clubs.';

  @override
  String get signUpAction => 'Créer mon compte';

  @override
  String get signUpHaveAccount => 'Déjà inscrit ? Se connecter';

  @override
  String get signUpCheckEmail =>
      'Compte créé. Confirmez votre adresse e-mail grâce au lien reçu, puis connectez-vous.';

  @override
  String get signOutAction => 'Se déconnecter';

  @override
  String get fieldEmail => 'Adresse e-mail';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get fieldPasswordHelp =>
      '8 caractères minimum, dont une lettre et un chiffre';

  @override
  String get fieldPasswordConfirm => 'Confirmer le mot de passe';

  @override
  String get fieldDisplayName => 'Nom affiché';

  @override
  String get fieldUsername => 'Pseudonyme';

  @override
  String get fieldUsernameHelp => '3 à 30 caractères : minuscules, chiffres, _';

  @override
  String get fieldCity => 'Ville';

  @override
  String get fieldBio => 'Présentation';

  @override
  String get validationRequired => 'Champ obligatoire';

  @override
  String get validationEmail => 'Adresse e-mail invalide';

  @override
  String get validationPassword =>
      '8 caractères minimum, dont une lettre et un chiffre';

  @override
  String get validationPasswordMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get validationDisplayName => 'Entre 1 et 60 caractères';

  @override
  String get validationUsername =>
      '3 à 30 caractères : lettres minuscules, chiffres ou _';

  @override
  String get validationClubName => 'Entre 3 et 80 caractères';

  @override
  String get validationCity => 'Entre 2 et 80 caractères';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get profileMissingTitle => 'Profil introuvable';

  @override
  String get profileMissingBody =>
      'Votre profil n\'a pas pu être chargé. Réessayez dans un instant.';

  @override
  String get clubsOfflineBody =>
      'Les clubs nécessitent une connexion au serveur Rider Group.';

  @override
  String get clubsTabMine => 'Mes clubs';

  @override
  String get clubsTabDiscover => 'Découvrir';

  @override
  String get clubsMineEmptyTitle => 'Vous n\'avez rejoint aucun club';

  @override
  String get clubsMineEmptyBody =>
      'Découvrez les clubs de votre ville ou créez le vôtre.';

  @override
  String get clubsSearchHint => 'Rechercher un club ou une ville';

  @override
  String get clubsDiscoverEmptyTitle => 'Aucun club trouvé';

  @override
  String get clubsDiscoverEmptyBody =>
      'Essayez un autre nom ou une autre ville, ou créez le premier club.';

  @override
  String get clubCreate => 'Créer un club';

  @override
  String get clubEdit => 'Modifier le club';

  @override
  String get clubEditNotAllowed =>
      'Seuls le propriétaire et les administrateurs peuvent modifier ce club.';

  @override
  String get clubDelete => 'Supprimer le club';

  @override
  String clubDeleteConfirm(String name) {
    return 'Supprimer définitivement « $name » ? Les membres, demandes et invitations seront supprimés.';
  }

  @override
  String get clubNotFoundBody =>
      'Ce club n\'existe pas ou n\'est pas accessible.';

  @override
  String get clubFieldName => 'Nom du club';

  @override
  String get clubFieldDescription => 'Description';

  @override
  String get clubFieldRules => 'Règlement';

  @override
  String get clubSectionAccess => 'Visibilité et adhésion';

  @override
  String get clubSettingsOwnerOnly =>
      'Seul le propriétaire peut modifier ces réglages.';

  @override
  String get clubVisibilityPublic => 'Public';

  @override
  String get clubVisibilityPrivate => 'Privé';

  @override
  String get clubVisibilityPublicHelp =>
      'Le club et sa liste de membres sont visibles par tous les motards connectés.';

  @override
  String get clubVisibilityPrivateHelp =>
      'La liste des membres est réservée aux membres. Vous choisissez si le club apparaît dans la recherche.';

  @override
  String get clubFieldListed => 'Apparaître dans la recherche';

  @override
  String get clubFieldListedHelp =>
      'Si désactivé, seuls les membres et les personnes invitées voient le club.';

  @override
  String get clubFieldJoinPolicy => 'Conditions d\'adhésion';

  @override
  String get clubJoinOpen => 'Adhésion libre';

  @override
  String get clubJoinApproval => 'Sur approbation';

  @override
  String get clubJoinInviteOnly => 'Sur invitation uniquement';

  @override
  String get clubRoleOwner => 'Propriétaire';

  @override
  String get clubRoleAdmin => 'Administrateur';

  @override
  String get clubRoleModerator => 'Modérateur';

  @override
  String get clubRoleMember => 'Membre';

  @override
  String get clubVerified => 'Vérifié';

  @override
  String get clubMembersTitle => 'Membres';

  @override
  String get clubMembersPrivate =>
      'La liste des membres est réservée aux membres du club.';

  @override
  String get clubMembersEmpty => 'Aucun membre à afficher.';

  @override
  String get clubJoin => 'Rejoindre le club';

  @override
  String get clubJoined => 'Bienvenue dans le club !';

  @override
  String get clubRequestJoin => 'Demander à rejoindre';

  @override
  String get clubRequestMessage => 'Message (facultatif)';

  @override
  String get clubRequestSend => 'Envoyer';

  @override
  String get clubRequestSent => 'Demande envoyée';

  @override
  String get clubRequestPending =>
      'Votre demande d\'adhésion est en attente de validation.';

  @override
  String get clubRequestCancel => 'Annuler ma demande';

  @override
  String get clubInviteOnlyNotice =>
      'Ce club accepte uniquement les membres invités.';

  @override
  String get clubLeave => 'Quitter le club';

  @override
  String clubLeaveConfirm(String name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get clubAdminTitle => 'Administration du club';

  @override
  String get clubInvite => 'Inviter un motard';

  @override
  String get clubInviteSend => 'Inviter';

  @override
  String clubInviteSent(String name) {
    return 'Invitation envoyée à $name';
  }

  @override
  String get clubRequestsNone => 'Aucune demande d\'adhésion en attente.';

  @override
  String clubInvitationTitle(String club) {
    return 'Invitation à rejoindre « $club »';
  }

  @override
  String clubInvitationFrom(String name) {
    return 'De la part de $name';
  }

  @override
  String clubSetRole(String role) {
    return 'Nommer $role';
  }

  @override
  String get clubRemoveMember => 'Retirer du club';

  @override
  String clubRemoveConfirm(String name) {
    return 'Retirer $name du club ?';
  }

  @override
  String get clubTransferOwnership => 'Transférer la propriété';

  @override
  String clubTransferConfirm(String name) {
    return 'Faire de $name le propriétaire du club ? Vous deviendrez administrateur.';
  }

  @override
  String get clubVerificationRequest => 'Demander le badge Vérifié';

  @override
  String get clubVerificationMessage =>
      'Présentez votre club (ancienneté, références…)';

  @override
  String get clubVerificationSent => 'Demande de vérification envoyée';

  @override
  String get clubVerificationPending =>
      'Demande de vérification en cours d\'examen par l\'équipe Rider Group.';

  @override
  String get clubVerificationRejected =>
      'La précédente demande de vérification a été refusée.';

  @override
  String get clubVerificationHelp =>
      'Le badge est facultatif et accordé après examen par l\'équipe Rider Group. Il ne donne accès à aucune donnée privée.';

  @override
  String get errorNetwork =>
      'Connexion impossible. Vérifiez votre accès Internet et réessayez.';

  @override
  String get errorBackendUnavailable =>
      'Le serveur n\'est pas configuré sur cette version de l\'application.';

  @override
  String get errorNotAuthenticated =>
      'Votre session a expiré. Reconnectez-vous.';

  @override
  String get errorNotAllowed => 'Action non autorisée';

  @override
  String get errorInvalidInput => 'Données invalides';

  @override
  String get errorAlreadyExists => 'Cette valeur est déjà utilisée.';

  @override
  String get errorInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get errorEmailNotConfirmed =>
      'Confirmez votre adresse e-mail avant de vous connecter.';

  @override
  String get errorUserAlreadyExists =>
      'Un compte existe déjà avec cette adresse e-mail.';

  @override
  String get errorWeakPassword => 'Mot de passe trop faible.';

  @override
  String get errorRateLimited => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get errorClubNotFound => 'Club introuvable';

  @override
  String get errorClubNameTaken => 'Ce nom de club est déjà pris.';

  @override
  String get errorClubSuspended => 'Ce club est suspendu.';

  @override
  String get errorAlreadyMember => 'Vous êtes déjà membre de ce club.';

  @override
  String get errorNotMember => 'Cette personne n\'est pas membre du club.';

  @override
  String get errorInvitationRequired =>
      'Ce club n\'accepte que les membres invités.';

  @override
  String get errorRequestNotFound => 'Cette demande n\'existe plus.';

  @override
  String get errorInvitationNotFound => 'Cette invitation n\'est plus valide.';

  @override
  String get errorOwnerCannotLeave =>
      'Le propriétaire doit transférer la propriété avant de quitter le club.';

  @override
  String get errorUseTransferOwnership => 'Utilisez le transfert de propriété.';

  @override
  String get errorUserNotFound => 'Aucun motard trouvé avec ce pseudonyme.';

  @override
  String get errorAlreadyVerified => 'Ce club est déjà vérifié.';

  @override
  String get errorVerificationPending =>
      'Une demande de vérification est déjà en cours.';

  @override
  String get errorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String clubMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: 'Aucun membre',
    );
    return '$_temp0';
  }

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get signInForgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordSubtitle =>
      'Indiquez votre adresse e-mail : vous recevrez un lien pour choisir un nouveau mot de passe.';

  @override
  String get forgotPasswordAction => 'Envoyer le lien';

  @override
  String get forgotPasswordSent =>
      'Si un compte correspond à cette adresse, un e-mail vient d\'être envoyé. Ouvrez le lien depuis ce téléphone.';

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSubtitle =>
      'Choisissez un mot de passe que vous n\'utilisez nulle part ailleurs.';

  @override
  String get fieldNewPassword => 'Nouveau mot de passe';

  @override
  String get newPasswordSaved => 'Mot de passe mis à jour.';

  @override
  String get profileHidden => 'Profil masqué';

  @override
  String get profilePhotoChange => 'Changer la photo';

  @override
  String get profilePhotoRemove => 'Retirer la photo';

  @override
  String get profileAccountSection => 'Compte';

  @override
  String get profileChangePassword => 'Changer de mot de passe';

  @override
  String get privacyTitle => 'Confidentialité';

  @override
  String get privacyDiscoverable => 'Profil visible par tous les motards';

  @override
  String get privacyDiscoverableHelp =>
      'Si désactivé, seuls les membres de vos clubs voient votre profil, et personne ne peut vous trouver par pseudonyme.';

  @override
  String get privacyInvitations => 'Accepter les invitations de clubs';

  @override
  String get privacyInvitationsHelp =>
      'Si désactivé, aucun club ne peut vous inviter. Vous pouvez toujours demander à rejoindre un club.';

  @override
  String get privacyEmailNotice =>
      'Votre adresse e-mail n\'est jamais visible par les autres utilisateurs.';

  @override
  String get deleteAccountTitle => 'Supprimer mon compte';

  @override
  String get deleteAccountIntro =>
      'La suppression de votre compte est définitive.';

  @override
  String get deleteAccountConsequences =>
      'Votre profil, votre photo, vos adhésions, vos participations, vos demandes et vos invitations seront supprimés. Les balades terminées que vous avez organisées restent dans l\'historique des participants, sans votre nom. Cette action est irréversible.';

  @override
  String deleteAccountSoloClubs(String clubs) {
    return 'Ces clubs, dont vous êtes le seul membre, seront supprimés : $clubs';
  }

  @override
  String get deleteAccountBlockedTitle => 'Transférez d\'abord vos clubs';

  @override
  String deleteAccountBlockedBody(String clubs) {
    return 'Vous êtes propriétaire de clubs qui comptent d\'autres membres : $clubs. Transférez-en la propriété depuis la fiche du club avant de supprimer votre compte.';
  }

  @override
  String deleteAccountTypeToConfirm(String word) {
    return 'Tapez $word pour confirmer';
  }

  @override
  String get deleteAccountAction => 'Supprimer définitivement';

  @override
  String get deleteAccountDone => 'Votre compte a été supprimé.';

  @override
  String get clubImagesTitle => 'Logo et couverture';

  @override
  String get clubLogo => 'Logo';

  @override
  String get clubCover => 'Image de couverture';

  @override
  String get clubImageNone => 'Aucune image';

  @override
  String get clubImageSet => 'Image enregistrée';

  @override
  String get clubImageChange => 'Choisir';

  @override
  String get errorInvitationsDisabled =>
      'Ce motard n\'accepte pas les invitations de clubs.';

  @override
  String get errorOwnsClubsWithMembers =>
      'Transférez d\'abord la propriété de vos clubs qui comptent d\'autres membres.';

  @override
  String get errorSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'ancien.';

  @override
  String get errorUnsupportedImage =>
      'Format d\'image non pris en charge (JPEG, PNG ou WebP).';

  @override
  String get errorImageTooLarge => 'Image trop volumineuse.';

  @override
  String get bikeAny => 'Toutes motos';

  @override
  String get bikeScooter => 'Scooter';

  @override
  String get bikeRoadster => 'Roadster';

  @override
  String get bikeSport => 'Sportive';

  @override
  String get bikeTrail => 'Trail';

  @override
  String get bikeEnduro => 'Enduro / tout-terrain';

  @override
  String get bikeCustom => 'Custom';

  @override
  String get bikeTouring => 'Routière';

  @override
  String get bikeQuad => 'Quad';

  @override
  String get clubRidesTitle => 'Balades du club';

  @override
  String get clubRidesEmpty => 'Aucune balade du club à venir.';

  @override
  String get clubOrganizeRide => 'Organiser une balade du club';

  @override
  String get errorRideNotFound => 'Balade introuvable';

  @override
  String get errorRideNotEditable => 'Cette balade ne peut plus être modifiée.';

  @override
  String get errorRideNotJoinable =>
      'Les inscriptions à cette balade sont fermées.';

  @override
  String get errorRideFull => 'Cette balade est complète.';

  @override
  String get errorInvalidTransition =>
      'Ce changement de statut n\'est pas possible.';

  @override
  String get errorAlreadyParticipant => 'Vous participez déjà à cette balade.';

  @override
  String get errorNotParticipant =>
      'Cette personne ne participe pas à la balade.';

  @override
  String get errorRemovedFromRide =>
      'Vous avez été retiré de cette balade par l\'organisateur.';

  @override
  String get errorOrganizerCannotLeave =>
      'L\'organisateur ne peut pas quitter sa balade : annulez-la si nécessaire.';

  @override
  String get errorClubMembersOnly => 'Balade réservée aux membres du club.';

  @override
  String get errorStartInPast => 'La date de départ doit être dans le futur.';

  @override
  String get errorCapacityBelowParticipants =>
      'Le nombre maximal ne peut pas être inférieur au nombre de participants inscrits.';

  @override
  String get privacyRideInvitations => 'Accepter les invitations aux balades';

  @override
  String get privacyRideInvitationsHelp =>
      'Si désactivé, aucun organisateur ne peut vous inviter à une balade.';

  @override
  String get ridesOfflineBody =>
      'Les balades nécessitent une connexion au serveur Rider Group.';

  @override
  String get ridesTabUpcoming => 'À venir';

  @override
  String get ridesTabMine => 'Mes balades';

  @override
  String get ridesSearchHint => 'Rechercher : titre, ville, lieu';

  @override
  String get ridesUpcomingEmptyTitle => 'Aucune balade à venir';

  @override
  String get ridesUpcomingEmptyBody =>
      'Organisez la première balade de votre ville !';

  @override
  String get ridesMineEmptyTitle => 'Aucune balade pour vous';

  @override
  String get ridesMineEmptyBody =>
      'Rejoignez une balade ou organisez la vôtre.';

  @override
  String get ridesSectionUpcoming => 'À venir et en cours';

  @override
  String get ridesSectionDrafts => 'Brouillons';

  @override
  String get ridesSectionPast => 'Terminées ou annulées';

  @override
  String get rideCreate => 'Organiser une balade';

  @override
  String get rideEdit => 'Modifier la balade';

  @override
  String get rideEditNotAllowed =>
      'Seul l\'organisateur (ou un administrateur du club) peut modifier cette balade avant son départ.';

  @override
  String get rideNotFoundBody =>
      'Cette balade n\'existe pas ou ne vous est pas accessible.';

  @override
  String get rideDeleteDraft => 'Supprimer le brouillon';

  @override
  String get rideDeleteDraftConfirm =>
      'Supprimer définitivement ce brouillon ?';

  @override
  String get rideFieldTitle => 'Titre de la balade';

  @override
  String get rideSectionWhen => 'Date et heure';

  @override
  String get rideFieldTimezone => 'Fuseau horaire';

  @override
  String get timezoneKinshasa => 'Heure de Kinshasa (UTC+1)';

  @override
  String get timezoneLubumbashi => 'Heure de Lubumbashi (UTC+2)';

  @override
  String get rideSectionWhere => 'Itinéraire';

  @override
  String get rideFieldStart => 'Point de départ';

  @override
  String get rideFieldDestination => 'Destination';

  @override
  String get rideFieldItinerary => 'Étapes et pauses';

  @override
  String get rideFieldItineraryHelp =>
      'Ex. : départ 8 h, pause carburant à Maluku, déjeuner à Kinkole.';

  @override
  String get rideSectionRiders => 'Participants';

  @override
  String get rideFieldDifficulty => 'Niveau de difficulté';

  @override
  String get rideDifficultyEasy => 'Facile';

  @override
  String get rideDifficultyModerate => 'Intermédiaire';

  @override
  String get rideDifficultyHard => 'Difficile';

  @override
  String get rideDifficultyExpert => 'Expert';

  @override
  String get rideFieldBikeTypes => 'Motos recommandées';

  @override
  String get rideFieldMaxParticipants => 'Nombre maximal de participants';

  @override
  String get rideFieldMaxParticipantsHelp =>
      'Facultatif, organisateur compris (2 à 500).';

  @override
  String get rideFieldConditions => 'Conditions de participation';

  @override
  String get rideFieldConditionsHelp =>
      'Ex. : casque et gants obligatoires, permis valide, réservoir plein au départ.';

  @override
  String get rideFieldOrganizedBy => 'Organisée par';

  @override
  String get rideOrganizedByMe => 'Moi (balade personnelle)';

  @override
  String get rideFieldOpenToNonMembers => 'Ouverte aux motards hors du club';

  @override
  String get rideFieldOpenToNonMembersHelp =>
      'Si désactivé, seuls les membres du club voient la balade et peuvent la rejoindre.';

  @override
  String get rideFieldJoinPolicy => 'Mode d\'adhésion';

  @override
  String get rideJoinOpen => 'Participation libre';

  @override
  String get rideJoinApproval => 'Sur approbation de l\'organisateur';

  @override
  String get rideJoinInviteOnly => 'Sur invitation uniquement';

  @override
  String get rideSaveDraft => 'Enregistrer en brouillon';

  @override
  String get rideVisibilityPublic => 'Publique';

  @override
  String get rideVisibilityPrivate => 'Privée';

  @override
  String get rideVisibilityClub => 'Balade de club';

  @override
  String get rideOpenToAll => 'ouverte à tous';

  @override
  String get rideStatusDraft => 'Brouillon';

  @override
  String get rideStatusPublished => 'Inscriptions ouvertes';

  @override
  String get rideStatusLocked => 'Verrouillée';

  @override
  String get rideStatusInProgress => 'En cours';

  @override
  String get rideStatusFinished => 'Terminée';

  @override
  String get rideStatusCancelled => 'Annulée';

  @override
  String get rideJoinsClosed => 'inscriptions fermées';

  @override
  String get rideActionPublish => 'Publier';

  @override
  String get rideActionLock => 'Verrouiller';

  @override
  String get rideActionUnlock => 'Déverrouiller';

  @override
  String get rideActionStart => 'Démarrer';

  @override
  String get rideActionFinish => 'Terminer';

  @override
  String get rideActionCancel => 'Annuler la balade';

  @override
  String get rideCancelReason => 'Motif (facultatif, visible des participants)';

  @override
  String get rideCancelledNoReason => 'Aucun motif indiqué.';

  @override
  String get rideStartConfirm =>
      'Démarrer la balade maintenant ? Les participants verront qu\'elle est en cours.';

  @override
  String get rideFinishConfirm =>
      'Marquer la balade comme terminée ? Cette action est définitive.';

  @override
  String rideClubLabel(String club) {
    return 'Club : $club';
  }

  @override
  String rideOrganizerLabel(String name) {
    return 'Organisateur : $name';
  }

  @override
  String get rideOrganizerRole => 'Organisateur';

  @override
  String rideParticipantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
    );
    return '$_temp0';
  }

  @override
  String rideParticipantCapacity(int count, int max) {
    return '$count / $max participants';
  }

  @override
  String get rideDraftNotice =>
      'Brouillon : visible uniquement par vous. Publiez-le pour ouvrir les inscriptions.';

  @override
  String get rideYouOrganize => 'Vous organisez cette balade.';

  @override
  String get rideYouParticipate => 'Vous participez à cette balade.';

  @override
  String get rideRemovedNotice =>
      'L\'organisateur vous a retiré de cette balade.';

  @override
  String get rideRequestPending =>
      'Votre demande de participation attend la décision de l\'organisateur.';

  @override
  String get rideRequestPendingShort => 'Demande envoyée';

  @override
  String get rideJoinsClosedNotice =>
      'Les inscriptions sont fermées (balade verrouillée par l\'organisateur).';

  @override
  String get rideJoin => 'Participer';

  @override
  String get rideJoined => 'Vous participez à la balade !';

  @override
  String get rideRequestJoin => 'Demander à participer';

  @override
  String get rideInviteOnlyNotice =>
      'Cette balade accepte uniquement les motards invités par l\'organisateur.';

  @override
  String get rideLeave => 'Quitter la balade';

  @override
  String rideLeaveConfirm(String title) {
    return 'Ne plus participer à « $title » ?';
  }

  @override
  String get rideManageTitle => 'Gestion de la balade';

  @override
  String get rideNoMoreActions =>
      'La balade est close : plus aucune action n\'est possible.';

  @override
  String get rideLockedHelp =>
      'Verrouillée : aucune nouvelle inscription (y compris par invitation ou approbation). Les participants inscrits restent.';

  @override
  String get rideInvite => 'Inviter un motard';

  @override
  String get rideRequestsTitle => 'Demandes de participation';

  @override
  String get rideParticipantsTitle => 'Participants';

  @override
  String get rideParticipantsHidden =>
      'La liste des participants est réservée aux participants de cette balade.';

  @override
  String get rideRemoveParticipant => 'Retirer de la balade';

  @override
  String rideRemoveConfirm(String name) {
    return 'Retirer $name de la balade ? Cette personne ne pourra pas revenir d\'elle-même.';
  }

  @override
  String rideInvitationTitle(String title) {
    return 'Invitation à la balade « $title »';
  }

  @override
  String get validationRideTitle => 'Entre 3 et 100 caractères';

  @override
  String get validationRidePlace => 'Entre 2 et 120 caractères';

  @override
  String get validationMaxParticipants => 'Entre 2 et 500, ou laisser vide';

  @override
  String get validationBikeTypes => 'Choisissez au moins un type de moto.';

  @override
  String get rideOrganizerDeleted => 'compte supprimé';

  @override
  String get errorOrganizesActiveRides =>
      'Annulez d\'abord les balades que vous organisez et qui comptent d\'autres inscrits.';

  @override
  String get deleteAccountBlockedRidesTitle =>
      'Annulez d\'abord vos balades actives';

  @override
  String deleteAccountBlockedRidesBody(String rides) {
    return 'Vous organisez des balades qui comptent d\'autres inscrits : $rides. Annulez-les depuis leur fiche avant de supprimer votre compte.';
  }

  @override
  String get errorSignupDisabled =>
      'Les inscriptions par e-mail sont désactivées sur le serveur. Contactez l\'administrateur de Rider Group.';

  @override
  String get convoyTitle => 'Mode Convoi';

  @override
  String get convoyOpen => 'Ouvrir le mode Convoi';

  @override
  String get convoySafety =>
      'Ne manipulez pas le téléphone en roulant : arrêtez-vous en lieu sûr.';

  @override
  String get convoyStartSharing => 'Partager ma position';

  @override
  String get convoyStopSharing => 'Arrêter le partage';

  @override
  String get convoySharingOff => 'Votre position n\'est pas partagée.';

  @override
  String get convoySharingStarting => 'Activation du partage…';

  @override
  String get convoyWaitingFix => 'Partage actif — recherche du signal GPS…';

  @override
  String convoyLastSent(String time) {
    return 'Partage actif — dernière position envoyée à $time. Il s\'arrête si vous quittez cet écran.';
  }

  @override
  String get convoyNotSent =>
      'Position NON transmise (réseau ?). Nouvel essai automatique.';

  @override
  String get convoyLocationOff =>
      'La localisation du téléphone est désactivée. Activez-la dans les réglages.';

  @override
  String get convoyLocationDenied =>
      'Rider Group n\'a pas l\'autorisation d\'utiliser votre position.';

  @override
  String get convoyLocationDeniedForever =>
      'Autorisation refusée définitivement : modifiez-la dans les réglages du téléphone.';

  @override
  String get convoyNotRunningTitle => 'La balade n\'est pas en cours';

  @override
  String get convoyNotRunningBody =>
      'Le mode Convoi est disponible uniquement pendant la balade.';

  @override
  String get convoyParticipantsOnly =>
      'Le mode Convoi est réservé aux participants confirmés.';

  @override
  String get convoyYou => 'Vous';

  @override
  String get convoyRoleLeader => 'chef de convoi';

  @override
  String get convoyRoleSweeper => 'serre-file';

  @override
  String get convoyNotSharing => 'Ne partage pas sa position';

  @override
  String get convoyLive => 'Position à jour';

  @override
  String get convoyAging => 'Position de plus d\'une minute';

  @override
  String convoyStale(int minutes) {
    return 'Position ancienne ($minutes min) : réseau absent ou arrêt — à vérifier';
  }

  @override
  String convoySeparated(String km) {
    return 'À $km km du chef de convoi — peut-être séparé';
  }

  @override
  String get convoyAssignRole => 'Rôle de convoi';

  @override
  String get convoyMakeLeader => 'Nommer chef de convoi';

  @override
  String get convoyMakeSweeper => 'Nommer serre-file';

  @override
  String get convoyClearRole => 'Retirer le rôle de convoi';

  @override
  String get errorRideNotInProgress =>
      'La balade n\'est pas en cours : le partage de position est arrêté.';

  @override
  String get errorSharingDisabled => 'Le partage de position est désactivé.';

  @override
  String get errorAlertClosed => 'Cette alerte est déjà close.';

  @override
  String get errorOwnAlert =>
      'Vous ne pouvez pas accuser réception de votre propre alerte.';

  @override
  String get sosTitle => 'SOS et assistance';

  @override
  String get sosOpen => 'SOS';

  @override
  String get sosDisclaimer =>
      'Rider Group prévient les participants de la balade. Ce n\'est pas un service de secours : en cas de danger, appelez les secours.';

  @override
  String sosCall(String number) {
    return 'Appeler le $number';
  }

  @override
  String sosCallFailed(String number) {
    return 'Impossible d\'ouvrir le téléphone. Composez le $number vous-même.';
  }

  @override
  String get sosChooseKind => 'Que se passe-t-il ?';

  @override
  String get sosKindBreakdown => 'Panne';

  @override
  String get sosKindAccident => 'Accident';

  @override
  String get sosKindAssistance => 'Besoin d\'aide';

  @override
  String get sosKindDelay => 'Je suis en retard';

  @override
  String sosConfirmTitle(String kind) {
    return 'Envoyer l\'alerte « $kind » ?';
  }

  @override
  String get sosConfirmBody =>
      'Les participants de la balade recevront votre alerte et votre dernière position connue.';

  @override
  String get sosConfirmSend => 'Envoyer l\'alerte';

  @override
  String get sosSending =>
      'Envoi en cours… L\'alerte n\'est PAS encore transmise.';

  @override
  String get sosFailedTitle => 'ALERTE NON TRANSMISE';

  @override
  String get sosFailedBody =>
      'Personne n\'a été prévenu. Réessayez ou appelez directement.';

  @override
  String get sosRetry => 'Réessayer l\'envoi';

  @override
  String get sosAbandon => 'Abandonner';

  @override
  String sosSentTitle(String time) {
    return 'Alerte transmise à $time';
  }

  @override
  String get sosNoAckYet => 'Pas encore d\'accusé de réception.';

  @override
  String sosAckedBy(String names) {
    return 'Vu par : $names';
  }

  @override
  String get sosPositionDevice => 'Position GPS envoyée';

  @override
  String get sosPositionConvoy => 'Dernière position du mode Convoi envoyée';

  @override
  String get sosPositionNone => 'Aucune position disponible';

  @override
  String get sosCancelMine => 'Annuler (fausse alerte)';

  @override
  String get sosResolveMine => 'Problème résolu';

  @override
  String get sosIncomingTitle => 'Alertes en cours';

  @override
  String sosIncomingFrom(String kind, String name) {
    return '$kind — $name';
  }

  @override
  String sosSince(String time) {
    return 'Depuis $time';
  }

  @override
  String get sosAck => 'J\'ai vu, je m\'en occupe';

  @override
  String get sosAcked => 'Vous avez accusé réception';

  @override
  String get sosOpenMap => 'Voir sur la carte';

  @override
  String get sosResolveByManager => 'Marquer comme résolue';

  @override
  String get sosClosedResolved => 'Alerte résolue';

  @override
  String get sosClosedCancelled => 'Alerte annulée';

  @override
  String get sosParticipantsOnly =>
      'Le SOS est réservé aux participants de la balade en cours.';

  @override
  String get sosNotRunningBody =>
      'Le SOS est disponible pendant une balade en cours. En dehors, appelez directement les secours.';

  @override
  String sosBanner(String kind) {
    return 'SOS : $kind dans votre balade';
  }

  @override
  String sosBannerMore(int count) {
    return '+$count autre(s)';
  }

  @override
  String get sosBannerView => 'Voir';

  @override
  String get sosBannerDismiss => 'Masquer';

  @override
  String get settingsSafety => 'Sécurité';

  @override
  String get settingsEmergencyNumber => 'Numéro d\'appel d\'urgence';

  @override
  String get settingsEmergencyNumberHint =>
      'Proposé sur l\'écran SOS. Sa disponibilité dépend du pays et de l\'opérateur.';

  @override
  String get settingsEmergencyNumberInvalid =>
      'Numéro invalide (chiffres uniquement, + autorisé au début).';
}
