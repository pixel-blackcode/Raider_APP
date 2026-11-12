import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/clubs/data/supabase_clubs_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('codes métier renvoyés par les fonctions SQL', () {
    expect(
      AppException.from(
        const PostgrestException(message: 'invitation_required', code: 'P0001'),
      ).code,
      'invitation_required',
    );
  });

  test('un message serveur inconnu n\'est pas relayé tel quel', () {
    expect(
      AppException.from(
        const PostgrestException(message: 'texte interne', code: 'P0001'),
      ).code,
      AppException.unknown,
    );
  });

  test('refus de privilège PostgreSQL → not_allowed', () {
    expect(
      AppException.from(
        const PostgrestException(message: 'permission denied', code: '42501'),
      ).code,
      AppException.notAllowed,
    );
  });

  test('erreurs Supabase Auth', () {
    expect(
      AppException.from(const AuthException('x', code: 'invalid_credentials'))
          .code,
      AppException.invalidCredentials,
    );
    expect(
      AppException.from(const AuthException('x', code: 'email_exists')).code,
      AppException.userAlreadyExists,
    );
    // Configuration Supabase : fournisseur Email désactivé.
    expect(
      AppException.from(
        const AuthException('x', code: 'email_provider_disabled'),
      ).code,
      AppException.signupDisabled,
    );
  });

  test('erreurs réseau', () {
    expect(
      AppException.from(const SocketException('offline')).code,
      AppException.network,
    );
  });

  test('la recherche neutralise la syntaxe de filtre PostgREST', () {
    expect(
      SupabaseClubsRepository.sanitizeQuery('kin,name.eq.x)(*%'),
      'kin name eq x',
    );
  });
}
