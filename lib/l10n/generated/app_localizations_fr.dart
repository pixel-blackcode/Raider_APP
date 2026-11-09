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
}
