import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../../convoy/data/location_service.dart';
import '../domain/solo.dart';

abstract interface class SoloRepository {
  Future<List<SoloContact>> contacts();

  /// Demande à un motard d'accepter de suivre mes trajets.
  Future<void> requestContact(String userId);

  Future<void> respondContact(String contactId, {required bool accept});

  Future<void> removeContact(String contactId);

  /// Mes trajets et ceux que je suis (en cours, ou finis depuis moins de 12 h).
  Future<List<SoloTrip>> trips();

  Future<String> startTrip({
    required List<String> watcherIds,
    required int minutes,
    required bool shareLocation,
    String? destination,
  });

  Future<void> updateLocation(
    String tripId,
    double lat,
    double lng,
    double? accuracyM,
  );

  Future<void> setSharing(String tripId, {required bool share});

  /// Envoie la position aux proches (réponse à une demande).
  Future<void> sendPosition(
    String tripId,
    double lat,
    double lng,
    double? accuracyM,
  );

  /// « Je vais bien », avec éventuellement du temps en plus.
  Future<void> imOk(String tripId, {int extraMinutes = 0});

  Future<void> arrive(String tripId);

  Future<void> cancel(String tripId);

  /// Un proche demande des nouvelles ([position] : demande la position).
  Future<void> askNews(String tripId, {bool position = false});
}

class SupabaseSoloRepository implements SoloRepository {
  SupabaseSoloRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> _rpc(String name, Map<String, dynamic> params) =>
      _guard(() => _client.rpc<void>(name, params: params));

  @override
  Future<List<SoloContact>> contacts() => _guard(() async {
    final data = await _client.rpc<Object?>('my_solo_contacts');
    return [
      for (final r in (data as List?) ?? const [])
        SoloContact.fromJson(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> requestContact(String userId) =>
      _rpc('request_solo_contact', {'p_user_id': userId});

  @override
  Future<void> respondContact(String contactId, {required bool accept}) =>
      _rpc('respond_solo_contact', {'p_id': contactId, 'p_accept': accept});

  @override
  Future<void> removeContact(String contactId) =>
      _rpc('remove_solo_contact', {'p_id': contactId});

  @override
  Future<List<SoloTrip>> trips() => _guard(() async {
    final data = await _client.rpc<Object?>('my_solo_trips');
    return [
      for (final r in (data as List?) ?? const [])
        SoloTrip.fromJson(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<String> startTrip({
    required List<String> watcherIds,
    required int minutes,
    required bool shareLocation,
    String? destination,
  }) => _guard(() async {
    final id = await _client.rpc<Object?>(
      'start_solo_trip',
      params: {
        'p_watchers': watcherIds,
        'p_minutes': minutes,
        'p_share_location': shareLocation,
        'p_destination': destination,
      },
    );
    return id as String;
  });

  @override
  Future<void> updateLocation(
    String tripId,
    double lat,
    double lng,
    double? accuracyM,
  ) => _rpc('update_solo_location', {
    'p_trip_id': tripId,
    'p_lat': lat,
    'p_lng': lng,
    'p_accuracy_m': accuracyM,
  });

  @override
  Future<void> setSharing(String tripId, {required bool share}) =>
      _rpc('set_solo_sharing', {'p_trip_id': tripId, 'p_share': share});

  @override
  Future<void> sendPosition(
    String tripId,
    double lat,
    double lng,
    double? accuracyM,
  ) => _rpc('send_solo_position', {
    'p_trip_id': tripId,
    'p_lat': lat,
    'p_lng': lng,
    'p_accuracy_m': accuracyM,
  });

  @override
  Future<void> imOk(String tripId, {int extraMinutes = 0}) => _guard(
    () => _client.rpc<Object?>(
      'solo_im_ok',
      params: {'p_trip_id': tripId, 'p_extra_minutes': extraMinutes},
    ),
  );

  @override
  Future<void> arrive(String tripId) =>
      _rpc('arrive_solo_trip', {'p_trip_id': tripId});

  @override
  Future<void> cancel(String tripId) =>
      _rpc('cancel_solo_trip', {'p_trip_id': tripId});

  @override
  Future<void> askNews(String tripId, {bool position = false}) => _rpc(
    'ask_solo_news',
    {'p_trip_id': tripId, 'p_what': position ? 'position' : 'news'},
  );
}

final soloRepositoryProvider = Provider<SoloRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSoloRepository(client);
});

final soloContactsProvider = FutureProvider.autoDispose<List<SoloContact>>((
  ref,
) async {
  final repo = ref.watch(soloRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) {
    return const [];
  }
  return repo.contacts();
});

final soloTripsProvider = FutureProvider.autoDispose<List<SoloTrip>>((
  ref,
) async {
  final repo = ref.watch(soloRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) {
    return const [];
  }
  return repo.trips();
});

/// Mon trajet en cours, s'il y en a un.
final myActiveSoloTripProvider = Provider.autoDispose<SoloTrip?>((ref) {
  final trips = ref.watch(soloTripsProvider).value ?? const [];
  for (final t in trips) {
    if (t.mine && t.active) return t;
  }
  return null;
});

extension RefreshSolo on WidgetRef {
  void refreshSolo() {
    invalidate(soloTripsProvider);
    invalidate(soloContactsProvider);
  }
}

/// Envoie la position du téléphone pendant le trajet, si le motard l'a choisi
/// (au plus une fois par minute). Actif tant qu'un écran le regarde
/// (écran Mode solo ou bandeau de l'accueil), application ouverte.
final soloLocationSharingProvider = Provider.autoDispose<void>((ref) {
  final trip = ref.watch(myActiveSoloTripProvider);
  final repo = ref.watch(soloRepositoryProvider);
  if (trip == null || !trip.shareLocation || repo == null) return;
  final location = ref.watch(locationServiceProvider);
  DateTime? lastSent;
  StreamSubscription<void>? sub;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    sub?.cancel();
  });
  Future<void> start() async {
    if (await location.ensurePermission() != LocationAccess.granted) return;
    if (disposed) return;
    sub = location.positions().listen((p) async {
      final now = DateTime.now();
      if (lastSent != null && now.difference(lastSent!).inSeconds < 60) return;
      lastSent = now;
      try {
        await repo.updateLocation(trip.id, p.lat, p.lng, p.accuracyM);
      } catch (_) {
        // Réseau absent : la position suivante sera envoyée plus tard.
      }
    });
  }

  unawaited(start());
});
