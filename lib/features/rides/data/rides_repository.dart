import '../domain/ride.dart';
import '../domain/ride_draft.dart';

/// Accès aux balades. Les autorisations, le verrouillage, la capacité et les
/// transitions de statut sont vérifiés côté serveur ; un refus lève une
/// `AppException` (`ride_not_joinable`, `ride_full`...).
abstract interface class RidesRepository {
  /// Balades à venir ou en cours visibles par l'utilisateur.
  Future<List<Ride>> discoverRides({
    String query = '',
    RideDifficulty? difficulty,
  });

  /// Balades organisées ou rejointes (y compris brouillons et passées).
  Future<List<MyRide>> myRides(String userId);

  /// Balades à venir d'un club.
  Future<List<Ride>> clubRides(String clubId);

  /// `null` si la balade n'existe pas ou n'est pas visible.
  Future<Ride?> getRide(String rideId);

  /// Statut de participation de l'utilisateur (`null` : aucun lien).
  Future<ParticipantStatus?> myStatus(String rideId, String userId);

  /// Participants confirmés (liste vide si non visible).
  Future<List<RideParticipant>> participants(String rideId);

  /// Demandes en attente (gestionnaires uniquement).
  Future<List<RideParticipant>> pendingRequests(String rideId);

  Future<Ride> createRide(RideDraft draft, {required bool publish});

  Future<void> updateRide(String rideId, RideDraft draft);

  /// Enregistre (ou retire avec null) la photo de couverture ; retourne
  /// l'ancien chemin (à effacer).
  Future<String?> setCover(String rideId, String? path);

  Future<void> setStatus(String rideId, RideAction action, {String? reason});

  Future<void> deleteDraft(String rideId);

  Future<RideJoinOutcome> join(String rideId, {String? message});

  Future<void> cancelRequest(String rideId);

  Future<void> leave(String rideId);

  Future<void> decideRequest(
    String rideId,
    String userId, {
    required bool approve,
  });

  Future<void> removeParticipant(String rideId, String userId);

  Future<void> invite(String rideId, String inviteeId);

  Future<List<RideInvitation>> myInvitations(String userId);

  Future<void> respondToInvitation(String invitationId, {required bool accept});
}
