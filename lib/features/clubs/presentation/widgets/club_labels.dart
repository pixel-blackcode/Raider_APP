import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/club.dart';

/// Libellés localisés des énumérations du module clubs.
extension ClubVisibilityLabel on ClubVisibility {
  String label(AppLocalizations l10n) => switch (this) {
    ClubVisibility.public => l10n.clubVisibilityPublic,
    ClubVisibility.private => l10n.clubVisibilityPrivate,
  };
}

extension ClubJoinPolicyLabel on ClubJoinPolicy {
  String label(AppLocalizations l10n) => switch (this) {
    ClubJoinPolicy.open => l10n.clubJoinOpen,
    ClubJoinPolicy.approval => l10n.clubJoinApproval,
    ClubJoinPolicy.inviteOnly => l10n.clubJoinInviteOnly,
  };
}

extension ClubRoleLabel on ClubRole {
  String label(AppLocalizations l10n) => switch (this) {
    ClubRole.owner => l10n.clubRoleOwner,
    ClubRole.admin => l10n.clubRoleAdmin,
    ClubRole.moderator => l10n.clubRoleModerator,
    ClubRole.member => l10n.clubRoleMember,
  };
}
