import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/config/app_config.dart';
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

  /// Envoie un lien de réinitialisation. Ne révèle jamais si l'adresse
  /// correspond à un compte.
  Future<void> sendPasswordReset(String email);

  /// Change le mot de passe de l'utilisateur connecté (y compris après un
  /// lien de réinitialisation).
  Future<void> updatePassword(String newPassword);

  /// Émet un événement quand l'utilisateur ouvre un lien de
  /// réinitialisation de mot de passe.
  Stream<void> passwordRecoveryEvents();

  /// Supprime définitivement le compte (fonction serveur
  /// `delete_my_account`) puis ferme la session locale.
  Future<void> deleteAccount();
}

/// Implémentation Supabase Auth. La session est persistée et rafraîchie
/// automatiquement par `supabase_flutter` (stockage sécurisé de la plateforme
/// non garanti : voir docs/SECURITY.md).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final supa.SupabaseClient _client;

  supa.GoTrueClient get _auth => _client.auth;

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
        emailRedirectTo: AppConfig.authRedirectUri,
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

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUri,
      );
    } catch (error) {
      final failure = AppException.from(error);
      // Seuls les problèmes techniques sont remontés (pas d'énumération).
      if (failure.code == AppException.network ||
          failure.code == AppException.rateLimited) {
        throw failure;
      }
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(supa.UserAttributes(password: newPassword));
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Stream<void> passwordRecoveryEvents() => _auth.onAuthStateChange
      .where((state) => state.event == supa.AuthChangeEvent.passwordRecovery)
      .map((_) {});

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc<void>('delete_my_account');
    } catch (error) {
      throw AppException.from(error);
    }
    // Le compte n'existe plus : seule la session locale est à effacer.
    await _auth.signOut(scope: supa.SignOutScope.local);
  }
}
