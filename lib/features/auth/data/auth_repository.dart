import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/errors/app_exception.dart';
import '../domain/auth_session.dart';

/// Accès aux comptes utilisateurs.
abstract interface class AuthRepository {
  AuthSession? get currentSession;

  /// Émet la session courante à chaque changement (connexion, déconnexion,
  /// expiration...).
  Stream<AuthSession?> sessionChanges();

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

/// Implémentation Supabase Auth. La session est persistée et rafraîchie
/// automatiquement par `supabase_flutter` (stockage sécurisé de la plateforme
/// non garanti : voir docs/SECURITY.md).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final supa.GoTrueClient _auth;

  static AuthSession? _map(supa.Session? session) {
    if (session == null) return null;
    return AuthSession(userId: session.user.id, email: session.user.email);
  }

  @override
  AuthSession? get currentSession => _map(_auth.currentSession);

  @override
  Stream<AuthSession?> sessionChanges() =>
      _auth.onAuthStateChange.map((state) => _map(state.session));

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        // Suggestions utilisées par le trigger de création du profil.
        data: {'display_name': displayName.trim(), 'username': username},
      );
      return response.session != null
          ? SignUpOutcome.signedIn
          : SignUpOutcome.confirmationRequired;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
