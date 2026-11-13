import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/client_ref.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/messaging.dart';
import 'messaging_repository.dart';

/// Boîte de réception, rafraîchie à chaque nouveau message (temps réel).
final inboxProvider = StreamProvider<List<ConversationSummary>>((ref) async* {
  final repo = ref.watch(messagingRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  if (repo == null || me == null) {
    yield const [];
    return;
  }
  yield await repo.inbox();
  await for (final _ in repo.inboxChanges()) {
    try {
      yield await repo.inbox();
    } catch (_) {
      // Coupure réseau : on garde la dernière liste connue.
    }
  }
});

/// Total des messages non lus (badge de l'onglet Messages).
final unreadTotalProvider = Provider<int>((ref) {
  final inbox = ref.watch(inboxProvider).value ?? const [];
  return inbox.fold(0, (sum, c) => sum + c.unreadCount);
});

final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
      final repo = ref.watch(messagingRepositoryProvider);
      if (repo == null) return Stream.value(const []);
      return repo.watchMessages(conversationId);
    });

/// Messages que J'envoie : « envoi… », « non envoyé » (renvoi possible avec
/// le même identifiant) ou « envoyé » une fois enregistré par le serveur.
class ChatOutbox extends Notifier<Map<String, OutgoingMessage>> {
  @override
  Map<String, OutgoingMessage> build() => const {};

  void _put(OutgoingMessage m) => state = {...state, m.clientRef: m};

  Future<void> send(String conversationId, String body) async {
    final m = OutgoingMessage(
      clientRef: newClientRef(),
      conversationId: conversationId,
      body: body,
      state: OutgoingState.sending,
      createdAt: DateTime.now().toUtc(),
    );
    _put(m);
    await _transmit(m);
  }

  Future<void> retry(String clientRef) async {
    final m = state[clientRef];
    if (m == null || m.state != OutgoingState.failed) return;
    _put(m.copyWith(state: OutgoingState.sending));
    await _transmit(state[clientRef]!);
  }

  void discard(String clientRef) => state = {...state}..remove(clientRef);

  Future<void> _transmit(OutgoingMessage m) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      if (repo == null) throw StateError('backend');
      final saved = await repo
          .send(m.conversationId, m.body, m.clientRef)
          .timeout(const Duration(seconds: 20));
      _put(m.copyWith(state: OutgoingState.sent, message: saved));
    } catch (error) {
      _put(m.copyWith(state: OutgoingState.failed, error: error));
    }
  }
}

final chatOutboxProvider =
    NotifierProvider<ChatOutbox, Map<String, OutgoingMessage>>(ChatOutbox.new);
