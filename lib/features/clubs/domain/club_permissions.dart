import 'club.dart';

/// Permissions d'un membre, utilisées UNIQUEMENT pour adapter l'interface.
///
/// L'autorité reste le serveur (RLS + fonctions SQL) : ces règles en sont le
/// miroir, afin de ne pas proposer d'actions vouées à l'échec.
class ClubPermissions {
  const ClubPermissions(this.role);

  /// Rôle de l'utilisateur dans le club ; `null` s'il n'est pas membre.
  final ClubRole? role;

  int get _rank => role?.rank ?? 0;

  bool get isMember => role != null;

  /// Description, règlement, ville, nom.
  bool get canEditDetails => _rank >= ClubRole.admin.rank;

  /// Visibilité, référencement, mode d'adhésion.
  bool get canChangeSettings => role == ClubRole.owner;

  bool get canInvite => _rank >= ClubRole.admin.rank;

  bool get canReviewRequests => _rank >= ClubRole.admin.rank;

  bool get canRequestVerification => role == ClubRole.owner;

  bool get canDeleteClub => role == ClubRole.owner;

  bool get canLeave => isMember && role != ClubRole.owner;

  /// Retrait : au moins modérateur et rang strictement supérieur.
  bool canRemove(ClubMember target) =>
      _rank >= ClubRole.moderator.rank && _rank > target.role.rank;

  /// Rôles qu'on peut attribuer à [target] (hors propriété).
  List<ClubRole> assignableRoles(ClubMember target) {
    if (_rank <= target.role.rank) return const [];
    return [
      for (final r in [ClubRole.admin, ClubRole.moderator, ClubRole.member])
        if (r.rank < _rank && r != target.role) r,
    ];
  }
}
