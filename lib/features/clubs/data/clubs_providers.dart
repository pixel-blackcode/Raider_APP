import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/club.dart';
import 'clubs_repository.dart';
import 'supabase_clubs_repository.dart';

/// Dépôt des clubs ; `null` si le backend n'est pas initialisé.
final clubsRepositoryProvider = Provider<ClubsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseClubsRepository(client);
});

/// Texte de recherche de l'onglet « Découvrir ».
final clubSearchQueryProvider = NotifierProvider<ClubSearchQuery, String>(
  ClubSearchQuery.new,
);

class ClubSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value.trim();
}

final discoverClubsProvider = FutureProvider.autoDispose<List<Club>>((
  ref,
) async {
  final repository = ref.watch(clubsRepositoryProvider);
  if (repository == null) return const [];
  return repository.discoverClubs(query: ref.watch(clubSearchQueryProvider));
});

final myClubsProvider = FutureProvider.autoDispose<List<ClubMembership>>((
  ref,
) async {
  final repository = ref.watch(clubsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (repository == null || userId == null) return const [];
  return repository.myClubs(userId);
});

final myClubInvitationsProvider =
    FutureProvider.autoDispose<List<ClubInvitation>>((ref) async {
      final repository = ref.watch(clubsRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (repository == null || userId == null) return const [];
      return repository.myInvitations(userId);
    });

/// Tout ce que l'écran de détail affiche pour un club.
class ClubDetail {
  const ClubDetail({
    required this.club,
    required this.myRole,
    required this.members,
    this.myPendingRequest,
    this.pendingRequests = const [],
    this.verificationRequest,
  });

  final Club club;
  final ClubRole? myRole;
  final List<ClubMember> members;
  final ClubJoinRequest? myPendingRequest;
  final List<ClubJoinRequest> pendingRequests;
  final ClubVerificationRequest? verificationRequest;
}

/// `null` si le club n'existe pas ou n'est pas visible par l'utilisateur.
final clubDetailProvider = FutureProvider.autoDispose
    .family<ClubDetail?, String>((ref, clubId) async {
      final repository = ref.watch(clubsRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (repository == null || userId == null) return null;

      final club = await repository.getClub(clubId);
      if (club == null) return null;

      final role = await repository.roleOf(clubId, userId);
      final isAdmin = (role?.rank ?? 0) >= ClubRole.admin.rank;

      final results = await Future.wait<Object?>([
        repository.members(clubId),
        role == null
            ? repository.myPendingRequest(clubId, userId)
            : Future<Object?>.value(),
        isAdmin
            ? repository.pendingRequests(clubId)
            : Future<Object?>.value(const <ClubJoinRequest>[]),
        isAdmin
            ? repository.latestVerificationRequest(clubId)
            : Future<Object?>.value(),
      ]);

      return ClubDetail(
        club: club,
        myRole: role,
        members: results[0]! as List<ClubMember>,
        myPendingRequest: results[1] as ClubJoinRequest?,
        pendingRequests: results[2]! as List<ClubJoinRequest>,
        verificationRequest: results[3] as ClubVerificationRequest?,
      );
    });

extension ClubsRefresh on WidgetRef {
  /// Rafraîchit toutes les vues des clubs après une action.
  void refreshClubs([String? clubId]) {
    invalidate(myClubsProvider);
    invalidate(discoverClubsProvider);
    invalidate(myClubInvitationsProvider);
    if (clubId != null) invalidate(clubDetailProvider(clubId));
  }
}
