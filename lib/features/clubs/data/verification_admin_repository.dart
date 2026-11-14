import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/club.dart';

/// Outils réservés à l'équipe Rider Group (le serveur refuse tout autre
/// compte, même si l'écran était affiché).
abstract interface class VerificationAdminRepository {
  Future<bool> amIPlatformAdmin();

  Future<List<VerificationQueueItem>> queue();

  Future<void> review(
    String requestId, {
    required bool approve,
    String? note,
    DateTime? validUntil,
  });

  Future<void> revoke(String clubId, {String? note});
}

class SupabaseVerificationAdminRepository
    implements VerificationAdminRepository {
  SupabaseVerificationAdminRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<bool> amIPlatformAdmin() => _guard(
    () async => (await _client.rpc<bool?>('am_i_platform_admin')) ?? false,
  );

  @override
  Future<List<VerificationQueueItem>> queue() => _guard(() async {
    final data = await _client.rpc<Object?>('verification_queue');
    return [
      for (final r in (data as List?) ?? const [])
        VerificationQueueItem.fromJson(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> review(
    String requestId, {
    required bool approve,
    String? note,
    DateTime? validUntil,
  }) => _guard(
    () => _client.rpc<void>(
      'review_club_verification',
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_note': note,
        'p_valid_until': validUntil?.toUtc().toIso8601String(),
      },
    ),
  );

  @override
  Future<void> revoke(String clubId, {String? note}) => _guard(
    () => _client.rpc<void>(
      'revoke_club_verification',
      params: {'p_club_id': clubId, 'p_note': note},
    ),
  );
}

final verificationAdminRepositoryProvider =
    Provider<VerificationAdminRepository?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return client == null
          ? null
          : SupabaseVerificationAdminRepository(client);
    });

final amIPlatformAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(verificationAdminRepositoryProvider);
  if (repo == null) return false;
  return repo.amIPlatformAdmin();
});

final verificationQueueProvider =
    FutureProvider.autoDispose<List<VerificationQueueItem>>((ref) async {
      final repo = ref.watch(verificationAdminRepositoryProvider);
      if (repo == null) return const [];
      return repo.queue();
    });
