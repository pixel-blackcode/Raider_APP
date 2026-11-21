import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/badges.dart';

abstract interface class BadgesRepository {
  /// Mes badges (avec progression) si [userId] est null, sinon les badges
  /// obtenus de ce motard.
  Future<List<RiderBadge>> badges([String? userId]);

  Future<List<Challenge>> challenges();

  Future<AccountSuspension?> mySuspension();
}

class SupabaseBadgesRepository implements BadgesRepository {
  SupabaseBadgesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> _rows(
    String fn, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final data = await _client.rpc<Object?>(fn, params: params);
      return [
        for (final r in (data as List?) ?? const [])
          (r as Map).cast<String, dynamic>(),
      ];
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<List<RiderBadge>> badges([String? userId]) async => [
    for (final r in await _rows('rider_badges', {'p_user_id': userId}))
      RiderBadge.fromJson(r),
  ];

  @override
  Future<List<Challenge>> challenges() async => [
    for (final r in await _rows('my_challenges')) Challenge.fromJson(r),
  ];

  @override
  Future<AccountSuspension?> mySuspension() async {
    final rows = await _rows('my_suspension');
    return rows.isEmpty ? null : AccountSuspension.fromJson(rows.first);
  }
}

final badgesRepositoryProvider = Provider<BadgesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseBadgesRepository(client);
});

final myBadgesProvider = FutureProvider.autoDispose<List<RiderBadge>>((
  ref,
) async {
  final repo = ref.watch(badgesRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) {
    return const [];
  }
  return repo.badges();
});

final riderBadgesProvider = FutureProvider.autoDispose
    .family<List<RiderBadge>, String>((ref, userId) async {
      final repo = ref.watch(badgesRepositoryProvider);
      if (repo == null) return const [];
      try {
        return await repo.badges(userId);
      } catch (_) {
        return const []; // complément du profil : jamais bloquant
      }
    });

final challengesProvider = FutureProvider.autoDispose<List<Challenge>>((
  ref,
) async {
  final repo = ref.watch(badgesRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) {
    return const [];
  }
  return repo.challenges();
});

final mySuspensionProvider = FutureProvider.autoDispose<AccountSuspension?>((
  ref,
) async {
  final repo = ref.watch(badgesRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) return null;
  try {
    return await repo.mySuspension();
  } catch (_) {
    return null;
  }
});
