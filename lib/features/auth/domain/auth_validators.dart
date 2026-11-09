/// Règles de saisie des comptes et profils.
///
/// Elles améliorent l'ergonomie ; les mêmes règles sont appliquées côté
/// serveur (Supabase Auth et contraintes SQL de `profiles`).
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[a-z0-9_]{3,30}$');

  static const minPasswordLength = 8;

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  /// Au moins 8 caractères, dont une lettre et un chiffre.
  static bool isValidPassword(String value) =>
      value.length >= minPasswordLength &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);

  /// 3 à 30 caractères : minuscules, chiffres, tiret bas.
  static bool isValidUsername(String value) => _username.hasMatch(value);

  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static bool isValidDisplayName(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= 60;
  }
}
