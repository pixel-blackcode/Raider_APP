import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stockage chiffré de la session Supabase (Keychain iOS, Keystore Android).
///
/// Remplace le stockage par défaut de `supabase_flutter` (SharedPreferences,
/// non chiffré). Les jetons ne doivent jamais être écrits ailleurs.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const sessionKey = 'rider_group.supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: sessionKey);
}

/// Stockage chiffré du vérificateur PKCE (liens de confirmation et de
/// réinitialisation de mot de passe).
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _prefix = 'rider_group.supabase.pkce.';

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_prefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_prefix$key');
}

/// Sur iOS, le Keychain survit à la désinstallation : sans précaution, une
/// réinstallation restaurerait l'ancienne session. Au premier lancement
/// d'une installation, on efface donc les secrets éventuellement résiduels.
Future<void> clearSecretsOnFreshInstall(
  SharedPreferences preferences,
  FlutterSecureStorage storage,
) async {
  const installedKey = 'app.installed';
  if (preferences.getBool(installedKey) ?? false) return;
  await storage.deleteAll();
  await preferences.setBool(installedKey, true);
}
