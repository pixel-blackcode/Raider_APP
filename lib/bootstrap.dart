import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/backend/backend_initializer.dart';
import 'core/backend/backend_providers.dart';
import 'core/backend/secure_session_storage.dart';
import 'core/config/app_config.dart';
import 'core/preferences/preferences_providers.dart';
import 'features/rides/domain/ride_time.dart';

/// Prépare les dépendances puis lance l'application.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  RideTime.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final preferences = await SharedPreferences.getInstance();
  await clearSecretsOnFreshInstall(preferences, const FlutterSecureStorage());
  final backendStatus = await initializeBackend(config);

  runApp(
    ProviderScope(
      // Pas de nouvelle tentative automatique : les écrans proposent
      // « Réessayer » et affichent l'erreur réelle.
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        backendStatusProvider.overrideWithValue(backendStatus),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const RiderGroupApp(),
    ),
  );
}
