import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/backend/backend_initializer.dart';
import 'core/backend/backend_providers.dart';
import 'core/config/app_config.dart';
import 'core/preferences/preferences_providers.dart';

/// Prépare les dépendances puis lance l'application.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final backendStatus = await initializeBackend(config);
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        backendStatusProvider.overrideWithValue(backendStatus),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const RiderGroupApp(),
    ),
  );
}
