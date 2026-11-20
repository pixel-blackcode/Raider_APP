import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/app.dart';
import 'package:rider_group/core/backend/backend_providers.dart';
import 'package:rider_group/core/backend/backend_status.dart';
import 'package:rider_group/core/config/app_config.dart';
import 'package:rider_group/core/preferences/preferences_providers.dart';
import 'package:rider_group/core/push/push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration sans backend (aucun identifiant Supabase).
final unconfiguredConfig = AppConfig.fromMap(const {});

/// Lance l'application complète avec des dépendances contrôlées.
///
/// Par défaut, le backend est « non configuré » : aucun appel réseau réel.
Future<ProviderContainer> pumpRiderGroupApp(
  WidgetTester tester, {
  BackendStatus? backendStatus,
  AppConfig? config,
  Map<String, Object> preferences = const {},
  List<Override> overrides = const [],
}) async {
  // Écran haut : les formulaires tiennent sans défilement dans les tests.
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  final effectiveConfig = config ?? unconfiguredConfig;

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      // Pas de Firebase en test de widget.
      pushMessagingProvider.overrideWithValue(FakePushMessaging()),
      ...overrides,
      appConfigProvider.overrideWithValue(effectiveConfig),
      backendStatusProvider.overrideWithValue(
        backendStatus ?? BackendNotConfigured(effectiveConfig.issues),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RiderGroupApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Notifications push factices : Firebase absent, jeton fixe si demandé.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.available = false});

  final bool available;
  int permissionRequests = 0;

  @override
  Future<bool> init() async => available;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return available;
  }

  @override
  Future<String?> token() async =>
      available ? 'jeton-de-test-0123456789' : null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<String> get onOpenRoute => const Stream.empty();

  @override
  Future<String?> initialRoute() async => null;

  @override
  String get platform => 'android';
}
