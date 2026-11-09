import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/features/auth/domain/auth_validators.dart';

void main() {
  test('e-mail', () {
    expect(AuthValidators.isValidEmail('motard@exemple.cd'), isTrue);
    expect(AuthValidators.isValidEmail('  motard@exemple.cd '), isTrue);
    expect(AuthValidators.isValidEmail('motard@exemple'), isFalse);
    expect(AuthValidators.isValidEmail('motard exemple.cd'), isFalse);
  });

  test('mot de passe : 8 caractères, une lettre et un chiffre', () {
    expect(AuthValidators.isValidPassword('moto2026'), isTrue);
    expect(AuthValidators.isValidPassword('moto26'), isFalse);
    expect(AuthValidators.isValidPassword('motomoto'), isFalse);
    expect(AuthValidators.isValidPassword('12345678'), isFalse);
  });

  test('pseudonyme : miroir de la contrainte SQL', () {
    expect(AuthValidators.isValidUsername('kin_rider_243'), isTrue);
    expect(AuthValidators.isValidUsername('ab'), isFalse);
    expect(AuthValidators.isValidUsername('Majuscule'), isFalse);
    expect(AuthValidators.isValidUsername('avec espace'), isFalse);
    expect(AuthValidators.isValidUsername('a' * 31), isFalse);
    expect(AuthValidators.normalizeUsername('  Kin_Rider '), 'kin_rider');
  });

  test('nom affiché : 1 à 60 caractères', () {
    expect(AuthValidators.isValidDisplayName('Joël'), isTrue);
    expect(AuthValidators.isValidDisplayName('   '), isFalse);
    expect(AuthValidators.isValidDisplayName('x' * 61), isFalse);
  });
}
