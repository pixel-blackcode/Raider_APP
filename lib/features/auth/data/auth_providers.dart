import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../domain/auth_session.dart';
import 'auth_repository.dart';

/// Dépôt d'authentification ; `null` si le backend n'est pas initialisé.
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAuthRepository(client.auth);
});

/// Session courante, observable (utilisée par le routeur via
/// [Listenable]).
final authSessionProvider = Provider<ValueListenable<AuthSession?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = ValueNotifier<AuthSession?>(repository?.currentSession);
  if (repository != null) {
    final subscription = repository.sessionChanges().listen(
      (session) => notifier.value = session,
    );
    ref.onDispose(subscription.cancel);
  }
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Identifiant de l'utilisateur connecté, mis à jour à chaque changement de
/// session.
final currentUserIdProvider = NotifierProvider<CurrentUserId, String?>(
  CurrentUserId.new,
);

class CurrentUserId extends Notifier<String?> {
  @override
  String? build() {
    final listenable = ref.watch(authSessionProvider);
    void update() => state = listenable.value?.userId;
    listenable.addListener(update);
    ref.onDispose(() => listenable.removeListener(update));
    return listenable.value?.userId;
  }
}
