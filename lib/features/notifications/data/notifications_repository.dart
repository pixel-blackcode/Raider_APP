import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> list();

  /// Émet à chaque nouvelle notification (temps réel).
  Stream<void> changes();

  /// `ids` null : tout marquer comme lu.
  Future<void> markRead([List<String>? ids]);
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> list() async {
    try {
      final data = await _client.rpc<Object?>(
        'my_notifications',
        params: {'p_limit': 100},
      );
      return [
        for (final r in (data as List?) ?? const [])
          AppNotification.fromJson(r as Map<String, dynamic>),
      ];
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Stream<void> changes() {
    late final RealtimeChannel channel;
    // Fermé à l'annulation de l'abonnement (canal retiré).
    // ignore: close_sinks
    final controller = StreamController<void>();
    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };
    channel = _client
        .channel('notifications-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => controller.add(null),
        )
        .subscribe();
    return controller.stream;
  }

  @override
  Future<void> markRead([List<String>? ids]) async {
    try {
      await _client.rpc<void>(
        'mark_notifications_read',
        params: {'p_ids': ids},
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseNotificationsRepository(client);
});

/// Notifications de la personne connectée, rafraîchies en temps réel.
final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  final repo = ref.watch(notificationsRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  if (repo == null || me == null) {
    yield const [];
    return;
  }
  yield await repo.list();
  await for (final _ in repo.changes()) {
    try {
      yield await repo.list();
    } catch (_) {
      // Coupure réseau : on garde la dernière liste connue.
    }
  }
});

final unreadNotificationsProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? const [])
      .where((n) => n.unread)
      .length,
);
