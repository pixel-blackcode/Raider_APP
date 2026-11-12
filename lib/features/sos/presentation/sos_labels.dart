import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/sos.dart';

extension SosKindUi on SosKind {
  String label(AppLocalizations l10n) => switch (this) {
    SosKind.breakdown => l10n.sosKindBreakdown,
    SosKind.accident => l10n.sosKindAccident,
    SosKind.assistance => l10n.sosKindAssistance,
    SosKind.delay => l10n.sosKindDelay,
  };

  IconData get icon => switch (this) {
    SosKind.breakdown => Icons.build_circle_outlined,
    SosKind.accident => Icons.car_crash_outlined,
    SosKind.assistance => Icons.front_hand_outlined,
    SosKind.delay => Icons.schedule,
  };
}

/// Heure locale HH:MM.
String sosTime(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
