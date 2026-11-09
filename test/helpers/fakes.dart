import 'dart:async';

import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/auth/data/auth_repository.dart';
import 'package:rider_group/features/auth/domain/auth_session.dart';
import 'package:rider_group/features/clubs/data/clubs_repository.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/clubs/domain/club_draft.dart';
import 'package:rider_group/features/profile/data/profile_repository.dart';
import 'package:rider_group/features/profile/domain/profile.dart';

/// Authentification en mémoire. Les mots de passe sont ceux de [accounts].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSession? initial,
    this.requireConfirmation = false,
    Map<String, String>? accounts,
  }) : _session = initial,
       accounts = accounts ?? {};

  final bool requireConfirmation;
  final Map<String, String> accounts;
  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _session;

  void _emit(AuthSession? session) {
    _session = session;
    _controller.add(session);
  }

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email] != password) {
      throw const AppException(AppException.invalidCredentials);
    }
    _emit(AuthSession(userId: 'user-$email', email: email));
  }

  @override
  Future<void> signOut() async => _emit(null);

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    if (accounts.containsKey(email)) {
      throw const AppException(AppException.userAlreadyExists);
    }
    accounts[email] = password;
    if (requireConfirmation) return SignUpOutcome.confirmationRequired;
    _emit(AuthSession(userId: 'user-$email', email: email));
    return SignUpOutcome.signedIn;
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([Iterable<Profile> profiles = const []])
    : profiles = {for (final p in profiles) p.id: p};

  final Map<String, Profile> profiles;

  @override
  Future<Profile?> fetchProfile(String userId) async => profiles[userId];

  @override
  Future<Profile?> findByUsername(String username) async {
    for (final p in profiles.values) {
      if (p.username == username.toLowerCase()) return p;
    }
    return null;
  }

  @override
  Future<Profile> updateProfile(String userId, ProfileUpdate update) async {
    final updated = profiles[userId]!.copyWith(
      username: update.username,
      displayName: update.displayName,
      city: update.city,
      bio: update.bio,
    );
    profiles[userId] = updated;
    return updated;
  }
}

/// Clubs en mémoire, du point de vue de [currentUserId].
///
/// Reproduit le comportement visible des fonctions serveur pour tester
/// l'interface ; les règles de sécurité réelles sont testées en SQL.
class FakeClubsRepository implements ClubsRepository {
  FakeClubsRepository({required this.currentUserId, this.profiles = const {}});

  String currentUserId;
  final Map<String, Profile> profiles;
  final clubs = <String, Club>{};
  final roles = <String, Map<String, ClubRole>>{};
  final requests = <ClubJoinRequest>[];
  final invitations = <ClubInvitation>[];
  final invitationTargets = <String, String>{};
  final verificationRequests = <String, ClubVerificationRequest>{};
  final calls = <String>[];
  var _seq = 0;

  Club addClub({
    required String name,
    required String ownerId,
    ClubVisibility visibility = ClubVisibility.public,
    ClubJoinPolicy joinPolicy = ClubJoinPolicy.open,
    bool isListed = true,
    bool verified = false,
    Map<String, ClubRole> members = const {},
  }) {
    final id = 'club-${++_seq}';
    roles[id] = {ownerId: ClubRole.owner, ...members};
    clubs[id] = Club(
      id: id,
      name: name,
      city: 'Kinshasa',
      description: 'Description de $name',
      visibility: visibility,
      joinPolicy: joinPolicy,
      isListed: isListed,
      ownerId: ownerId,
      memberCount: roles[id]!.length,
      verifiedAt: verified ? DateTime(2026) : null,
    );
    return clubs[id]!;
  }

  void _syncCount(String clubId) {
    final c = clubs[clubId]!;
    clubs[clubId] = Club(
      id: c.id,
      name: c.name,
      city: c.city,
      description: c.description,
      rules: c.rules,
      visibility: c.visibility,
      joinPolicy: c.joinPolicy,
      isListed: c.isListed,
      ownerId: c.ownerId,
      memberCount: roles[clubId]!.length,
      verifiedAt: c.verifiedAt,
    );
  }

  bool _visible(Club c) =>
      c.visibility == ClubVisibility.public ||
      c.isListed ||
      roles[c.id]!.containsKey(currentUserId) ||
      invitationTargets.entries.any(
        (e) =>
            e.value == currentUserId &&
            invitations.any((i) => i.id == e.key && i.clubId == c.id),
      );

  @override
  Future<List<Club>> discoverClubs({String query = ''}) async {
    final q = query.toLowerCase();
    return clubs.values
        .where((c) => c.isListed)
        .where(
          (c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<List<ClubMembership>> myClubs(String userId) async => [
    for (final entry in roles.entries)
      if (entry.value.containsKey(userId))
        ClubMembership(club: clubs[entry.key]!, role: entry.value[userId]!),
  ];

  @override
  Future<Club?> getClub(String clubId) async {
    final club = clubs[clubId];
    return club != null && _visible(club) ? club : null;
  }

  @override
  Future<ClubRole?> roleOf(String clubId, String userId) async =>
      roles[clubId]?[userId];

  @override
  Future<List<ClubMember>> members(String clubId) async {
    final club = clubs[clubId]!;
    if (club.isPrivate && !roles[clubId]!.containsKey(currentUserId)) {
      return const [];
    }
    return [
      for (final e in roles[clubId]!.entries)
        ClubMember(
          userId: e.key,
          role: e.value,
          username: profiles[e.key]?.username ?? e.key,
          displayName: profiles[e.key]?.displayName ?? e.key,
        ),
    ]..sort((a, b) => b.role.rank.compareTo(a.role.rank));
  }

  @override
  Future<Club> createClub(ClubDraft draft) async {
    calls.add('createClub');
    if (clubs.values.any(
      (c) => c.name.toLowerCase() == draft.name.trim().toLowerCase(),
    )) {
      throw const AppException('club_name_taken');
    }
    return addClub(
      name: draft.name.trim(),
      ownerId: currentUserId,
      visibility: draft.visibility,
      joinPolicy: draft.joinPolicy,
      isListed: draft.effectiveIsListed,
    );
  }

  @override
  Future<void> updateClub(String clubId, ClubDraft draft) async {
    calls.add('updateClub');
  }

  @override
  Future<void> deleteClub(String clubId) async {
    calls.add('deleteClub');
    clubs.remove(clubId);
    roles.remove(clubId);
  }

  @override
  Future<JoinOutcome> joinClub(String clubId, {String? message}) async {
    calls.add('joinClub');
    final club = clubs[clubId]!;
    switch (club.joinPolicy) {
      case ClubJoinPolicy.open:
        roles[clubId]![currentUserId] = ClubRole.member;
        _syncCount(clubId);
        return JoinOutcome.joined;
      case ClubJoinPolicy.approval:
        requests.add(
          ClubJoinRequest(
            id: 'req-${++_seq}',
            clubId: clubId,
            userId: currentUserId,
            displayName: profiles[currentUserId]?.displayName ?? '',
            username: profiles[currentUserId]?.username ?? '',
            message: message,
          ),
        );
        return JoinOutcome.requested;
      case ClubJoinPolicy.inviteOnly:
        throw const AppException('invitation_required');
    }
  }

  @override
  Future<void> leaveClub(String clubId) async {
    calls.add('leaveClub');
    roles[clubId]!.remove(currentUserId);
    _syncCount(clubId);
  }

  @override
  Future<ClubJoinRequest?> myPendingRequest(
    String clubId,
    String userId,
  ) async {
    for (final r in requests) {
      if (r.clubId == clubId && r.userId == userId) return r;
    }
    return null;
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async =>
      requests.removeWhere((r) => r.id == requestId);

  @override
  Future<List<ClubJoinRequest>> pendingRequests(String clubId) async =>
      requests.where((r) => r.clubId == clubId).toList();

  @override
  Future<void> decideJoinRequest(
    String requestId, {
    required bool approve,
  }) async {
    final request = requests.firstWhere((r) => r.id == requestId);
    requests.remove(request);
    if (approve) {
      roles[request.clubId]![request.userId] = ClubRole.member;
      _syncCount(request.clubId);
    }
  }

  @override
  Future<void> invite(String clubId, String inviteeId) async {
    calls.add('invite:$inviteeId');
    final id = 'inv-${++_seq}';
    invitations.add(
      ClubInvitation(id: id, clubId: clubId, clubName: clubs[clubId]!.name),
    );
    invitationTargets[id] = inviteeId;
  }

  @override
  Future<List<ClubInvitation>> myInvitations(String userId) async => [
    for (final i in invitations)
      if (invitationTargets[i.id] == userId) i,
  ];

  @override
  Future<void> respondToInvitation(
    String invitationId, {
    required bool accept,
  }) async {
    final invitation = invitations.firstWhere((i) => i.id == invitationId);
    invitations.remove(invitation);
    if (accept) {
      roles[invitation.clubId]![currentUserId] = ClubRole.member;
      _syncCount(invitation.clubId);
    }
  }

  @override
  Future<void> setMemberRole(
    String clubId,
    String userId,
    ClubRole role,
  ) async {
    calls.add('setRole:$userId:${role.dbValue}');
    roles[clubId]![userId] = role;
  }

  @override
  Future<void> removeMember(String clubId, String userId) async {
    calls.add('remove:$userId');
    roles[clubId]!.remove(userId);
    _syncCount(clubId);
  }

  @override
  Future<void> transferOwnership(String clubId, String newOwnerId) async {
    calls.add('transfer:$newOwnerId');
  }

  @override
  Future<ClubVerificationRequest?> latestVerificationRequest(
    String clubId,
  ) async => verificationRequests[clubId];

  @override
  Future<void> requestVerification(String clubId, {String? message}) async {
    calls.add('requestVerification');
    verificationRequests[clubId] = const ClubVerificationRequest(
      id: 'ver-1',
      status: VerificationStatus.pending,
    );
  }
}
