import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/garage.dart';

extension MaintenanceKindLabels on MaintenanceKind {
  String label(AppLocalizations l10n) => switch (this) {
    MaintenanceKind.oil => l10n.garageKindOil,
    MaintenanceKind.tires => l10n.garageKindTires,
    MaintenanceKind.brakes => l10n.garageKindBrakes,
    MaintenanceKind.chain => l10n.garageKindChain,
    MaintenanceKind.service => l10n.garageKindService,
    MaintenanceKind.battery => l10n.garageKindBattery,
    MaintenanceKind.insurance => l10n.garageKindInsurance,
    MaintenanceKind.inspection => l10n.garageKindInspection,
    MaintenanceKind.other => l10n.garageKindOther,
  };

  IconData get icon => switch (this) {
    MaintenanceKind.oil => Icons.water_drop_outlined,
    MaintenanceKind.tires => Icons.trip_origin,
    MaintenanceKind.brakes => Icons.album_outlined,
    MaintenanceKind.chain => Icons.link,
    MaintenanceKind.service => Icons.build_outlined,
    MaintenanceKind.battery => Icons.battery_charging_full,
    MaintenanceKind.insurance => Icons.shield_outlined,
    MaintenanceKind.inspection => Icons.fact_check_outlined,
    MaintenanceKind.other => Icons.more_horiz,
  };
}

/// « 11 700 km ».
String formatKm(int km) {
  final s = km.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b km';
}

/// « 45 $ » / « 180 000 FC ».
String formatCost(double cost, GarageCurrency c) {
  final whole = cost == cost.roundToDouble();
  final n = whole ? cost.toStringAsFixed(0) : cost.toStringAsFixed(2);
  final parts = n.split('.');
  final s = parts.first;
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  final amount = parts.length > 1 ? '$b,${parts[1]}' : '$b';
  return c == GarageCurrency.cdf ? '$amount FC' : '$amount \$';
}

/// Texte court d'échéance d'un rappel.
String reminderDue(
  AppLocalizations l10n,
  MaintenanceReminder r,
  int odometerKm,
  DateTime today,
) {
  final parts = <String>[];
  final k = r.kmLeft(odometerKm);
  final d = r.daysLeft(today);
  if (k != null) {
    parts.add(k <= 0 ? l10n.garageKmOverdue : l10n.garageKmLeft(formatKm(k)));
  }
  if (d != null) {
    parts.add(d < 0 ? l10n.garageDaysOverdue : l10n.garageDaysLeft(d));
  }
  return parts.join(' · ');
}
