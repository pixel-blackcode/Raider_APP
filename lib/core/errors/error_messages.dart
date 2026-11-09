import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_exception.dart';

/// Message lisible (en français) pour n'importe quelle erreur.
String describeError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  final code = AppException.from(error).code;
  return switch (code) {
    'network' => l10n.errorNetwork,
    'backend_unavailable' => l10n.errorBackendUnavailable,
    'not_authenticated' => l10n.errorNotAuthenticated,
    'not_allowed' => l10n.errorNotAllowed,
    'invalid_input' => l10n.errorInvalidInput,
    'already_exists' => l10n.errorAlreadyExists,
    'invalid_credentials' => l10n.errorInvalidCredentials,
    'email_not_confirmed' => l10n.errorEmailNotConfirmed,
    'user_already_exists' => l10n.errorUserAlreadyExists,
    'weak_password' => l10n.errorWeakPassword,
    'rate_limited' => l10n.errorRateLimited,
    'club_not_found' => l10n.errorClubNotFound,
    'club_name_taken' => l10n.errorClubNameTaken,
    'club_suspended' => l10n.errorClubSuspended,
    'already_member' => l10n.errorAlreadyMember,
    'not_member' => l10n.errorNotMember,
    'invitation_required' => l10n.errorInvitationRequired,
    'request_not_found' => l10n.errorRequestNotFound,
    'invitation_not_found' => l10n.errorInvitationNotFound,
    'owner_cannot_leave' => l10n.errorOwnerCannotLeave,
    'use_transfer_ownership' => l10n.errorUseTransferOwnership,
    'user_not_found' => l10n.errorUserNotFound,
    'already_verified' => l10n.errorAlreadyVerified,
    'verification_pending' => l10n.errorVerificationPending,
    _ => l10n.errorUnknown,
  };
}
