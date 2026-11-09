import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/backend/backend_initializer.dart';
import 'package:rider_group/core/backend/backend_status.dart';
import 'package:rider_group/core/config/app_config.dart';

void main() {
  final validConfig = AppConfig.fromMap(const {
    'APP_ENV': 'dev',
    'SUPABASE_URL': 'https://abcd.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
  });

  test('ne tente aucune initialisation sans configuration', () async {
    var called = false;
    final status = await initializeBackend(
      AppConfig.fromMap(const {}),
      initializer: ({required url, required key}) async => called = true,
    );

    expect(called, isFalse);
    expect(status, isA<BackendNotConfigured>());
    expect(status.isReady, isFalse);
    expect((status as BackendNotConfigured).issues, isNotEmpty);
  });

  test('transmet URL et clé publishable puis signale Ready', () async {
    String? receivedUrl;
    String? receivedKey;
    final status = await initializeBackend(
      validConfig,
      initializer: ({required url, required key}) async {
        receivedUrl = url;
        receivedKey = key;
      },
    );

    expect(receivedUrl, 'https://abcd.supabase.co');
    expect(receivedKey, 'sb_publishable_test');
    expect(status, isA<BackendReady>());
    expect(status.isReady, isTrue);
  });

  test('une erreur d\'initialisation donne Failed, sans exception', () async {
    final status = await initializeBackend(
      validConfig,
      initializer: ({required url, required key}) async =>
          throw StateError('boom'),
    );

    expect(status, isA<BackendFailed>());
    expect(status.isReady, isFalse);
  });
}
