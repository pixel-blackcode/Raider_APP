import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/community.dart';

abstract interface class CommunityRepository {
  /// Fil : publications visibles, les plus récentes d'abord.
  Future<List<Post>> feed({
    String? clubId,
    String? authorId,
    DateTime? before,
    int limit = 20,
  });

  /// Une publication visible, ou null.
  Future<Post?> post(String postId);

  /// Envoi idempotent (même `clientRef` : pas de doublon).
  Future<String> createPost({
    required String clientRef,
    required String body,
    PostAudience audience = PostAudience.public,
    String? clubId,
    List<String> mediaPaths = const [],
  });

  /// Retourne les chemins des photos à effacer.
  Future<List<String>> deletePost(String postId);

  Future<List<PostComment>> comments(String postId);

  Future<void> addComment(String postId, String body, String clientRef);

  Future<void> deleteComment(String commentId);

  /// `kind` null : retire la réaction.
  Future<void> setReaction(String postId, ReactionKind? kind);

  Future<void> block(String userId);

  Future<void> unblock(String userId);

  Future<List<BlockedUser>> blockedUsers();

  Future<void> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? details,
  });

  Future<bool> amIModerator();

  Future<List<ModerationItem>> moderationQueue();

  Future<void> moderate(
    ReportTarget target,
    String targetId,
    ModerationAction action, {
    String? note,
  });
}

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client);

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
  Future<List<Post>> feed({
    String? clubId,
    String? authorId,
    DateTime? before,
    int limit = 20,
  }) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'feed_posts',
      params: {
        'p_club_id': clubId,
        'p_author_id': authorId,
        'p_before': before?.toUtc().toIso8601String(),
        'p_limit': limit,
      },
    );
    return _rows(data).map(Post.fromJson).toList();
  });

  @override
  Future<Post?> post(String postId) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'feed_posts',
      params: {'p_post_id': postId, 'p_limit': 1},
    );
    final rows = _rows(data);
    return rows.isEmpty ? null : Post.fromJson(rows.first);
  });

  @override
  Future<String> createPost({
    required String clientRef,
    required String body,
    PostAudience audience = PostAudience.public,
    String? clubId,
    List<String> mediaPaths = const [],
  }) => _guard(
    () => _client.rpc<String>(
      'create_post',
      params: {
        'p_client_ref': clientRef,
        'p_body': body,
        'p_audience': audience.dbValue,
        'p_club_id': clubId,
        'p_media_paths': mediaPaths,
      },
    ),
  );

  @override
  Future<List<String>> deletePost(String postId) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'delete_post',
      params: {'p_post_id': postId},
    );
    return [for (final p in (data as List?) ?? const []) p as String];
  });

  @override
  Future<List<PostComment>> comments(String postId) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'post_comments_list',
      params: {'p_post_id': postId},
    );
    return _rows(data).map(PostComment.fromJson).toList();
  });

  @override
  Future<void> addComment(String postId, String body, String clientRef) =>
      _guard(
        () => _client.rpc<Object?>(
          'add_comment',
          params: {
            'p_post_id': postId,
            'p_body': body,
            'p_client_ref': clientRef,
          },
        ),
      );

  @override
  Future<void> deleteComment(String commentId) => _guard(
    () => _client.rpc<void>(
      'delete_comment',
      params: {'p_comment_id': commentId},
    ),
  );

  @override
  Future<void> setReaction(String postId, ReactionKind? kind) => _guard(
    () => _client.rpc<void>(
      'set_reaction',
      params: {'p_post_id': postId, 'p_kind': kind?.dbValue},
    ),
  );

  @override
  Future<void> block(String userId) => _guard(
    () => _client.rpc<void>('block_user', params: {'p_user_id': userId}),
  );

  @override
  Future<void> unblock(String userId) => _guard(
    () => _client.rpc<void>('unblock_user', params: {'p_user_id': userId}),
  );

  @override
  Future<List<BlockedUser>> blockedUsers() => _guard(() async {
    final data = await _client.rpc<Object?>('my_blocked_users');
    return _rows(data).map(BlockedUser.fromJson).toList();
  });

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? details,
  }) => _guard(
    () => _client.rpc<void>(
      'report_content',
      params: {
        'p_target': target.name,
        'p_target_id': targetId,
        'p_reason': reason.name,
        'p_details': details,
      },
    ),
  );

  @override
  Future<bool> amIModerator() =>
      _guard(() async => (await _client.rpc<bool?>('am_i_moderator')) ?? false);

  @override
  Future<List<ModerationItem>> moderationQueue() => _guard(() async {
    final data = await _client.rpc<Object?>('moderation_queue');
    return _rows(data).map(ModerationItem.fromJson).toList();
  });

  @override
  Future<void> moderate(
    ReportTarget target,
    String targetId,
    ModerationAction action, {
    String? note,
  }) => _guard(
    () => _client.rpc<void>(
      'moderate_content',
      params: {
        'p_target': target.name,
        'p_target_id': targetId,
        'p_action': action.name,
        'p_note': note,
      },
    ),
  );
}

final communityRepositoryProvider = Provider<CommunityRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseCommunityRepository(client);
});
