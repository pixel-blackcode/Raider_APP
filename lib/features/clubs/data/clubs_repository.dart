import '../domain/club.dart';
import '../domain/club_draft.dart';

/// Accès aux clubs. Toutes les vérifications d'autorisation sont faites côté
/// serveur ; une action refusée lève une `AppException` (`not_allowed`...).
abstract interface class ClubsRepository {
  /// Clubs découvrables (publics et privés référencés), filtrés par nom ou
  /// ville.
  Future<List<Club>> discoverClubs({String query = ''});

  Future<List<ClubMembership>> myClubs(String userId);

  /// `null` si le club n'existe pas ou n'est pas visible.
  Future<Club?> getClub(String clubId);

  Future<ClubRole?> roleOf(String clubId, String userId);

  /// Liste vide si elle n'est pas visible (club privé dont on n'est pas
  /// membre).
  Future<List<ClubMember>> members(String clubId);

  Future<Club> createClub(ClubDraft draft);

  Future<void> updateClub(String clubId, ClubDraft draft);

  Future<void> deleteClub(String clubId);

  /// Enregistre (ou retire avec `null`) le logo ou la couverture.
  Future<void> setClubImage(String clubId, ClubImageKind kind, String? path);

  Future<JoinOutcome> joinClub(String clubId, {String? message});

  Future<void> leaveClub(String clubId);

  /// Demande d'adhésion en attente de l'utilisateur pour ce club.
  Future<ClubJoinRequest?> myPendingRequest(String clubId, String userId);

  Future<void> cancelJoinRequest(String requestId);

  /// Demandes en attente (visibles par owner/admin uniquement).
  Future<List<ClubJoinRequest>> pendingRequests(String clubId);

  Future<void> decideJoinRequest(String requestId, {required bool approve});

  Future<void> invite(String clubId, String inviteeId);

  Future<List<ClubInvitation>> myInvitations(String userId);

  Future<void> respondToInvitation(String invitationId, {required bool accept});

  Future<void> setMemberRole(String clubId, String userId, ClubRole role);

  Future<void> removeMember(String clubId, String userId);

  Future<void> transferOwnership(String clubId, String newOwnerId);

  /// Dernière demande de vérification (owner/admin uniquement).
  Future<ClubVerificationRequest?> latestVerificationRequest(String clubId);

  Future<void> requestVerification(String clubId, {String? message});
}
