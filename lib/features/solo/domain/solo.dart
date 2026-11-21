/// Mode solo (Mission 10 bis, D-70) : trajet seul suivi par 1 ou 2 proches.
library;

/// Lien « proche » entre deux motards.
class SoloContact {
  const SoloContact({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.accepted,
    required this.incoming,
    this.avatarPath,
  });

  factory SoloContact.fromJson(Map<String, dynamic> j) => SoloContact(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    displayName: (j['display_name'] as String?) ?? '',
    avatarPath: j['avatar_path'] as String?,
    accepted: j['status'] == 'accepted',
    incoming: (j['incoming'] as bool?) ?? false,
  );

  final String id;

  /// L'autre motard.
  final String userId;
  final String displayName;
  final String? avatarPath;
  final bool accepted;

  /// true : l'autre m'a demandé de suivre SES trajets (je suis son proche).
  /// false : j'ai demandé à l'autre de suivre MES trajets.
  final bool incoming;

  /// Peut être choisi pour suivre mon trajet.
  bool get canWatchMe => accepted && !incoming;
}

enum SoloTripStatus {
  active,
  arrived,
  cancelled,
  expired;

  static SoloTripStatus parse(String? v) => switch (v) {
    'arrived' => arrived,
    'cancelled' => cancelled,
    'expired' => expired,
    _ => active,
  };
}

class SoloWatcher {
  const SoloWatcher(this.userId, this.displayName);

  final String userId;
  final String displayName;
}

class SoloTrip {
  const SoloTrip({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.mine,
    required this.status,
    required this.startedAt,
    required this.expectedAt,
    required this.shareLocation,
    this.avatarPath,
    this.destination,
    this.lastLat,
    this.lastLng,
    this.lastPositionAt,
    this.lastOkAt,
    this.overdueAt,
    this.endedAt,
    this.watchers = const [],
  });

  factory SoloTrip.fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) =>
        j[k] == null ? null : DateTime.parse(j[k] as String).toUtc();
    return SoloTrip(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      displayName: (j['display_name'] as String?) ?? '',
      avatarPath: j['avatar_path'] as String?,
      mine: (j['mine'] as bool?) ?? false,
      destination: j['destination'] as String?,
      status: SoloTripStatus.parse(j['status'] as String?),
      startedAt: d('started_at')!,
      expectedAt: d('expected_at')!,
      shareLocation: (j['share_location'] as bool?) ?? false,
      lastLat: (j['last_lat'] as num?)?.toDouble(),
      lastLng: (j['last_lng'] as num?)?.toDouble(),
      lastPositionAt: d('last_position_at'),
      lastOkAt: d('last_ok_at'),
      overdueAt: d('overdue_at'),
      endedAt: d('ended_at'),
      watchers: [
        for (final w in (j['watchers'] as List?) ?? const [])
          SoloWatcher(
            (w as Map)['user_id'] as String,
            (w['display_name'] as String?) ?? '',
          ),
      ],
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final String? avatarPath;

  /// Mon trajet (sinon : je suis l'un des proches).
  final bool mine;
  final String? destination;
  final SoloTripStatus status;
  final DateTime startedAt;
  final DateTime expectedAt;
  final bool shareLocation;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastPositionAt;
  final DateTime? lastOkAt;
  final DateTime? overdueAt;
  final DateTime? endedAt;
  final List<SoloWatcher> watchers;

  bool get active => status == SoloTripStatus.active;

  bool get hasPosition => lastLat != null && lastLng != null;

  /// En retard : l'heure prévue est passée sans confirmation d'arrivée.
  bool isLate(DateTime now) => active && !now.isBefore(expectedAt);
}

/// Durées proposées au départ (minutes).
const soloDurations = [15, 30, 45, 60, 90, 120];
