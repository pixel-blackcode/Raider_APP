import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'backend_status.dart';

/// Configuration de l'application. Surchargée au démarrage (voir bootstrap).
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider doit être surchargé.'),
);

/// État du backend, déterminé une seule fois au démarrage.
final backendStatusProvider = Provider<BackendStatus>(
  (ref) =>
      throw UnimplementedError('backendStatusProvider doit être surchargé.'),
);

/// Client Supabase, disponible uniquement lorsque le backend est initialisé.
///
/// Retourne `null` si le backend n'est pas configuré : les fonctionnalités
/// en ligne doivent alors afficher un état explicite plutôt que simuler des
/// données.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final status = ref.watch(backendStatusProvider);
  return status.isReady ? Supabase.instance.client : null;
});
