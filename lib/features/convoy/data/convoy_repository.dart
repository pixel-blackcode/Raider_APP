import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/convoy.dart';

/// Accès aux positions et rôles du convoi. Toutes les règles (participant
/// confirmé, balade en cours, consentement, fréquence) sont appliquées par
/// le serveur.
abstract interface class ConvoyRepository {
  /// Positions visibles, mises à jour en temps réel.
  Stream<List<RiderPosition>> watchPositions(String rideId);

  Future<Map<ConvoyRole, String>> roles(String rideId);

  Future<bool> isSharing(String rideId, String userId);

  Future<void> setSharing(String rideId, {required bool enabled});

  Future<void> publish(String rideId, RiderPosition position);

  /// `userId` null : retire le rôle.
  Future<void> setRole(String rideId, ConvoyRole role, String? userId);

  /// Itinéraire parcouru par le chef de convoi (balade en cours).
  Future<List<TrailPoint>> trail(String rideId);
}

class SupabaseConvoyRepository implements ConvoyRepository {
  SupabaseConvoyRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Stream<List<RiderPosition>> watchPositions(String rideId) => _client
      .from('ride_positions')
      .stream(primaryKey: ['ride_id', 'user_id'])
      .eq('ride_id', rideId)
      .map((rows) => rows.map(RiderPosition.fromJson).toList());

  @override
  Future<Map<ConvoyRole, String>> roles(String rideId) => _guard(() async {
    final rows = await _client
        .from('ride_role_assignments')
        .select('role, user_id')
        .eq('ride_id', rideId);
    return {
      for (final r in rows)
        if (ConvoyRole.tryParse(r['role'] as String?) != null)
          ConvoyRole.tryParse(r['role'] as String?)!: r['user_id'] as String,
    };
  });

  @override
  Future<List<TrailPoint>> trail(String rideId) => _guard(() async {
    final rows = await _client
        .from('ride_trail_points')
        .select('lat, lng, recorded_at')
        .eq('ride_id', rideId)
        .order('recorded_at')
        .limit(5000);
    return rows.map(TrailPoint.fromJson).toList();
  });

  @override
  Future<bool> isSharing(String rideId, String userId) => _guard(() async {
    final row = await _client
        .from('ride_location_shares')
        .select('enabled')
        .eq('ride_id', rideId)
        .eq('user_id', userId)
        .maybeSingle();
    return (row?['enabled'] as bool?) ?? false;
  });

  @override
  Future<void> setSharing(String rideId, {required bool enabled}) => _guard(
    () => _client.rpc<void>(
      'set_location_sharing',
      params: {'p_ride_id': rideId, 'p_enabled': enabled},
    ),
  );

  @override
  Future<void> publish(String rideId, RiderPosition p) => _guard(
    () => _client.rpc<void>(
      'publish_position',
      params: {
        'p_ride_id': rideId,
        'p_lat': p.lat,
        'p_lng': p.lng,
        'p_recorded_at': p.recordedAt.toUtc().toIso8601String(),
        'p_accuracy_m': p.accuracyM,
        'p_heading_deg': p.headingDeg,
        'p_speed_mps': p.speedMps,
      },
    ),
  );

  @override
  Future<void> setRole(String rideId, ConvoyRole role, String? userId) =>
      _guard(
        () => _client.rpc<void>(
          'set_convoy_role',
          params: {
            'p_ride_id': rideId,
            'p_role': role.dbValue,
            'p_user_id': userId,
          },
        ),
      );
}

final convoyRepositoryProvider = Provider<ConvoyRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseConvoyRepository(client);
});
