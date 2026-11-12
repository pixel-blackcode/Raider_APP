import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../convoy/domain/convoy.dart';
import '../domain/sos.dart';

/// Alertes SOS. Les destinataires et les droits sont décidés par le serveur.
abstract interface class SosRepository {
  /// Envoi idempotent : renvoyer le même `clientRef` ne crée pas de doublon.
  Future<SosAlert> raise({
    required String rideId,
    required SosKind kind,
    required String clientRef,
    String? message,
    RiderPosition? position,
  });

  Future<void> acknowledge(String alertId);

  Future<SosAlert> close(String alertId, SosStatus status, {String? note});

  /// Alertes visibles d'une balade (temps réel).
  Stream<List<SosAlert>> watchRideAlerts(String rideId);

  /// Alertes récentes visibles, toutes balades confondues (temps réel).
  Stream<List<SosAlert>> watchRecentAlerts();

  Stream<List<SosAck>> watchAcks(String rideId);
}

class SupabaseSosRepository implements SosRepository {
  SupabaseSosRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<SosAlert> raise({
    required String rideId,
    required SosKind kind,
    required String clientRef,
    String? message,
    RiderPosition? position,
  }) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'raise_sos',
      params: {
        'p_ride_id': rideId,
        'p_kind': kind.dbValue,
        'p_client_ref': clientRef,
        'p_message': message,
        'p_lat': position?.lat,
        'p_lng': position?.lng,
        'p_recorded_at': position?.recordedAt.toUtc().toIso8601String(),
        'p_accuracy_m': position?.accuracyM,
      },
    );
    return SosAlert.fromJson(row);
  });

  @override
  Future<void> acknowledge(String alertId) => _guard(
    () => _client.rpc<void>('acknowledge_sos', params: {'p_alert_id': alertId}),
  );

  @override
  Future<SosAlert> close(String alertId, SosStatus status, {String? note}) =>
      _guard(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'close_sos',
          params: {
            'p_alert_id': alertId,
            'p_status': status.dbValue,
            'p_note': note,
          },
        );
        return SosAlert.fromJson(row);
      });

  @override
  Stream<List<SosAlert>> watchRideAlerts(String rideId) => _client
      .from('sos_alerts')
      .stream(primaryKey: ['id'])
      .eq('ride_id', rideId)
      .order('created_at')
      .map((rows) => rows.map(SosAlert.fromJson).toList());

  @override
  Stream<List<SosAlert>> watchRecentAlerts() => _client
      .from('sos_alerts')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .limit(30)
      .map((rows) => rows.map(SosAlert.fromJson).toList());

  @override
  Stream<List<SosAck>> watchAcks(String rideId) => _client
      .from('sos_acknowledgements')
      .stream(primaryKey: ['alert_id', 'user_id'])
      .eq('ride_id', rideId)
      .map((rows) => rows.map(SosAck.fromJson).toList());
}

final sosRepositoryProvider = Provider<SosRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSosRepository(client);
});
