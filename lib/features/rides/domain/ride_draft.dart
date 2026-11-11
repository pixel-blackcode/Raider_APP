import 'ride.dart';

/// Données saisies pour créer ou modifier une balade.
class RideDraft {
  const RideDraft({
    required this.title,
    required this.startsAt,
    required this.city,
    required this.startLabel,
    required this.destinationLabel,
    required this.visibility,
    required this.joinPolicy,
    this.clubId,
    this.openToNonMembers = false,
    this.description = '',
    this.timezone = 'Africa/Kinshasa',
    this.itinerary = '',
    this.difficulty = RideDifficulty.moderate,
    this.bikeTypes = const {BikeType.any},
    this.maxParticipants,
    this.conditions = '',
    this.startLat,
    this.startLng,
  });

  factory RideDraft.fromRide(Ride ride) => RideDraft(
    title: ride.title,
    startsAt: ride.startsAt,
    city: ride.city,
    startLabel: ride.startLabel,
    destinationLabel: ride.destinationLabel,
    visibility: ride.visibility,
    joinPolicy: ride.joinPolicy,
    clubId: ride.clubId,
    openToNonMembers: ride.openToNonMembers,
    description: ride.description,
    timezone: ride.timezone,
    itinerary: ride.itinerary,
    difficulty: ride.difficulty,
    bikeTypes: ride.bikeTypes.toSet(),
    maxParticipants: ride.maxParticipants,
    conditions: ride.conditions,
    startLat: ride.startLat,
    startLng: ride.startLng,
  );

  final String title;

  /// Instant de départ (UTC).
  final DateTime startsAt;
  final String city;
  final String startLabel;
  final String destinationLabel;
  final RideVisibility visibility;
  final RideJoinPolicy joinPolicy;
  final String? clubId;
  final bool openToNonMembers;
  final String description;
  final String timezone;
  final String itinerary;
  final RideDifficulty difficulty;
  final Set<BikeType> bikeTypes;
  final int? maxParticipants;
  final String conditions;
  final double? startLat;
  final double? startLng;

  /// Problèmes de saisie (miroir des contraintes SQL de `rides`).
  List<RideDraftIssue> validate({
    required DateTime now,
    bool publishing = false,
  }) {
    final issues = <RideDraftIssue>[];
    bool between(String v, int min, int max) {
      final l = v.trim().length;
      return l >= min && l <= max;
    }

    if (!between(title, 3, 100)) issues.add(RideDraftIssue.title);
    if (!between(city, 2, 80)) issues.add(RideDraftIssue.city);
    if (!between(startLabel, 2, 120)) issues.add(RideDraftIssue.startLabel);
    if (!between(destinationLabel, 2, 120)) {
      issues.add(RideDraftIssue.destinationLabel);
    }
    if (description.length > 3000) issues.add(RideDraftIssue.description);
    if (itinerary.length > 3000) issues.add(RideDraftIssue.itinerary);
    if (conditions.length > 1000) issues.add(RideDraftIssue.conditions);
    if (maxParticipants != null &&
        (maxParticipants! < 2 || maxParticipants! > 500)) {
      issues.add(RideDraftIssue.maxParticipants);
    }
    if ((visibility == RideVisibility.club) != (clubId != null)) {
      issues.add(RideDraftIssue.club);
    }
    if (bikeTypes.isEmpty) issues.add(RideDraftIssue.bikeTypes);
    if (publishing && !startsAt.isAfter(now)) {
      issues.add(RideDraftIssue.startInPast);
    }
    return issues;
  }

  /// Colonnes modifiables directement (cf. GRANT UPDATE de la migration).
  Map<String, dynamic> toUpdateJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'starts_at': startsAt.toUtc().toIso8601String(),
    'timezone': timezone,
    'city': city.trim(),
    'start_label': startLabel.trim(),
    'destination_label': destinationLabel.trim(),
    'itinerary': itinerary.trim(),
    'difficulty': difficulty.dbValue,
    'recommended_bike_types': [for (final t in bikeTypes) t.dbValue],
    'max_participants': maxParticipants,
    'conditions': conditions.trim(),
    'visibility': visibility.dbValue,
    'open_to_non_members':
        visibility == RideVisibility.club && openToNonMembers,
    'join_policy': joinPolicy.dbValue,
  };
}

enum RideDraftIssue {
  title,
  city,
  startLabel,
  destinationLabel,
  description,
  itinerary,
  conditions,
  maxParticipants,
  club,
  bikeTypes,
  startInPast,
}
