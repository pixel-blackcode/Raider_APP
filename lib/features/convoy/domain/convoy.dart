import 'dart:math' as math;

/// Rôle dans le convoi (miroir de l'énumération SQL `convoy_role`).
enum ConvoyRole {
  leader('leader'),
  sweeper('sweeper');

  const ConvoyRole(this.dbValue);

  final String dbValue;

  static ConvoyRole? tryParse(String? value) {
    for (final r in values) {
      if (r.dbValue == value) return r;
    }
    return null;
  }
}

/// Dernière position connue d'un participant.
class RiderPosition {
  const RiderPosition({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.accuracyM,
    this.headingDeg,
    this.speedMps,
  });

  factory RiderPosition.fromJson(Map<String, dynamic> json) => RiderPosition(
    userId: json['user_id'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recorded_at'] as String).toUtc(),
    accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
    headingDeg: (json['heading_deg'] as num?)?.toDouble(),
    speedMps: (json['speed_mps'] as num?)?.toDouble(),
  );

  final String userId;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? accuracyM;
  final double? headingDeg;
  final double? speedMps;
}

/// Ancienneté d'une position.
enum Freshness {
  /// Moins d'une minute.
  live,

  /// Entre 1 et 3 minutes : réseau faible ou arrêt possible.
  aging,

  /// Plus de 3 minutes : position périmée, affichée comme telle.
  stale,
}

/// Alerte informative : jamais une conclusion (panne, accident...).
enum ConvoyAlert {
  /// Position périmée : réseau absent, arrêt volontaire ou autre cause.
  staleSignal,

  /// Position récente mais loin du chef de convoi.
  possiblySeparated,
}

/// Seuils de la détection, réglables en un seul endroit.
abstract final class ConvoyThresholds {
  static const liveFor = Duration(minutes: 1);
  static const staleAfter = Duration(minutes: 3);

  /// Distance au chef de convoi au-delà de laquelle on signale un écart.
  static const separationMeters = 2000.0;
}

abstract final class ConvoyMath {
  static const _earthRadiusM = 6371000.0;

  /// Distance orthodromique (formule de haversine), en mètres.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
  }

  static Freshness freshness(DateTime recordedAt, DateTime now) {
    final age = now.difference(recordedAt);
    if (age <= ConvoyThresholds.liveFor) return Freshness.live;
    if (age <= ConvoyThresholds.staleAfter) return Freshness.aging;
    return Freshness.stale;
  }
}

/// Un participant tel que le mode Convoi l'affiche.
class ConvoyMember {
  const ConvoyMember({
    required this.userId,
    required this.name,
    this.position,
    this.role,
    this.freshness,
    this.distanceToLeaderM,
    this.alert,
  });

  final String userId;
  final String name;
  final RiderPosition? position;
  final ConvoyRole? role;
  final Freshness? freshness;
  final double? distanceToLeaderM;
  final ConvoyAlert? alert;

  bool get isSharing => position != null;
}

/// Construit l'état du convoi à partir des positions, des rôles et des
/// participants. Prudence : une position périmée n'est jamais interprétée
/// comme un écart, et l'écart n'est calculé qu'entre positions récentes.
List<ConvoyMember> buildConvoy({
  required Map<String, String> participants,
  required List<RiderPosition> positions,
  required Map<ConvoyRole, String> roles,
  required DateTime now,
}) {
  final byUser = {for (final p in positions) p.userId: p};
  final leaderId = roles[ConvoyRole.leader];
  final leaderPos = leaderId == null ? null : byUser[leaderId];
  final leaderUsable =
      leaderPos != null &&
      ConvoyMath.freshness(leaderPos.recordedAt, now) != Freshness.stale;

  ConvoyRole? roleOf(String id) {
    for (final e in roles.entries) {
      if (e.value == id) return e.key;
    }
    return null;
  }

  final members = <ConvoyMember>[];
  for (final entry in participants.entries) {
    final pos = byUser[entry.key];
    final role = roleOf(entry.key);
    final fresh = pos == null
        ? null
        : ConvoyMath.freshness(pos.recordedAt, now);
    double? distance;
    ConvoyAlert? alert;
    if (pos != null) {
      if (fresh == Freshness.stale) {
        alert = ConvoyAlert.staleSignal;
      } else if (leaderUsable && entry.key != leaderId) {
        distance = ConvoyMath.distanceMeters(
          leaderPos.lat,
          leaderPos.lng,
          pos.lat,
          pos.lng,
        );
        if (distance > ConvoyThresholds.separationMeters) {
          alert = ConvoyAlert.possiblySeparated;
        }
      }
    }
    members.add(
      ConvoyMember(
        userId: entry.key,
        name: entry.value,
        position: pos,
        role: role,
        freshness: fresh,
        distanceToLeaderM: distance,
        alert: alert,
      ),
    );
  }
  int rank(ConvoyMember m) => m.role == ConvoyRole.leader
      ? 0
      : m.role == ConvoyRole.sweeper
      ? 2
      : 1;
  members.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return members;
}

/// Fréquence d'envoi adaptative : économise batterie et données.
abstract final class PublishCadence {
  static Duration intervalFor({double? speedMps}) {
    final speed = speedMps ?? 0;
    if (speed < 1) return const Duration(seconds: 30); // à l'arrêt
    if (speed < 8) return const Duration(seconds: 15); // en ville
    return const Duration(seconds: 8); // sur route
  }
}
