/// Chemins de navigation centralisés.
abstract final class AppRoutes {
  // Onglets principaux (barre de navigation).
  static const home = '/accueil';
  static const rides = '/balades';
  static const clubs = '/clubs';
  static const messages = '/messages';
  static const profile = '/profil';

  // Écrans plein écran, au-dessus de la barre de navigation.
  static const garage = '/garage';
  static const marketplace = '/marketplace';
  static const settings = '/parametres';
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

  // Clubs.
  static const newClub = '/clubs/nouveau';
  static String club(String id) => '/clubs/$id';
  static String editClub(String id) => '/clubs/$id/modifier';
}
