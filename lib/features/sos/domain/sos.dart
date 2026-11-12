/// Assistance et SOS (Mission 06).
///
/// Une alerte n'est considérée comme transmise que lorsque le serveur l'a
/// enregistrée (critère d'acceptation 12) : tant que ce n'est pas le cas,
/// l'application l'affiche « en cours d'envoi » ou « non transmise ».
library;

enum SosKind {
  breakdown('breakdown'),
  accident('accident'),
  assistance('assistance'),
  delay('delay');

  const SosKind(this.dbValue);

  final String dbValue;

  static SosKind? tryParse(String? value) {
    for (final k in values) {
      if (k.dbValue == value) return k;
    }
    return null;
  }
}

enum SosStatus {
  active('active'),
  resolved('resolved'),
  cancelled('cancelled');

  const SosStatus(this.dbValue);

  final String dbValue;

  static SosStatus parse(String? value) =>
      values.firstWhere((s) => s.dbValue == value, orElse: () => active);
}

class SosAlert {
  const SosAlert({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.clientRef,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.message,
    this.lat,
    this.lng,
    this.accuracyM,
    this.positionRecordedAt,
    this.positionSource,
    this.closedAt,
    this.closedBy,
    this.closeNote,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? v) =>
        v == null ? null : DateTime.parse(v as String).toUtc();
    double? number(Object? v) => (v as num?)?.toDouble();
    return SosAlert(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      userId: json['user_id'] as String,
      clientRef: json['client_ref'] as String,
      kind: SosKind.tryParse(json['kind'] as String?) ?? SosKind.assistance,
      status: SosStatus.parse(json['status'] as String?),
      createdAt: date(json['created_at'])!,
      message: json['message'] as String?,
      lat: number(json['lat']),
      lng: number(json['lng']),
      accuracyM: number(json['accuracy_m']),
      positionRecordedAt: date(json['position_recorded_at']),
      positionSource: json['position_source'] as String?,
      closedAt: date(json['closed_at']),
      closedBy: json['closed_by'] as String?,
      closeNote: json['close_note'] as String?,
    );
  }

  final String id;
  final String rideId;
  final String userId;
  final String clientRef;
  final SosKind kind;
  final SosStatus status;
  final DateTime createdAt;
  final String? message;
  final double? lat;
  final double? lng;
  final double? accuracyM;
  final DateTime? positionRecordedAt;

  /// `device` (GPS au moment de l'alerte) ou `convoy` (dernière position
  /// partagée en mode Convoi).
  final String? positionSource;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closeNote;

  bool get isActive => status == SosStatus.active;
  bool get hasPosition => lat != null && lng != null;
}

class SosAck {
  const SosAck({
    required this.alertId,
    required this.userId,
    required this.ackedAt,
  });

  factory SosAck.fromJson(Map<String, dynamic> json) => SosAck(
    alertId: json['alert_id'] as String,
    userId: json['user_id'] as String,
    ackedAt: DateTime.parse(json['acked_at'] as String).toUtc(),
  );

  final String alertId;
  final String userId;
  final DateTime ackedAt;
}

/// État de transmission d'une alerte que J'envoie.
enum SosDelivery { sending, sent, failed }

class OutgoingSos {
  const OutgoingSos({
    required this.clientRef,
    required this.rideId,
    required this.kind,
    required this.delivery,
    this.message,
    this.alert,
    this.error,
  });

  final String clientRef;
  final String rideId;
  final SosKind kind;
  final String? message;
  final SosDelivery delivery;

  /// Alerte enregistrée par le serveur : non nulle SEULEMENT si transmise.
  final SosAlert? alert;
  final Object? error;

  OutgoingSos copyWith({
    SosDelivery? delivery,
    SosAlert? alert,
    Object? error,
  }) => OutgoingSos(
    clientRef: clientRef,
    rideId: rideId,
    kind: kind,
    message: message,
    delivery: delivery ?? this.delivery,
    alert: alert ?? this.alert,
    error: error,
  );
}
