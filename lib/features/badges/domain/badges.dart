/// Badges et défis (Mission 11, D-71). Jamais de classement ni de vitesse.
library;

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();

class RiderBadge {
  const RiderBadge({
    required this.code,
    required this.title,
    required this.earned,
    this.description,
    this.period,
    this.awardedAt,
    this.progress,
    this.target,
  });

  factory RiderBadge.fromJson(Map<String, dynamic> j) => RiderBadge(
    code: j['code'] as String,
    title: (j['title'] as String?) ?? '',
    description: j['description'] as String?,
    period: j['period'] as String?,
    awardedAt: _date(j['awarded_at']),
    earned: (j['earned'] as bool?) ?? false,
    progress: (j['progress'] as num?)?.toDouble(),
    target: (j['target'] as num?)?.toDouble(),
  );

  /// first_ride, road_1000, challenge, ride_of_month…
  final String code;
  final String title;
  final String? description;

  /// « 2026-10 » pour un défi ou la meilleure balade du mois.
  final String? period;
  final DateTime? awardedAt;
  final bool earned;

  /// Progression (seulement pour mes propres badges non obtenus).
  final double? progress;
  final double? target;

  double get ratio => (target == null || target == 0 || progress == null)
      ? 0
      : (progress! / target!).clamp(0, 1).toDouble();
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.startsOn,
    required this.endsOn,
    required this.progress,
    required this.completed,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    metric: (j['metric'] as String?) ?? '',
    target: (j['target'] as num?)?.toInt() ?? 1,
    startsOn: DateTime.parse(j['starts_on'] as String),
    endsOn: DateTime.parse(j['ends_on'] as String),
    progress: (j['progress'] as num?)?.toDouble() ?? 0,
    completed: (j['completed'] as bool?) ?? false,
  );

  final String id;
  final String title;
  final String description;

  /// rides_finished, ride_distance, distance_total, maintenance…
  final String metric;
  final int target;
  final DateTime startsOn;
  final DateTime endsOn;
  final double progress;
  final bool completed;

  bool get isDistance =>
      metric == 'ride_distance' || metric == 'distance_total';

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0, 1);

  /// Jours restants (0 le dernier jour, négatif si terminé).
  int daysLeft(DateTime today) => DateTime(
    endsOn.year,
    endsOn.month,
    endsOn.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
}

class AccountSuspension {
  const AccountSuspension({required this.reason, this.until});

  factory AccountSuspension.fromJson(Map<String, dynamic> j) =>
      AccountSuspension(
        reason: (j['reason'] as String?) ?? '',
        until: _date(j['until']),
      );

  final String reason;

  /// null : sans fin.
  final DateTime? until;
}
