import 'package:intl/intl.dart';
// Jeu complet : les jeux réduits (latest, latest_10y) omettent les alias
// IANA de la RDC (Africa/Kinshasa, Africa/Lubumbashi).
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Fuseaux horaires proposés à la création d'une balade. La RDC en compte
/// deux, sans heure d'été.
enum RideTimeZone {
  kinshasa('Africa/Kinshasa'),
  lubumbashi('Africa/Lubumbashi');

  const RideTimeZone(this.id);

  final String id;

  static RideTimeZone? tryParse(String id) {
    for (final zone in values) {
      if (zone.id == id) return zone;
    }
    return null;
  }
}

/// Conversions entre l'heure locale d'une balade et l'UTC.
abstract final class RideTime {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  static tz.Location _location(String zoneId) {
    ensureInitialized();
    return tz.getLocation(zoneId);
  }

  /// Instant UTC correspondant à une date/heure saisie dans [zoneId].
  static DateTime toUtc({
    required DateTime localDate,
    required int hour,
    required int minute,
    required String zoneId,
  }) {
    final zoned = tz.TZDateTime(
      _location(zoneId),
      localDate.year,
      localDate.month,
      localDate.day,
      hour,
      minute,
    );
    return zoned.toUtc();
  }

  /// Date/heure murale de [instant] dans [zoneId].
  static DateTime inZone(DateTime instant, String zoneId) {
    final zoned = tz.TZDateTime.from(instant.toUtc(), _location(zoneId));
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
    );
  }

  /// Ex. « samedi 14 novembre 2026 ».
  static String formatDate(DateTime instant, String zoneId) =>
      DateFormat('EEEE d MMMM y', 'fr').format(inZone(instant, zoneId));

  /// Ex. « sam. 14 nov. ».
  static String formatShortDate(DateTime instant, String zoneId) =>
      DateFormat('EEE d MMM', 'fr').format(inZone(instant, zoneId));

  /// Ex. « 08:30 ».
  static String formatTime(DateTime instant, String zoneId) =>
      DateFormat('HH:mm', 'fr').format(inZone(instant, zoneId));
}
