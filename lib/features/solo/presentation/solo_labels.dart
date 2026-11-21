import '../../../l10n/generated/app_localizations.dart';
import '../domain/solo.dart';

/// Heure locale « 22:30 ».
String soloTime(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// « 15 min », « 1 h », « 1 h 30 ».
String soloDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// État d'un trajet vu par un proche.
String soloStatusText(AppLocalizations l10n, SoloTrip t, DateTime now) =>
    switch (t.status) {
      SoloTripStatus.arrived => l10n.soloStatusArrived(
        soloTime(t.endedAt ?? now),
      ),
      SoloTripStatus.cancelled => l10n.soloStatusCancelled,
      SoloTripStatus.expired => l10n.soloStatusExpired,
      SoloTripStatus.active =>
        t.isLate(now)
            ? l10n.soloStatusLate(soloTime(t.expectedAt))
            : l10n.soloStatusOnTheWay(soloTime(t.expectedAt)),
    };
