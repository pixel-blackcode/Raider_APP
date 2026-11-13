import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/messaging.dart';

abstract interface class MessagingRepository {
  Future<List<ConversationSummary>> inbox();

  /// Émet à chaque nouveau message visible (temps réel) : la boîte de
  /// réception se met à jour.
  Stream<void> inboxChanges();

  Future<String> openDirect(String userId);

  Future<String> createGroup(String title, List<String> memberIds);

  Future<String> openRide(String rideId);

  /// Messages de la conversation, mis à jour en temps réel.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Envoi idempotent : renvoyer le même `clientRef` ne crée pas de doublon.
  Future<ChatMessage> send(
    String conversationId,
    String body,
    String clientRef,
  );

  Future<void> deleteMessage(String messageId);

  Future<void> markRead(String conversationId);

  /// Quitter un groupe (userId = soi) ou en retirer un membre (créateur).
  Future<void> removeMember(String conversationId, String userId);
}

class SupabaseMessagingRepository implements MessagingRepository {
  SupabaseMessagingRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  List<Map<String, dynamic>> _rows(Object? data) => [
    for (final r in (data as List?) ?? const []) r as Map<String, dynamic>,
  ];

  @override
  Future<List<ConversationSummary>> inbox() => _guard(() async {
    final data = await _client.rpc<Object?>('my_conversations');
    return _rows(data).map(ConversationSummary.fromJson).toList();
  });

  @override
  Stream<void> inboxChanges() {
    late final RealtimeChannel channel;
    // Fermé à l'annulation de l'abonnement (canal retiré).
    // ignore: close_sinks
    final controller = StreamController<void>();
    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };
    channel = _client
        .channel('inbox-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => controller.add(null),
        )
        .subscribe();
    return controller.stream;
  }

  @override
  Future<String> openDirect(String userId) => _guard(
    () => _client.rpc<String>(
      'open_direct_conversation',
      params: {'p_user_id': userId},
    ),
  );

  @override
  Future<String> createGroup(String title, List<String> memberIds) => _guard(
    () => _client.rpc<String>(
      'create_group_conversation',
      params: {'p_title': title, 'p_member_ids': memberIds},
    ),
  );

  @override
  Future<String> openRide(String rideId) => _guard(
    () => _client.rpc<String>(
      'open_ride_conversation',
      params: {'p_ride_id': rideId},
    ),
  );

  Future<List<ChatMessage>> _messages(String conversationId) =>
      _guard(() async {
        final data = await _client.rpc<Object?>(
          'conversation_messages',
          params: {'p_conversation_id': conversationId, 'p_limit': 200},
        );
        return _rows(data).map(ChatMessage.fromJson).toList();
      });

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) => _client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      // Le flux signale les changements ; les noms viennent de la fonction.
      .asyncMap((_) => _messages(conversationId));

  @override
  Future<ChatMessage> send(
    String conversationId,
    String body,
    String clientRef,
  ) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'send_message',
      params: {
        'p_conversation_id': conversationId,
        'p_body': body,
        'p_client_ref': clientRef,
      },
    );
    return ChatMessage.fromJson(row);
  });

  @override
  Future<void> deleteMessage(String messageId) => _guard(
    () => _client.rpc<void>(
      'delete_message',
      params: {'p_message_id': messageId},
    ),
  );

  @override
  Future<void> markRead(String conversationId) => _guard(
    () => _client.rpc<void>(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    ),
  );

  @override
  Future<void> removeMember(String conversationId, String userId) => _guard(
    () => _client.rpc<void>(
      'remove_conversation_member',
      params: {'p_conversation_id': conversationId, 'p_user_id': userId},
    ),
  );
}

final messagingRepositoryProvider = Provider<MessagingRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseMessagingRepository(client);
});
