import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales non sensibles (thème, etc.).
///
/// Ne jamais y stocker de jetons, mots de passe ou positions GPS.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé.',
  ),
);
