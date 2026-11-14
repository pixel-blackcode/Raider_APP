/// Notification affichée dans la cloche (Mission 08 ter).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.rideId,
    this.rideTitle,
    this.clubId,
    this.clubName,
    this.postId,
    this.refId,
    this.data = const {},
    this.readAt,
    this.actionable = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    kind: j['kind'] as String,
    actorId: j['actor_id'] as String?,
    actorName: j['actor_name'] as String?,
    actorAvatar: j['actor_avatar'] as String?,
    rideId: j['ride_id'] as String?,
    rideTitle: j['ride_title'] as String?,
    clubId: j['club_id'] as String?,
    clubName: j['club_name'] as String?,
    postId: j['post_id'] as String?,
    refId: j['ref_id'] as String?,
    data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    readAt: j['read_at'] == null
        ? null
        : DateTime.parse(j['read_at'] as String).toUtc(),
    actionable: (j['actionable'] as bool?) ?? false,
  );

  final String id;

  /// ride_join_request, ride_joined, ride_request_approved, … (voir SQL).
  final String kind;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final String? rideId;
  final String? rideTitle;
  final String? clubId;
  final String? clubName;
  final String? postId;

  /// Demande ou invitation concernée.
  final String? refId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Demande ou invitation encore en attente de réponse.
  final bool actionable;

  bool get unread => readAt == null;
}
