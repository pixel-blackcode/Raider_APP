/// Garage (Mission 10, D-69) : motos, entretiens, rappels.
enum MaintenanceKind {
  oil,
  tires,
  brakes,
  chain,
  service,
  battery,
  insurance,
  inspection,
  other;

  static MaintenanceKind parse(String? v) => values.firstWhere(
    (k) => k.name == v,
    orElse: () => MaintenanceKind.other,
  );

  /// Types proposés pour un entretien (assurance et contrôle : rappels seuls).
  static const forRecords = [
    oil,
    tires,
    brakes,
    chain,
    service,
    battery,
    other,
  ];
}

enum GarageCurrency { usd, cdf }

class Motorcycle {
  const Motorcycle({
    required this.id,
    required this.brand,
    required this.model,
    this.year,
    this.cc,
    this.color,
    this.plate,
    this.odometerKm = 0,
    this.isPrimary = false,
    this.showInSos = true,
    this.photoPath,
  });

  factory Motorcycle.fromJson(Map<String, dynamic> j) => Motorcycle(
    id: j['id'] as String,
    brand: j['brand'] as String,
    model: j['model'] as String,
    year: (j['year'] as num?)?.toInt(),
    cc: (j['cc'] as num?)?.toInt(),
    color: j['color'] as String?,
    plate: j['plate'] as String?,
    odometerKm: (j['odometer_km'] as num?)?.toInt() ?? 0,
    isPrimary: (j['is_primary'] as bool?) ?? false,
    showInSos: (j['show_in_sos'] as bool?) ?? true,
    photoPath: j['photo_path'] as String?,
  );

  final String id;
  final String brand;
  final String model;
  final int? year;
  final int? cc;
  final String? color;
  final String? plate;
  final int odometerKm;
  final bool isPrimary;
  final bool showInSos;
  final String? photoPath;

  String get name => '$brand $model';
}

class MotorcycleDraft {
  const MotorcycleDraft({
    required this.brand,
    required this.model,
    this.year,
    this.cc,
    this.color,
    this.plate,
    this.odometerKm = 0,
    this.isPrimary = false,
    this.showInSos = true,
  });

  final String brand;
  final String model;
  final int? year;
  final int? cc;
  final String? color;
  final String? plate;
  final int odometerKm;
  final bool isPrimary;
  final bool showInSos;
}

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.motoId,
    required this.kind,
    required this.doneOn,
    this.odometerKm,
    this.cost,
    this.currency = GarageCurrency.usd,
    this.garage,
    this.note,
    this.invoicePath,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) =>
      MaintenanceRecord(
        id: j['id'] as String,
        motoId: j['moto_id'] as String,
        kind: MaintenanceKind.parse(j['kind'] as String?),
        doneOn: DateTime.parse(j['done_on'] as String),
        odometerKm: (j['odometer_km'] as num?)?.toInt(),
        cost: (j['cost'] as num?)?.toDouble(),
        currency: j['currency'] == 'CDF'
            ? GarageCurrency.cdf
            : GarageCurrency.usd,
        garage: j['garage'] as String?,
        note: j['note'] as String?,
        invoicePath: j['invoice_path'] as String?,
      );

  final String id;
  final String motoId;
  final MaintenanceKind kind;
  final DateTime doneOn;
  final int? odometerKm;
  final double? cost;
  final GarageCurrency currency;
  final String? garage;
  final String? note;
  final String? invoicePath;
}

class MaintenanceDraft {
  const MaintenanceDraft({
    required this.kind,
    required this.doneOn,
    this.odometerKm,
    this.cost,
    this.currency = GarageCurrency.usd,
    this.garage,
    this.note,
    this.invoicePath,
    this.remindNext = false,
  });

  final MaintenanceKind kind;
  final DateTime doneOn;
  final int? odometerKm;
  final double? cost;
  final GarageCurrency currency;
  final String? garage;
  final String? note;
  final String? invoicePath;
  final bool remindNext;
}

class MaintenanceReminder {
  const MaintenanceReminder({
    required this.id,
    required this.motoId,
    required this.kind,
    this.label,
    this.dueDate,
    this.dueKm,
    this.intervalKm,
    this.intervalMonths,
  });

  factory MaintenanceReminder.fromJson(Map<String, dynamic> j) =>
      MaintenanceReminder(
        id: j['id'] as String,
        motoId: j['moto_id'] as String,
        kind: MaintenanceKind.parse(j['kind'] as String?),
        label: j['label'] as String?,
        dueDate: j['due_date'] == null
            ? null
            : DateTime.parse(j['due_date'] as String),
        dueKm: (j['due_km'] as num?)?.toInt(),
        intervalKm: (j['interval_km'] as num?)?.toInt(),
        intervalMonths: (j['interval_months'] as num?)?.toInt(),
      );

  final String id;
  final String motoId;
  final MaintenanceKind kind;
  final String? label;
  final DateTime? dueDate;
  final int? dueKm;
  final int? intervalKm;
  final int? intervalMonths;

  /// Jours restants (négatif : en retard), null sans date.
  int? daysLeft(DateTime today) => dueDate == null
      ? null
      : DateTime(
          dueDate!.year,
          dueDate!.month,
          dueDate!.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;

  int? kmLeft(int odometerKm) => dueKm == null ? null : dueKm! - odometerKm;

  /// À traiter : dans 7 jours ou moins, ou à 300 km ou moins.
  bool isDue(DateTime today, int odometerKm) {
    final d = daysLeft(today);
    final k = kmLeft(odometerKm);
    return (d != null && d <= 7) || (k != null && k <= 300);
  }
}

/// La moto d'un motard en alerte SOS (visible des participants, D-69).
class SosMotorcycle {
  const SosMotorcycle({
    required this.brand,
    required this.model,
    this.color,
    this.plate,
    this.photoPath,
  });

  factory SosMotorcycle.fromJson(Map<String, dynamic> j) => SosMotorcycle(
    brand: j['brand'] as String,
    model: j['model'] as String,
    color: j['color'] as String?,
    plate: j['plate'] as String?,
    photoPath: j['photo_path'] as String?,
  );

  final String brand;
  final String model;
  final String? color;
  final String? plate;
  final String? photoPath;
}
