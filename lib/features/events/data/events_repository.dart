import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/moto_event.dart';

/// Événements moto. Le serveur vérifie tout (club vérifié, responsables).
abstract interface class EventsRepository {
  Future<List<MotoEvent>> upcoming({String? clubId});

  Future<MotoEvent?> event(String id);

  Future<String> create(String clubId, String clientRef, EventDraft draft);

  Future<void> update(String id, EventDraft draft);

  /// Enregistre (ou retire avec null) la couverture ; retourne l'ancienne.
  Future<String?> setCover(String id, String? path);

  Future<void> cancel(String id);

  Future<void> inviteCoOrganizer(String eventId, String clubId);

  Future<void> respondCoOrganizer(String invitationId, {required bool accept});

  Future<void> removeCoOrganizer(String eventId, String clubId);

  Future<void> setGoing(String eventId, {required bool going});
}

class SupabaseEventsRepository implements EventsRepository {
  SupabaseEventsRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<List<MotoEvent>> _list(Map<String, dynamic> params) async {
    final data = await _client.rpc<Object?>('list_events', params: params);
    return [
      for (final r in (data as List?) ?? const [])
        MotoEvent.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<MotoEvent>> upcoming({String? clubId}) =>
      _guard(() => _list({'p_club_id': clubId}));

  @override
  Future<MotoEvent?> event(String id) => _guard(() async {
    final rows = await _list({'p_event_id': id});
    return rows.isEmpty ? null : rows.first;
  });

  @override
  Future<String> create(String clubId, String clientRef, EventDraft draft) =>
      _guard(
        () async => (await _client.rpc<String>(
          'create_event',
          params: {
            'p_club_id': clubId,
            'p_client_ref': clientRef,
            ...draft.toParams(),
          },
        )),
      );

  @override
  Future<void> update(String id, EventDraft draft) => _guard(
    () => _client.rpc<void>(
      'update_event',
      params: {'p_event_id': id, ...draft.toParams()},
    ),
  );

  @override
  Future<String?> setCover(String id, String? path) => _guard(
    () => _client.rpc<String?>(
      'set_event_cover',
      params: {'p_event_id': id, 'p_path': path},
    ),
  );

  @override
  Future<void> cancel(String id) => _guard(
    () => _client.rpc<void>('cancel_event', params: {'p_event_id': id}),
  );

  @override
  Future<void> inviteCoOrganizer(String eventId, String clubId) => _guard(
    () => _client.rpc<Object?>(
      'invite_event_coorganizer',
      params: {'p_event_id': eventId, 'p_club_id': clubId},
    ),
  );

  @override
  Future<void> respondCoOrganizer(
    String invitationId, {
    required bool accept,
  }) => _guard(
    () => _client.rpc<void>(
      'respond_event_coorganizer',
      params: {'p_invitation_id': invitationId, 'p_accept': accept},
    ),
  );

  @override
  Future<void> removeCoOrganizer(String eventId, String clubId) => _guard(
    () => _client.rpc<void>(
      'remove_event_coorganizer',
      params: {'p_event_id': eventId, 'p_club_id': clubId},
    ),
  );

  @override
  Future<void> setGoing(String eventId, {required bool going}) => _guard(
    () => _client.rpc<void>(
      'set_event_attendance',
      params: {'p_event_id': eventId, 'p_going': going},
    ),
  );
}

final eventsRepositoryProvider = Provider<EventsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseEventsRepository(client);
});

/// Événements à venir (tous, ou ceux d'un club / regroupement).
final upcomingEventsProvider = FutureProvider.autoDispose
    .family<List<MotoEvent>, String?>((ref, clubId) async {
      final repo = ref.watch(eventsRepositoryProvider);
      if (repo == null) return const [];
      return repo.upcoming(clubId: clubId);
    });

final eventDetailProvider = FutureProvider.autoDispose
    .family<MotoEvent?, String>((ref, id) async {
      final repo = ref.watch(eventsRepositoryProvider);
      if (repo == null) return null;
      return repo.event(id);
    });

extension RefreshEvents on WidgetRef {
  void refreshEvents([String? id]) {
    invalidate(upcomingEventsProvider);
    if (id != null) invalidate(eventDetailProvider(id));
  }
}
