/// Messagerie (Mission 07) : conversations privées, de groupe et de balade.
library;

enum ConversationKind {
  direct,
  group,
  ride;

  static ConversationKind parse(String? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => direct);
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.kind,
    required this.title,
    this.rideId,
    this.otherUserId,
    this.otherAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.blocked = false,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) =>
      ConversationSummary(
        id: j['id'] as String,
        kind: ConversationKind.parse(j['kind'] as String?),
        title: (j['title'] as String?) ?? '',
        rideId: j['ride_id'] as String?,
        otherUserId: j['other_user_id'] as String?,
        otherAvatar: j['other_avatar'] as String?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] == null
            ? null
            : DateTime.parse(j['last_message_at'] as String).toUtc(),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
        blocked: (j['blocked'] as bool?) ?? false,
      );

  final String id;
  final ConversationKind kind;
  final String title;
  final String? rideId;
  final String? otherUserId;
  final String? otherAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Conversation privée avec un motard bloqué (dans un sens ou l'autre).
  final bool blocked;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.clientRef,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.hidden = false,
    this.deleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId: j['sender_id'] as String?,
    senderName: j['sender_name'] as String?,
    body: (j['body'] as String?) ?? '',
    clientRef: j['client_ref'] as String,
    hidden: j['moderation'] == 'hidden',
    deleted: j['deleted_at'] != null,
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
  );

  final String id;
  final String conversationId;
  final String? senderId;
  final String? senderName;
  final String body;
  final String clientRef;
  final bool hidden;
  final bool deleted;
  final DateTime createdAt;
}

/// Message que J'envoie : jamais affiché « envoyé » sans réponse du serveur.
enum OutgoingState { sending, failed, sent }

class OutgoingMessage {
  const OutgoingMessage({
    required this.clientRef,
    required this.conversationId,
    required this.body,
    required this.state,
    required this.createdAt,
    this.error,
    this.message,
  });

  final String clientRef;
  final String conversationId;
  final String body;
  final OutgoingState state;
  final DateTime createdAt;
  final Object? error;

  /// Message enregistré par le serveur (état `sent` uniquement).
  final ChatMessage? message;

  OutgoingMessage copyWith({
    OutgoingState? state,
    Object? error,
    ChatMessage? message,
  }) => OutgoingMessage(
    clientRef: clientRef,
    conversationId: conversationId,
    body: body,
    state: state ?? this.state,
    createdAt: createdAt,
    error: error,
    message: message ?? this.message,
  );
}
