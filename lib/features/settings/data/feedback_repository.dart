import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';

enum FeedbackKind { problem, suggestion }

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.kind,
    required this.message,
    required this.createdAt,
    this.userId,
    this.username = '',
    this.displayName = '',
    this.appVersion,
    this.platform,
    this.handled = false,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
    id: j['id'] as String,
    kind: j['kind'] == 'problem'
        ? FeedbackKind.problem
        : FeedbackKind.suggestion,
    message: j['message'] as String,
    userId: j['user_id'] as String?,
    username: (j['username'] as String?) ?? '',
    displayName: (j['display_name'] as String?) ?? '',
    appVersion: j['app_version'] as String?,
    platform: j['platform'] as String?,
    handled: j['handled_at'] != null,
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
  );

  final String id;
  final FeedbackKind kind;
  final String message;
  final String? userId;
  final String username;
  final String displayName;
  final String? appVersion;
  final String? platform;
  final bool handled;
  final DateTime createdAt;
}

/// Signalements et suggestions envoyés à l'équipe Rider Group (D-60).
abstract interface class FeedbackRepository {
  Future<void> send(
    FeedbackKind kind,
    String message, {
    String? appVersion,
    String? platform,
  });

  /// Équipe uniquement (refusé par le serveur sinon).
  Future<List<FeedbackItem>> queue();

  Future<void> markHandled(String id);
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> send(
    FeedbackKind kind,
    String message, {
    String? appVersion,
    String? platform,
  }) => _guard(
    () => _client.rpc<Object?>(
      'send_feedback',
      params: {
        'p_kind': kind.name,
        'p_message': message.trim(),
        'p_app_version': appVersion,
        'p_platform': platform,
      },
    ),
  );

  @override
  Future<List<FeedbackItem>> queue() => _guard(() async {
    final data = await _client.rpc<Object?>('feedback_queue');
    return [
      for (final r in (data as List?) ?? const [])
        FeedbackItem.fromJson(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> markHandled(String id) => _guard(
    () => _client.rpc<void>('mark_feedback_handled', params: {'p_id': id}),
  );
}

final feedbackRepositoryProvider = Provider<FeedbackRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseFeedbackRepository(client);
});

final feedbackQueueProvider = FutureProvider.autoDispose<List<FeedbackItem>>((
  ref,
) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  if (repo == null) return const [];
  return repo.queue();
});
