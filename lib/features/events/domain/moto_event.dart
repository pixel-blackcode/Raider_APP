/// Événement moto (D-56) : organisé par un club ou un regroupement vérifié.
class MotoEvent {
  const MotoEvent({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    required this.startsAt,
    required this.placeName,
    required this.city,
    this.clubIsRegroupement = false,
    this.description = '',
    this.endsAt,
    this.lat,
    this.lng,
    this.coverPath,
    this.cancelledAt,
    this.attendeeCount = 0,
    this.iAmGoing = false,
    this.canManage = false,
    this.coOrganizers = const [],
  });

  factory MotoEvent.fromJson(Map<String, dynamic> j) => MotoEvent(
    id: j['id'] as String,
    clubId: j['club_id'] as String,
    clubName: (j['club_name'] as String?) ?? '',
    clubIsRegroupement: (j['club_is_regroupement'] as bool?) ?? false,
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    startsAt: DateTime.parse(j['starts_at'] as String).toUtc(),
    endsAt: _date(j['ends_at']),
    placeName: (j['place_name'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    coverPath: j['cover_path'] as String?,
    cancelledAt: _date(j['cancelled_at']),
    attendeeCount: (j['attendee_count'] as num?)?.toInt() ?? 0,
    iAmGoing: (j['i_am_going'] as bool?) ?? false,
    canManage: (j['can_manage'] as bool?) ?? false,
    coOrganizers: [
      for (final o in (j['coorganizers'] as List?) ?? const [])
        EventCoOrganizer.fromJson((o as Map).cast<String, dynamic>()),
    ],
  );

  final String id;
  final String clubId;
  final String clubName;
  final bool clubIsRegroupement;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String placeName;
  final String city;
  final double? lat;
  final double? lng;
  final String? coverPath;
  final DateTime? cancelledAt;
  final int attendeeCount;
  final bool iAmGoing;
  final bool canManage;

  /// Co-organisateurs : acceptés (tout le monde) et, pour les gestionnaires,
  /// les invitations en attente ou refusées.
  final List<EventCoOrganizer> coOrganizers;

  bool get isCancelled => cancelledAt != null;
}

class EventCoOrganizer {
  const EventCoOrganizer({
    required this.invitationId,
    required this.clubId,
    required this.name,
    required this.status,
  });

  factory EventCoOrganizer.fromJson(Map<String, dynamic> j) => EventCoOrganizer(
    invitationId: j['invitation_id'] as String,
    clubId: j['club_id'] as String,
    name: (j['name'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'pending',
  );

  final String invitationId;
  final String clubId;
  final String name;

  /// pending, accepted ou declined.
  final String status;
}

/// Saisie d'un événement.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.startsAt,
    required this.placeName,
    required this.city,
    this.description = '',
    this.endsAt,
  });

  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String placeName;
  final String city;
  final String description;

  Map<String, dynamic> toParams() => {
    'p_title': title.trim(),
    'p_starts_at': startsAt.toUtc().toIso8601String(),
    'p_place_name': placeName.trim(),
    'p_city': city.trim(),
    'p_description': description.trim(),
    'p_ends_at': endsAt?.toUtc().toIso8601String(),
  };
}

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;
