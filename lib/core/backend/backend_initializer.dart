import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'backend_status.dart';
import 'secure_session_storage.dart';

/// Signature de la fonction d'initialisation (injectable pour les tests).
typedef SupabaseInitializer = Future<void> Function({
  required String url,
  required String key,
});

Future<void> _defaultSupabaseInitializer({
  required String url,
  required String key,
}) async {
  const storage = FlutterSecureStorage();
  await Supabase.initialize(
    url: url,
    publishableKey: key,
    authOptions: const FlutterAuthClientOptions(
      // PKCE : les liens reçus par e-mail ne fonctionnent que sur l'appareil
      // qui a fait la demande.
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureSessionStorage(storage),
      pkceAsyncStorage: SecurePkceStorage(storage),
      // Les liens profonds (confirmation d'e-mail, réinitialisation du mot
      // de passe) sont échangés contre une session par supabase_flutter.
      detectSessionInUri: true,
    ),
  );
}

/// Initialise le client Supabase si et seulement si la configuration est
/// complète et valide. Ne lève jamais d'exception : le résultat est décrit
/// par un [BackendStatus].
Future<BackendStatus> initializeBackend(
  AppConfig config, {
  SupabaseInitializer initializer = _defaultSupabaseInitializer,
}) async {
  final issues = config.issues;
  if (issues.isNotEmpty) {
    debugPrint('[Backend] Supabase non configuré : $issues');
    return BackendNotConfigured(issues);
  }

  try {
    await initializer(
      url: config.supabaseUrl,
      key: config.supabasePublishableKey,
    );
    return BackendReady(config.environment);
  } catch (error) {
    debugPrint('[Backend] Échec d\'initialisation Supabase : $error');
    return BackendFailed(error);
  }
}
