import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/config/app_config.dart';

String _fakeJwt(Map<String, Object> payload) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}.sig';
}

void main() {
  group('AppEnvironment.parse', () {
    test('reconnaît les codes et noms', () {
      expect(AppEnvironment.parse('dev'), AppEnvironment.development);
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.parse(' PROD '), AppEnvironment.production);
      expect(AppEnvironment.parse('production'), AppEnvironment.production);
    });

    test('retombe sur development pour une valeur inconnue', () {
      expect(AppEnvironment.parse('???'), AppEnvironment.development);
    });
  });

  group('AppConfig.issues', () {
    test('configuration vide : URL et clé manquantes', () {
      final config = AppConfig.fromMap(const {});
      expect(config.issues, [
        ConfigIssue.missingSupabaseUrl,
        ConfigIssue.missingSupabaseKey,
      ]);
      expect(config.isBackendConfigured, isFalse);
    });

    test('configuration valide', () {
      final config = AppConfig.fromMap(const {
        'APP_ENV': 'staging',
        'SUPABASE_URL': 'https://abcd.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
      });
      expect(config.issues, isEmpty);
      expect(config.isBackendConfigured, isTrue);
      expect(config.environment, AppEnvironment.staging);
    });

    test('URL invalide refusée', () {
      final config = AppConfig.fromMap(const {
        'SUPABASE_URL': 'pas une url',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
      });
      expect(config.issues, [ConfigIssue.invalidSupabaseUrl]);
    });

    test('HTTP refusé hors instance locale', () {
      final config = AppConfig.fromMap(const {
        'SUPABASE_URL': 'http://abcd.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
      });
      expect(config.issues, [ConfigIssue.insecureSupabaseUrl]);
    });

    test('HTTP toléré pour Supabase local (émulateur Android inclus)', () {
      for (final url in [
        'http://localhost:54321',
        'http://127.0.0.1:54321',
        'http://10.0.2.2:54321',
      ]) {
        final config = AppConfig.fromMap({
          'SUPABASE_URL': url,
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        });
        expect(config.issues, isEmpty, reason: url);
      }
    });

    test('clé secrète (sb_secret_) refusée côté client', () {
      final config = AppConfig.fromMap(const {
        'SUPABASE_URL': 'https://abcd.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_xxx',
      });
      expect(config.issues, [ConfigIssue.forbiddenSecretKey]);
    });

    test('ancienne clé JWT service_role refusée côté client', () {
      final config = AppConfig.fromMap({
        'SUPABASE_URL': 'https://abcd.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': _fakeJwt({'role': 'service_role'}),
      });
      expect(config.issues, [ConfigIssue.forbiddenSecretKey]);
    });

    test('ancienne clé JWT anon acceptée', () {
      final config = AppConfig.fromMap({
        'SUPABASE_URL': 'https://abcd.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': _fakeJwt({'role': 'anon'}),
      });
      expect(config.issues, isEmpty);
    });
  });
}
