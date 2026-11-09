import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/app.dart';
import 'package:rider_group/core/backend/backend_providers.dart';
import 'package:rider_group/core/backend/backend_status.dart';
import 'package:rider_group/core/config/app_config.dart';
import 'package:rider_group/core/preferences/preferences_providers.dart';
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
