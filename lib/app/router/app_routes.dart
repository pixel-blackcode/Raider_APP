/// Chemins de navigation centralisés.
abstract final class AppRoutes {
  // Onglets principaux (barre de navigation).
  static const home = '/accueil';
  static const rides = '/balades';
  static const clubs = '/clubs';
  static const messages = '/messages';
  static const profile = '/profil';

  // Écrans plein écran, au-dessus de la barre de navigation.
  static const solo = '/solo';
  static const soloContacts = '/solo/proches';
  static String soloWatch(String id) => '/solo/suivi/$id';
  static const garage = '/garage';
  static const garageReminders = '/garage/rappels';
  static const newMotorcycle = '/garage/nouvelle';
  static String motorcycle(String id) => '/garage/moto/$id';
  static String editMotorcycle(String id) => '/garage/moto/$id/modifier';
  static String addMaintenance(String id) => '/garage/moto/$id/entretien';
  static const marketplace = '/marketplace';
  static const newListing = '/marketplace/vendre';
  static String listing(String id) => '/marketplace/annonces/$id';
  static String editListing(String id) => '/marketplace/annonces/$id/modifier';
  static const settings = '/parametres';
  static const notifications = '/notifications';
  static const editProfile = '/profil/modifier';
  static const privacySettings = '/profil/confidentialite';
  static const deleteAccount = '/profil/supprimer-mon-compte';
  static const newPassword = '/mot-de-passe/nouveau';
  static const authCallback = '/auth-callback';

  // Authentification.
  static const signIn = '/connexion';
  static const signUp = '/inscription';
  static const forgotPassword = '/mot-de-passe-oublie';
  static const authPages = {signIn, signUp, forgotPassword};

  // Balades.
  static String newRide({String? clubId}) => Uri(
    path: '/balades/nouvelle',
    queryParameters: clubId == null ? null : {'club': clubId},
  ).toString();
  static String ride(String id) => '/balades/$id';
  static String editRide(String id) => '/balades/$id/modifier';
  static String convoy(String id) => '/balades/$id/convoi';
  static String sos(String id) => '/balades/$id/sos';

  // Communauté.
  static String newPost({String? clubId}) => Uri(
    path: '/publier',
    queryParameters: clubId == null ? null : {'club': clubId},
  ).toString();
  static String post(String id) => '/publications/$id';
  static String rider(String id) => '/motards/$id';
  static const blockedUsers = '/profil/bloques';
  static const moderation = '/moderation';

  // Messagerie.
  static const newConversation = '/messages/nouveau';
  static String chat(String id, {String? text}) => Uri(
    path: '/messages/$id',
    queryParameters: text == null ? null : {'texte': text},
  ).toString();

  // Clubs.
  static const newClub = '/clubs/nouveau';
  static String club(String id) => '/clubs/$id';
  static String editClub(String id) => '/clubs/$id/modifier';
  static String clubVerification(String id) => '/clubs/$id/verification';
  static const verificationAdmin = '/equipe/verifications';
  static const riderVerification = '/verification-motard';
  static const riderVerificationForGroup = '/verification-motard?raison=groupe';

  // Événements moto.
  static const events = '/evenements';
  static String event(String id) => '/evenements/$id';
  static String editEvent(String id) => '/evenements/$id/modifier';
  static String newEvent(String clubId) => '/clubs/$clubId/evenement';

  static const feedback = '/parametres/signaler';

  // Boutiques.
  static const shops = '/boutiques';
  static const myShop = '/boutiques/la-mienne';
  static String shop(String id) => '/boutiques/$id';
}
