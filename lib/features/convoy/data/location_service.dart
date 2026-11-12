import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/convoy.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// Localisation de l'appareil, application ouverte uniquement.
///
/// Le suivi en arrière-plan n'est PAS promis : Android et iOS peuvent
/// suspendre l'application écran éteint. L'interface l'indique.
abstract interface class LocationService {
  Future<LocationAccess> ensurePermission();

  /// Positions de l'appareil (userId vide : rempli par l'appelant).
  Stream<RiderPosition> positions();
}

class DeviceLocationService implements LocationService {
  @override
  Future<LocationAccess> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Stream<RiderPosition> positions() =>
      Geolocator.getPositionStream(
        // Filtre de distance : pas de mise à jour pour quelques mètres.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).map(
        (p) => RiderPosition(
          userId: '',
          lat: p.latitude,
          lng: p.longitude,
          recordedAt: p.timestamp.toUtc(),
          accuracyM: p.accuracy,
          headingDeg: p.heading < 0 ? null : p.heading,
          speedMps: p.speed < 0 ? null : p.speed,
        ),
      );
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => DeviceLocationService(),
);
