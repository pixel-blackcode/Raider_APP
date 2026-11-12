import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../convoy/data/location_service.dart';
import '../../convoy/domain/convoy.dart';
import '../domain/sos.dart';
import 'sos_repository.dart';

/// Identifiant aléatoire (UUID v4) de l'alerte, choisi par l'appareil : un
/// renvoi après une coupure réseau ne crée pas de doublon côté serveur.
String newClientRef([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Alertes que J'envoie, par balade, avec leur état de transmission réel.
class SosOutbox extends Notifier<Map<String, OutgoingSos>> {
  /// Position mémorisée par alerte : réutilisée telle quelle au renvoi.
  final _positions = <String, RiderPosition?>{};

  @override
  Map<String, OutgoingSos> build() => const {};

  void _put(OutgoingSos o) => state = {...state, o.rideId: o};

  Future<void> send(String rideId, SosKind kind, {String? message}) async {
    final current = state[rideId];
    if (current != null && current.delivery == SosDelivery.sending) return;
    final outgoing = OutgoingSos(
      clientRef: newClientRef(),
      rideId: rideId,
      kind: kind,
      message: message,
      delivery: SosDelivery.sending,
    );
    _put(outgoing);
    _positions[outgoing.clientRef] = await _locate();
    await _transmit(outgoing);
  }

  /// Renvoie la même alerte (même identifiant) après un échec.
  Future<void> retry(String rideId) async {
    final o = state[rideId];
    if (o == null || o.delivery != SosDelivery.failed) return;
    _put(o.copyWith(delivery: SosDelivery.sending));
    await _transmit(state[rideId]!);
  }

  /// Oublie l'alerte locale (après clôture, ou abandon d'un envoi échoué).
  void clear(String rideId) {
    final o = state[rideId];
    if (o != null) _positions.remove(o.clientRef);
    state = {...state}..remove(rideId);
  }

  Future<RiderPosition?> _locate() async {
    final location = ref.read(locationServiceProvider);
    try {
      final access = await location.ensurePermission().timeout(
        const Duration(seconds: 20),
      );
      if (access != LocationAccess.granted) return null;
      return await location.current(timeout: const Duration(seconds: 8));
    } catch (_) {
      // Sans position, le serveur utilisera celle du mode Convoi.
      return null;
    }
  }

  Future<void> _transmit(OutgoingSos o) async {
    final repo = ref.read(sosRepositoryProvider);
    try {
      if (repo == null) {
        throw const AppException(AppException.backendUnavailable);
      }
      final alert = await repo
          .raise(
            rideId: o.rideId,
            kind: o.kind,
            clientRef: o.clientRef,
            message: o.message,
            position: _positions[o.clientRef],
          )
          .timeout(const Duration(seconds: 20));
      if (state[o.rideId]?.clientRef == o.clientRef) {
        _put(o.copyWith(delivery: SosDelivery.sent, alert: alert));
      }
    } catch (error) {
      // Jamais présentée comme envoyée sans réponse du serveur.
      if (state[o.rideId]?.clientRef == o.clientRef) {
        _put(o.copyWith(delivery: SosDelivery.failed, error: error));
      }
    }
  }
}

final sosOutboxProvider = NotifierProvider<SosOutbox, Map<String, OutgoingSos>>(
  SosOutbox.new,
);

final rideSosAlertsProvider = StreamProvider.autoDispose
    .family<List<SosAlert>, String>((ref, rideId) {
      final repo = ref.watch(sosRepositoryProvider);
      if (repo == null) return Stream.value(const []);
      return repo.watchRideAlerts(rideId);
    });

final rideSosAcksProvider = StreamProvider.autoDispose
    .family<List<SosAck>, String>((ref, rideId) {
      final repo = ref.watch(sosRepositoryProvider);
      if (repo == null) return Stream.value(const []);
      return repo.watchAcks(rideId);
    });
