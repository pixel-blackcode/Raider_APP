import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/preferences/preferences_providers.dart';
import 'package:rider_group/core/theme/app_colors.dart';
import 'package:rider_group/core/theme/app_theme.dart';
import 'package:rider_group/core/theme/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AppTheme', () {
    test('thèmes clair et sombre en Material 3 avec RiderColors', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.light.extension<RiderColors>(), RiderColors.light);
      expect(AppTheme.dark.extension<RiderColors>(), RiderColors.dark);
    });

    test('RiderColors.lerp interpole aux bornes', () {
      expect(
        RiderColors.light.lerp(RiderColors.dark, 0).sos,
        RiderColors.light.sos,
      );
      expect(
        RiderColors.light.lerp(RiderColors.dark, 1).sos,
        RiderColors.dark.sos,
      );
    });
  });

  group('ThemeModeController', () {
    test('suit le système par défaut', () async {
      final container = await _container({});
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('restaure la préférence enregistrée', () async {
      final container = await _container({
        ThemeModeController.storageKey: 'dark',
      });
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('ignore une valeur enregistrée corrompue', () async {
      final container = await _container({
        ThemeModeController.storageKey: 'violet',
      });
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('persiste le nouveau mode', () async {
      final container = await _container({});
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString(ThemeModeController.storageKey), 'light');
    });
  });
}
