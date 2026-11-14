import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/preferences/preferences_providers.dart';

/// Numéro d'appel d'urgence proposé sur l'écran SOS (D-40).
///
/// 112 par défaut, modifiable dans les Paramètres. Sa disponibilité dépend du
/// pays et de l'opérateur : l'application ne la garantit pas.
class EmergencyNumberController extends Notifier<String> {
  static const storageKey = 'sos.emergency_number';
  static const defaultNumber = '112';
  static final _valid = RegExp(r'^\+?[0-9]{2,15}$');

  static bool isValid(String value) => _valid.hasMatch(value);

  @override
  String build() =>
      ref.read(sharedPreferencesProvider).getString(storageKey) ??
      defaultNumber;

  /// Retourne false si le numéro est invalide (rien n'est enregistré).
  Future<bool> set(String value) async {
    final cleaned = value.replaceAll(RegExp(r'[\s.-]'), '');
    if (!isValid(cleaned)) return false;
    state = cleaned;
    await ref.read(sharedPreferencesProvider).setString(storageKey, cleaned);
    return true;
  }
}

final emergencyNumberProvider =
    NotifierProvider<EmergencyNumberController, String>(
      EmergencyNumberController.new,
    );

/// Actions hors de l'application (téléphone, carte), remplaçables en test.
abstract interface class ExternalActions {
  /// Ouvre le composeur téléphonique avec le numéro.
  Future<bool> dial(String number);

  /// Ouvre une position dans une carte (OpenStreetMap, navigateur ou app).
  Future<bool> openMap(double lat, double lng);

  /// Ouvre une conversation WhatsApp (outil de l'équipe Rider Group).
  Future<bool> openWhatsApp(String phone);
}

class UrlLauncherActions implements ExternalActions {
  @override
  Future<bool> dial(String number) =>
      launchUrl(Uri(scheme: 'tel', path: number));

  @override
  Future<bool> openMap(double lat, double lng) => launchUrl(
    Uri.https('www.openstreetmap.org', '/', {
      'mlat': '$lat',
      'mlon': '$lng',
    }).replace(fragment: 'map=17/$lat/$lng'),
    mode: LaunchMode.externalApplication,
  );

  @override
  Future<bool> openWhatsApp(String phone) => launchUrl(
    Uri.https('wa.me', '/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'),
    mode: LaunchMode.externalApplication,
  );
}

final externalActionsProvider = Provider<ExternalActions>(
  (ref) => UrlLauncherActions(),
);
