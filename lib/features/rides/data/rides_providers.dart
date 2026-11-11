import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../clubs/domain/club.dart';
import '../domain/ride.dart';
import 'rides_repository.dart';
import 'supabase_rides_repository.dart';

/// Dépôt des balades ; `null` si le backend n'est pas initialisé.
final ridesRepositoryProvider = Provider<RidesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseRidesRepository(client);
});

/// Critères de recherche de l'onglet « À venir ».
class RideSearch {
  const RideSearch({this.query = '', this.difficulty});

  final String query;
  final RideDifficulty? difficulty;
}

final rideSearchProvider = NotifierProvider<RideSearchController, RideSearch>(
  RideSearchController.new,
);

class RideSearchController extends Notifier<RideSearch> {
  @override
  RideSearch build() => const RideSearch();

  void setQuery(String query) =>
      state = RideSearch(query: query.trim(), difficulty: state.difficulty);

  void setDifficulty(RideDifficulty? difficulty) =>
      state = RideSearch(query: state.query, difficulty: difficulty);
}

final discoverRidesProvider = FutureProvider.autoDispose<List<Ride>>((
  ref,
) async {
  final repository = ref.watch(ridesRepositoryProvider);
  if (repository == null) return const [];
  final search = ref.watch(rideSearchProvider);
  return repository.discoverRides(
    query: search.query,
    difficulty: search.difficulty,
  );
});

final myRidesProvider = FutureProvider.autoDispose<List<MyRide>>((ref) async {
  final repository = ref.watch(ridesRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (repository == null || userId == null) return const [];
  return repository.myRides(userId);
});

final myRideInvitationsProvider =
    FutureProvider.autoDispose<List<RideInvitation>>((ref) async {
      final repository = ref.watch(ridesRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (repository == null || userId == null) return const [];
      return repository.myInvitations(userId);
    });

final clubRidesProvider = FutureProvider.autoDispose.family<List<Ride>, String>(
  (ref, clubId) async {
    final repository = ref.watch(ridesRepositoryProvider);
    if (repository == null) return const [];
    return repository.clubRides(clubId);
  },
);

/// Tout ce que la fiche d'une balade affiche.
class RideDetail {
  const RideDetail({
    required this.ride,
    required this.myStatus,
    required this.isOrganizer,
    required this.canManage,
    required this.participants,
    this.pendingRequests = const [],
  });

  final Ride ride;
  final ParticipantStatus? myStatus;
  final bool isOrganizer;

  /// Organisateur, ou administrateur du club pour une balade de club.
  final bool canManage;
  final List<RideParticipant> participants;
  final List<RideParticipant> pendingRequests;
}

final rideDetailProvider = FutureProvider.autoDispose
    .family<RideDetail?, String>((ref, rideId) async {
      final repository = ref.watch(ridesRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (repository == null || userId == null) return null;

      final ride = await repository.getRide(rideId);
      if (ride == null) return null;

      final isOrganizer = ride.organizerId == userId;
      var canManage = isOrganizer;
      if (!canManage && ride.clubId != null) {
        final role = await ref
            .read(clubsRepositoryProvider)
            ?.roleOf(ride.clubId!, userId);
        canManage = (role?.rank ?? 0) >= ClubRole.admin.rank;
      }

      final results = await Future.wait<Object?>([
        repository.myStatus(rideId, userId),
        repository.participants(rideId),
        canManage
            ? repository.pendingRequests(rideId)
            : Future<Object?>.value(const <RideParticipant>[]),
      ]);

      return RideDetail(
        ride: ride,
        myStatus: results[0] as ParticipantStatus?,
        isOrganizer: isOrganizer,
        canManage: canManage,
        participants: results[1]! as List<RideParticipant>,
        pendingRequests: results[2]! as List<RideParticipant>,
      );
    });

extension RidesRefresh on WidgetRef {
  /// Rafraîchit les vues des balades après une action.
  void refreshRides([String? rideId]) {
    invalidate(discoverRidesProvider);
    invalidate(myRidesProvider);
    invalidate(myRideInvitationsProvider);
    invalidate(clubRidesProvider);
    if (rideId != null) invalidate(rideDetailProvider(rideId));
  }
}
