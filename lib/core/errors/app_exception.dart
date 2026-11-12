import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur applicative normalisée, indépendante du fournisseur backend.
///
/// [code] reprend les codes renvoyés par les fonctions serveur
/// (voir les migrations SQL) ou des codes génériques ([network],
/// [unknown]...). Le texte affiché est produit par `describeError`.
class AppException implements Exception {
  const AppException(this.code, [this.cause]);

  /// Convertit n'importe quelle erreur en [AppException].
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is AuthException) return AppException(_authCode(error), error);
    if (error is PostgrestException) {
      if (error.code == '42501') return AppException(notAllowed, error);
      if (error.code == 'P0001' && _serverCodes.contains(error.message)) {
        return AppException(error.message, error);
      }
      if (error.code == '23505') return AppException(alreadyExists, error);
      return AppException(unknown, error);
    }
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is ClientException) {
      return AppException(network, error);
    }
    return AppException(unknown, error);
  }

  final String code;
  final Object? cause;

  // Codes génériques.
  static const network = 'network';
  static const unknown = 'unknown';
  static const notAllowed = 'not_allowed';
  static const alreadyExists = 'already_exists';
  static const backendUnavailable = 'backend_unavailable';

  // Codes d'authentification.
  static const invalidCredentials = 'invalid_credentials';
  static const emailNotConfirmed = 'email_not_confirmed';
  static const userAlreadyExists = 'user_already_exists';
  static const weakPassword = 'weak_password';
  static const rateLimited = 'rate_limited';
  static const samePassword = 'same_password';
  static const signupDisabled = 'signup_disabled';

  // Codes des médias.
  static const unsupportedImage = 'unsupported_image';
  static const imageTooLarge = 'image_too_large';

  /// Codes métier levés par les fonctions serveur (migrations SQL).
  static const _serverCodes = {
    'not_authenticated',
    'not_allowed',
    'invalid_input',
    'club_not_found',
    'club_name_taken',
    'club_suspended',
    'already_member',
    'not_member',
    'invitation_required',
    'request_not_found',
    'invitation_not_found',
    'owner_cannot_leave',
    'use_transfer_ownership',
    'user_not_found',
    'already_verified',
    'verification_pending',
    'rate_limited',
    'invitations_disabled',
    'owns_clubs_with_members',
    'ride_not_found',
    'ride_not_editable',
    'ride_not_joinable',
    'ride_full',
    'invalid_transition',
    'already_participant',
    'not_participant',
    'removed_from_ride',
    'organizer_cannot_leave',
    'club_members_only',
    'start_in_past',
    'capacity_below_participants',
    'organizes_active_rides',
    'ride_not_in_progress',
    'sharing_disabled',
    'too_frequent',
    'alert_closed',
    'own_alert',
  };

  static String _authCode(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
        return invalidCredentials;
      case 'email_not_confirmed':
        return emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return userAlreadyExists;
      case 'weak_password':
        return weakPassword;
      case 'same_password':
        return samePassword;
      // Inscriptions désactivées dans la configuration Supabase.
      case 'email_provider_disabled':
      case 'signup_disabled':
        return signupDisabled;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return rateLimited;
    }
    if (error is AuthRetryableFetchException) return network;
    return unknown;
  }

  @override
  String toString() => 'AppException($code)';
}
