/// Statut d'une balade (miroir de l'énumération SQL `ride_status`).
enum RideStatus {
  draft('draft'),
  published('published'),
  locked('locked'),
  inProgress('in_progress'),
  finished('finished'),
  cancelled('cancelled');

  const RideStatus(this.dbValue);

  final String dbValue;

  static RideStatus parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);

  bool get isTerminal => this == finished || this == cancelled;
}

enum RideVisibility {
  public('public'),
  private('private'),
  club('club');

  const RideVisibility(this.dbValue);

  final String dbValue;

  static RideVisibility parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

enum RideJoinPolicy {
  open('open'),
  approval('approval'),
  inviteOnly('invite_only');

  const RideJoinPolicy(this.dbValue);

  final String dbValue;

  static RideJoinPolicy parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

enum RideDifficulty {
  easy('easy'),
  moderate('moderate'),
  hard('hard'),
  expert('expert');

  const RideDifficulty(this.dbValue);

  final String dbValue;

  static RideDifficulty parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

/// Types de motos recommandés (miroir de `private.ride_bike_types()`).
enum BikeType {
  any('any'),
  scooter('scooter'),
  roadster('roadster'),
  sport('sport'),
  trail('trail'),
  enduro('enduro'),
  custom('custom'),
  touring('touring'),
  quad('quad');

  const BikeType(this.dbValue);

  final String dbValue;

  static BikeType? tryParse(String value) {
    for (final v in values) {
      if (v.dbValue == value) return v;
    }
    return null;
  }
}

enum ParticipantStatus {
  pending('pending'),
  confirmed('confirmed'),
  rejected('rejected'),
  cancelled('cancelled'),
  left('left'),
  removed('removed');

  const ParticipantStatus(this.dbValue);

  final String dbValue;

  static ParticipantStatus parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

/// Actions de changement de statut (miroir de `set_ride_status`).
enum RideAction { publish, lock, unlock, start, finish, cancel }

/// Résultat d'une demande de participation.
enum RideJoinOutcome { joined, requested }

class Ride {
  const Ride({
    required this.id,
    required this.title,
    required this.organizerId,
    required this.startsAt,
    required this.city,
    required this.startLabel,
    required this.destinationLabel,
    required this.visibility,
    required this.joinPolicy,
    required this.status,
    this.description = '',
    this.clubId,
    this.clubName,
    this.organizerName,
    this.endsAt,
    this.timezone = 'Africa/Kinshasa',
    this.startLat,
    this.startLng,
    this.destinationLat,
    this.destinationLng,
    this.itinerary = '',
    this.difficulty = RideDifficulty.moderate,
    this.bikeTypes = const [BikeType.any],
    this.maxParticipants,
    this.conditions = '',
    this.openToNonMembers = false,
    this.joinsLocked = false,
    this.participantCount = 0,
    this.cancellationReason,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final club = json['clubs'] as Map<String, dynamic>?;
    final organizer = json['organizer'] as Map<String, dynamic>?;
    return Ride(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      organizerId: json['organizer_id'] as String,
      organizerName: organizer?['display_name'] as String?,
      clubId: json['club_id'] as String?,
      clubName: club?['name'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String).toUtc(),
      timezone: (json['timezone'] as String?) ?? 'Africa/Kinshasa',
      city: json['city'] as String,
      startLabel: json['start_label'] as String,
      startLat: (json['start_lat'] as num?)?.toDouble(),
      startLng: (json['start_lng'] as num?)?.toDouble(),
      destinationLabel: json['destination_label'] as String,
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
      itinerary: (json['itinerary'] as String?) ?? '',
      difficulty: RideDifficulty.parse(
        (json['difficulty'] as String?) ?? 'moderate',
      ),
      bikeTypes: [
        for (final raw in (json['recommended_bike_types'] as List?) ?? const [])
          ?BikeType.tryParse(raw as String),
      ],
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      conditions: (json['conditions'] as String?) ?? '',
      visibility: RideVisibility.parse(json['visibility'] as String),
      openToNonMembers: (json['open_to_non_members'] as bool?) ?? false,
      joinPolicy: RideJoinPolicy.parse(json['join_policy'] as String),
      status: RideStatus.parse(json['status'] as String),
      joinsLocked: (json['joins_locked'] as bool?) ?? false,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String? organizerName;
  final String? clubId;
  final String? clubName;

  /// Instant de départ (UTC). L'affichage se fait dans [timezone].
  final DateTime startsAt;
  final DateTime? endsAt;

  /// Fuseau IANA de la balade (ex. Africa/Kinshasa, Africa/Lubumbashi).
  final String timezone;
  final String city;
  final String startLabel;
  final double? startLat;
  final double? startLng;
  final String destinationLabel;
  final double? destinationLat;
  final double? destinationLng;
  final String itinerary;
  final RideDifficulty difficulty;
  final List<BikeType> bikeTypes;
  final int? maxParticipants;
  final String conditions;
  final RideVisibility visibility;
  final bool openToNonMembers;
  final RideJoinPolicy joinPolicy;
  final RideStatus status;
  final bool joinsLocked;
  final int participantCount;
  final String? cancellationReason;

  bool get isFull =>
      maxParticipants != null && participantCount >= maxParticipants!;
}

class RideParticipant {
  const RideParticipant({
    required this.userId,
    required this.status,
    this.displayName = '',
    this.username = '',
    this.avatarPath,
    this.message,
  });

  factory RideParticipant.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? const {};
    return RideParticipant(
      userId: json['user_id'] as String,
      status: ParticipantStatus.parse(json['status'] as String),
      displayName: (profile['display_name'] as String?) ?? '',
      username: (profile['username'] as String?) ?? '',
      avatarPath: profile['avatar_path'] as String?,
      message: json['message'] as String?,
    );
  }

  final String userId;
  final ParticipantStatus status;

  /// Vide si le profil n'est pas visible (confidentialité).
  final String displayName;
  final String username;
  final String? avatarPath;
  final String? message;
}

/// Une balade vue par l'utilisateur : organisateur ou participant.
class MyRide {
  const MyRide({required this.ride, required this.status});

  final Ride ride;
  final ParticipantStatus status;
}

class RideInvitation {
  const RideInvitation({
    required this.id,
    required this.rideId,
    required this.rideTitle,
    this.startsAt,
    this.timezone = 'Africa/Kinshasa',
    this.inviterName,
  });

  factory RideInvitation.fromJson(Map<String, dynamic> json) {
    final ride = (json['rides'] as Map<String, dynamic>?) ?? const {};
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return RideInvitation(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      rideTitle: (ride['title'] as String?) ?? '',
      startsAt: ride['starts_at'] == null
          ? null
          : DateTime.parse(ride['starts_at'] as String).toUtc(),
      timezone: (ride['timezone'] as String?) ?? 'Africa/Kinshasa',
      inviterName: inviter?['display_name'] as String?,
    );
  }

  final String id;
  final String rideId;
  final String rideTitle;
  final DateTime? startsAt;
  final String timezone;
  final String? inviterName;
}
