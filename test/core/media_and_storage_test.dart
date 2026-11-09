import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/backend/secure_session_storage.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/core/media/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PickedImage.validateFor (miroir des limites des buckets)', () {
    PickedImage image(String ext, int size) =>
        PickedImage(bytes: Uint8List(size), extension: ext);

    test('formats acceptés', () {
      for (final ext in ['jpg', 'JPEG', 'png', 'webp']) {
        expect(
          () => image(ext, 10).validateFor(MediaBucket.avatars),
          returnsNormally,
        );
      }
    });

    test('format refusé', () {
      expect(
        () => image('gif', 10).validateFor(MediaBucket.avatars),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppException.unsupportedImage,
          ),
        ),
      );
      expect(image('heic', 10).contentType, isNull);
    });

    test('taille limitée par bucket', () {
      expect(
        () =>
            image('jpg', 2 * 1024 * 1024 + 1).validateFor(MediaBucket.avatars),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppException.imageTooLarge,
          ),
        ),
      );
      expect(
        () => image(
          'jpg',
          2 * 1024 * 1024 + 1,
        ).validateFor(MediaBucket.clubMedia),
        returnsNormally,
      );
    });
  });

  group('Stockage chiffré de la session', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('enregistre, relit et efface la session', () async {
      const storage = SecureSessionStorage(FlutterSecureStorage());
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('{"access_token":"x"}');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"access_token":"x"}');
      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
    });

    test('vérificateur PKCE', () async {
      const pkce = SecurePkceStorage(FlutterSecureStorage());
      await pkce.setItem(key: 'verifier', value: 'abc');
      expect(await pkce.getItem(key: 'verifier'), 'abc');
      await pkce.removeItem(key: 'verifier');
      expect(await pkce.getItem(key: 'verifier'), isNull);
    });

    test(
      'réinstallation : les secrets résiduels sont effacés une seule fois',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          SecureSessionStorage.sessionKey: 'ancienne-session',
        });
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        const secure = FlutterSecureStorage();

        await clearSecretsOnFreshInstall(prefs, secure);
        expect(await secure.read(key: SecureSessionStorage.sessionKey), isNull);

        await secure.write(
          key: SecureSessionStorage.sessionKey,
          value: 'nouvelle',
        );
        await clearSecretsOnFreshInstall(prefs, secure);
        expect(
          await secure.read(key: SecureSessionStorage.sessionKey),
          'nouvelle',
        );
      },
    );
  });
}
