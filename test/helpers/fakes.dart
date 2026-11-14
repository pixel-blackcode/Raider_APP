import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/core/media/media_repository.dart';
import 'package:rider_group/core/media/photo_picker.dart';
import 'package:rider_group/features/auth/data/auth_repository.dart';
import 'package:rider_group/features/auth/domain/auth_session.dart';
import 'package:rider_group/features/clubs/data/clubs_repository.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/clubs/domain/club_draft.dart';
import 'package:rider_group/features/community/data/community_repository.dart';
import 'package:rider_group/features/community/domain/community.dart';
import 'package:rider_group/features/convoy/data/convoy_repository.dart';
import 'package:rider_group/features/convoy/data/location_service.dart';
import 'package:rider_group/features/convoy/domain/convoy.dart';
import 'package:rider_group/features/marketplace/data/marketplace_repository.dart';
import 'package:rider_group/features/marketplace/domain/marketplace.dart';
import 'package:rider_group/features/messages/data/messaging_repository.dart';
import 'package:rider_group/features/messages/domain/messaging.dart';
import 'package:rider_group/features/profile/data/profile_repository.dart';
import 'package:rider_group/features/profile/domain/profile.dart';
import 'package:rider_group/features/rides/data/rides_repository.dart';
import 'package:rider_group/features/rides/domain/ride.dart';
import 'package:rider_group/features/rides/domain/ride_draft.dart';
import 'package:rider_group/features/rides/domain/ride_state_machine.dart';
import 'package:rider_group/features/sos/data/emergency.dart';
import 'package:rider_group/features/sos/data/sos_repository.dart';
import 'package:rider_group/features/sos/domain/sos.dart';

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
  final _recovery = StreamController<void>.broadcast();
  final resetRequests = <String>[];
  final calls = <String>[];
  Object? deleteError;

  /// Simule l'ouverture d'un lien de réinitialisation.
  void openRecoveryLink() => _recovery.add(null);
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
  Future<void> sendPasswordReset(String email) async =>
      resetRequests.add(email);

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('updatePassword');
    final email = _session?.email;
    if (email != null) accounts[email] = newPassword;
  }

  @override
  Stream<void> passwordRecoveryEvents() => _recovery.stream;

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    if (deleteError != null) throw deleteError!;
    _emit(null);
  }

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
  final settings = <String, PrivacySettings>{};

  @override
  Future<void> setAvatarPath(String userId, String? path) async {
    profiles[userId] = profiles[userId]!.copyWith(
      avatarPath: path,
      clearAvatar: path == null,
    );
  }

  @override
  Future<PrivacySettings> fetchPrivacySettings(String userId) async =>
      settings[userId] ?? const PrivacySettings();

  @override
  Future<void> savePrivacySettings(
    String userId,
    PrivacySettings value,
  ) async => settings[userId] = value;

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

  final images = <String, Map<ClubImageKind, String?>>{};

  @override
  Future<void> setClubImage(
    String clubId,
    ClubImageKind kind,
    String? path,
  ) async {
    calls.add('setImage:${kind.fileBaseName}');
    (images[clubId] ??= {})[kind] = path;
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

/// Médias en mémoire : enregistre les envois et suppressions.
class FakeMediaRepository implements MediaRepository {
  final uploads = <String>[];
  final removed = <String>[];
  final removedFolders = <String>[];
  var _seq = 0;

  @override
  Future<String> upload(
    MediaBucket bucket, {
    required String folder,
    required String baseName,
    required PickedImage image,
  }) async {
    image.validateFor(bucket);
    final path = '$folder/$baseName-${++_seq}.${image.extension}';
    uploads.add('${bucket.id}/$path');
    return path;
  }

  @override
  Future<void> remove(MediaBucket bucket, List<String> paths) async =>
      removed.addAll(paths.map((p) => '${bucket.id}/$p'));

  @override
  Future<void> removeFolder(MediaBucket bucket, String folder) async =>
      removedFolders.add('${bucket.id}/$folder');

  /// Pas d'image réseau dans les tests : l'initiale est affichée.
  @override
  ImageProvider? imageProvider(MediaBucket bucket, String? path) => null;
}

/// Sélecteur de photo renvoyant une image prédéfinie.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.next]);

  PickedImage? next;

  static PickedImage jpeg({int size = 1024}) =>
      PickedImage(bytes: Uint8List(size), extension: 'jpg');

  @override
  Future<PickedImage?> pick({required double maxDimension}) async => next;
}

/// Balades en mémoire, du point de vue de [currentUserId]. Reproduit la
/// machine à états et les refus visibles du serveur pour tester l'interface ;
/// les règles de sécurité réelles sont testées en SQL (05_rides_test.sql).
class FakeRidesRepository implements RidesRepository {
  FakeRidesRepository({required this.currentUserId, this.profiles = const {}});

  String currentUserId;
  final Map<String, Profile> profiles;
  final rides = <String, Ride>{};
  final members = <String, Map<String, ParticipantStatus>>{};
  final messages = <String, String?>{};
  final invitations = <RideInvitation>[];
  final invitationTargets = <String, String>{};
  final calls = <String>[];
  var _seq = 0;

  Ride addRide({
    required String title,
    required String organizerId,
    RideStatus status = RideStatus.published,
    bool joinsLocked = false,
    RideJoinPolicy joinPolicy = RideJoinPolicy.open,
    RideVisibility visibility = RideVisibility.public,
    int? maxParticipants,
    String? clubId,
    String? clubName,
    DateTime? startsAt,
    String timezone = 'Africa/Kinshasa',
    Map<String, ParticipantStatus> others = const {},
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
  }) {
    final id = 'ride-${++_seq}';
    members[id] = {organizerId: ParticipantStatus.confirmed, ...others};
    rides[id] = Ride(
      id: id,
      title: title,
      organizerId: organizerId,
      organizerName: profiles[organizerId]?.displayName,
      startsAt: startsAt ?? DateTime.now().toUtc().add(const Duration(days: 1)),
      timezone: timezone,
      city: 'Kinshasa',
      startLabel: 'Rond-point Victoire',
      destinationLabel: 'Kinkole',
      visibility: visibility,
      joinPolicy: joinPolicy,
      status: status,
      joinsLocked: joinsLocked || status == RideStatus.locked,
      maxParticipants: maxParticipants,
      clubId: clubId,
      clubName: clubName,
      startLat: startLat,
      startLng: startLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
    _sync(id);
    return rides[id]!;
  }

  void _sync(String id, {RideStatus? status, bool? joinsLocked}) {
    final r = rides[id]!;
    final count = members[id]!.values
        .where((s) => s == ParticipantStatus.confirmed)
        .length;
    rides[id] = Ride(
      id: r.id,
      title: r.title,
      organizerId: r.organizerId,
      organizerName: r.organizerName,
      startsAt: r.startsAt,
      timezone: r.timezone,
      city: r.city,
      startLabel: r.startLabel,
      destinationLabel: r.destinationLabel,
      visibility: r.visibility,
      joinPolicy: r.joinPolicy,
      status: status ?? r.status,
      joinsLocked: joinsLocked ?? r.joinsLocked,
      maxParticipants: r.maxParticipants,
      clubId: r.clubId,
      clubName: r.clubName,
      participantCount: count,
      startLat: r.startLat,
      startLng: r.startLng,
      destinationLat: r.destinationLat,
      destinationLng: r.destinationLng,
      coverPath: covers[id] ?? r.coverPath,
    );
  }

  RideParticipant _participant(String rideId, String userId) => RideParticipant(
    userId: userId,
    status: members[rideId]![userId]!,
    displayName: profiles[userId]?.displayName ?? userId,
    username: profiles[userId]?.username ?? userId,
    message: messages['$rideId/$userId'],
  );

  @override
  Future<List<Ride>> discoverRides({
    String query = '',
    RideDifficulty? difficulty,
  }) async {
    final q = query.toLowerCase();
    return rides.values
        .where(
          (r) =>
              r.visibility == RideVisibility.public &&
              !r.status.isTerminal &&
              r.status != RideStatus.draft,
        )
        .where((r) => difficulty == null || r.difficulty == difficulty)
        .where(
          (r) =>
              q.isEmpty ||
              r.title.toLowerCase().contains(q) ||
              r.city.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<List<MyRide>> myRides(String userId) async => [
    for (final entry in members.entries)
      if (entry.value[userId] == ParticipantStatus.confirmed ||
          entry.value[userId] == ParticipantStatus.pending)
        MyRide(ride: rides[entry.key]!, status: entry.value[userId]!),
  ];

  @override
  Future<List<Ride>> clubRides(String clubId) async =>
      rides.values.where((r) => r.clubId == clubId).toList();

  @override
  Future<Ride?> getRide(String rideId) async => rides[rideId];

  @override
  Future<ParticipantStatus?> myStatus(String rideId, String userId) async =>
      members[rideId]?[userId];

  @override
  Future<List<RideParticipant>> participants(String rideId) async => [
    for (final e in members[rideId]!.entries)
      if (e.value == ParticipantStatus.confirmed) _participant(rideId, e.key),
  ];

  @override
  Future<List<RideParticipant>> pendingRequests(String rideId) async => [
    for (final e in members[rideId]!.entries)
      if (e.value == ParticipantStatus.pending) _participant(rideId, e.key),
  ];

  RideDraft? lastDraft;
  bool? lastPublish;

  @override
  Future<Ride> createRide(RideDraft draft, {required bool publish}) async {
    calls.add(publish ? 'createRide:publish' : 'createRide:draft');
    lastDraft = draft;
    lastPublish = publish;
    return addRide(
      title: draft.title.trim(),
      organizerId: currentUserId,
      status: publish ? RideStatus.published : RideStatus.draft,
      joinPolicy: draft.joinPolicy,
      visibility: draft.visibility,
      maxParticipants: draft.maxParticipants,
      clubId: draft.clubId,
      startsAt: draft.startsAt,
      timezone: draft.timezone,
      startLat: draft.startLat,
      startLng: draft.startLng,
      destinationLat: draft.destinationLat,
      destinationLng: draft.destinationLng,
    );
  }

  final covers = <String, String?>{};

  @override
  Future<String?> setCover(String rideId, String? path) async {
    calls.add('setCover:$rideId:$path');
    final old = covers[rideId];
    covers[rideId] = path;
    _sync(rideId);
    return old;
  }

  @override
  Future<void> updateRide(String rideId, RideDraft draft) async {
    calls.add('updateRide');
    lastDraft = draft;
  }

  @override
  Future<void> setStatus(
    String rideId,
    RideAction action, {
    String? reason,
  }) async {
    calls.add('status:${action.name}${reason == null ? '' : ':$reason'}');
    final next = RideStateMachine.next(rides[rideId]!.state, action);
    if (next == null) throw const AppException('invalid_transition');
    _sync(rideId, status: next.status, joinsLocked: next.joinsLocked);
  }

  @override
  Future<void> deleteDraft(String rideId) async {
    calls.add('deleteDraft');
    rides.remove(rideId);
    members.remove(rideId);
  }

  @override
  Future<RideJoinOutcome> join(String rideId, {String? message}) async {
    calls.add('join');
    final ride = rides[rideId]!;
    if (!ride.acceptsParticipants) {
      throw const AppException('ride_not_joinable');
    }
    if (ride.isFull) throw const AppException('ride_full');
    switch (ride.joinPolicy) {
      case RideJoinPolicy.open:
        members[rideId]![currentUserId] = ParticipantStatus.confirmed;
        _sync(rideId);
        return RideJoinOutcome.joined;
      case RideJoinPolicy.approval:
        members[rideId]![currentUserId] = ParticipantStatus.pending;
        messages['$rideId/$currentUserId'] = message;
        return RideJoinOutcome.requested;
      case RideJoinPolicy.inviteOnly:
        throw const AppException('invitation_required');
    }
  }

  @override
  Future<void> cancelRequest(String rideId) async =>
      members[rideId]![currentUserId] = ParticipantStatus.cancelled;

  @override
  Future<void> leave(String rideId) async {
    calls.add('leave');
    members[rideId]![currentUserId] = ParticipantStatus.left;
    _sync(rideId);
  }

  @override
  Future<void> decideRequest(
    String rideId,
    String userId, {
    required bool approve,
  }) async {
    calls.add('decide:$userId:$approve');
    if (approve && !rides[rideId]!.acceptsParticipants) {
      throw const AppException('ride_not_joinable');
    }
    members[rideId]![userId] = approve
        ? ParticipantStatus.confirmed
        : ParticipantStatus.rejected;
    _sync(rideId);
  }

  @override
  Future<void> removeParticipant(String rideId, String userId) async {
    calls.add('remove:$userId');
    members[rideId]![userId] = ParticipantStatus.removed;
    _sync(rideId);
  }

  @override
  Future<void> invite(String rideId, String inviteeId) async {
    calls.add('invite:$inviteeId');
    final id = 'rinv-${++_seq}';
    invitations.add(
      RideInvitation(id: id, rideId: rideId, rideTitle: rides[rideId]!.title),
    );
    invitationTargets[id] = inviteeId;
  }

  @override
  Future<List<RideInvitation>> myInvitations(String userId) async => [
    for (final i in invitations)
      if (invitationTargets[i.id] == userId) i,
  ];

  @override
  Future<void> respondToInvitation(
    String invitationId, {
    required bool accept,
  }) async {
    final invitation = invitations.firstWhere((i) => i.id == invitationId);
    if (accept && !rides[invitation.rideId]!.acceptsParticipants) {
      throw const AppException('ride_not_joinable');
    }
    invitations.remove(invitation);
    if (accept) {
      members[invitation.rideId]![currentUserId] = ParticipantStatus.confirmed;
      _sync(invitation.rideId);
    }
  }
}

/// Doublure du convoi : positions poussées à la main, règles serveur
/// simplifiées (partage requis, balade en cours gérée par le test).
class FakeConvoyRepository implements ConvoyRepository {
  final positionsCtrl = StreamController<List<RiderPosition>>.broadcast();
  List<RiderPosition> current = const [];
  final roleMap = <ConvoyRole, String>{};
  final sharing = <String, bool>{};
  final published = <RiderPosition>[];
  final calls = <String>[];
  AppException? publishError;

  void push(List<RiderPosition> positions) {
    current = positions;
    positionsCtrl.add(positions);
  }

  @override
  Stream<List<RiderPosition>> watchPositions(String rideId) async* {
    yield current;
    yield* positionsCtrl.stream;
  }

  @override
  Future<Map<ConvoyRole, String>> roles(String rideId) async => {...roleMap};

  @override
  Future<bool> isSharing(String rideId, String userId) async =>
      sharing[rideId] ?? false;

  @override
  Future<void> setSharing(String rideId, {required bool enabled}) async {
    calls.add('setSharing:$enabled');
    sharing[rideId] = enabled;
  }

  @override
  Future<void> publish(String rideId, RiderPosition position) async {
    calls.add('publish');
    if (publishError != null) throw publishError!;
    published.add(position);
  }

  final trailPoints = <TrailPoint>[];

  @override
  Future<List<TrailPoint>> trail(String rideId) async => List.of(trailPoints);

  @override
  Future<void> setRole(String rideId, ConvoyRole role, String? userId) async {
    calls.add('setRole:${role.name}:$userId');
    if (userId == null) {
      roleMap.remove(role);
    } else {
      roleMap[role] = userId;
    }
  }
}

class FakeLocationService implements LocationService {
  LocationAccess access = LocationAccess.granted;
  final ctrl = StreamController<RiderPosition>.broadcast();
  var permissionRequests = 0;

  @override
  Future<LocationAccess> ensurePermission() async {
    permissionRequests++;
    return access;
  }

  @override
  Stream<RiderPosition> positions() => ctrl.stream;

  /// Position renvoyée par [current] (null : GPS indisponible).
  RiderPosition? fix = RiderPosition(
    userId: '',
    lat: -4.3217,
    lng: 15.3125,
    recordedAt: DateTime.utc(2026, 11, 12, 10),
    accuracyM: 10,
  );

  @override
  Future<RiderPosition?> current({
    Duration timeout = const Duration(seconds: 8),
  }) async => fix;

  void emit(double lat, double lng, {double? speedMps}) => ctrl.add(
    RiderPosition(
      userId: '',
      lat: lat,
      lng: lng,
      recordedAt: DateTime.now().toUtc(),
      speedMps: speedMps,
    ),
  );
}

/// Doublure SOS : flux pilotés par le test, pannes réseau simulables.
class FakeSosRepository implements SosRepository {
  FakeSosRepository({required this.currentUserId});

  String currentUserId;
  final alerts = <SosAlert>[];
  final acks = <SosAck>[];
  final calls = <String>[];
  final raised = <({String clientRef, RiderPosition? position})>[];
  final _alertsCtrl = StreamController<List<SosAlert>>.broadcast();
  final _acksCtrl = StreamController<List<SosAck>>.broadcast();

  /// Erreur levée par les prochains appels à [raise] (réseau coupé...).
  AppException? raiseError;

  /// Si non nul, [raise] attend ce signal (envoi « en cours »).
  Completer<void>? raiseGate;
  var _seq = 0;

  void _emit() {
    _alertsCtrl.add(List.of(alerts));
    _acksCtrl.add(List.of(acks));
  }

  SosAlert addAlert({
    required String rideId,
    required String userId,
    SosKind kind = SosKind.breakdown,
    double? lat = -4.33,
    double? lng = 15.32,
    String? message,
  }) {
    final a = SosAlert(
      id: 'sos-${++_seq}',
      rideId: rideId,
      userId: userId,
      clientRef: 'ref-$_seq',
      kind: kind,
      status: SosStatus.active,
      createdAt: DateTime.now().toUtc(),
      lat: lat,
      lng: lng,
      message: message,
      positionSource: lat == null ? null : 'device',
    );
    alerts.add(a);
    _emit();
    return a;
  }

  void addAck(String alertId, String userId) {
    acks.add(
      SosAck(alertId: alertId, userId: userId, ackedAt: DateTime.now().toUtc()),
    );
    _emit();
  }

  @override
  Future<SosAlert> raise({
    required String rideId,
    required SosKind kind,
    required String clientRef,
    String? message,
    RiderPosition? position,
  }) async {
    calls.add('raise:${kind.dbValue}');
    raised.add((clientRef: clientRef, position: position));
    if (raiseGate != null) await raiseGate!.future;
    if (raiseError != null) throw raiseError!;
    for (final a in alerts) {
      if (a.clientRef == clientRef) return a;
    }
    final a = SosAlert(
      id: 'sos-${++_seq}',
      rideId: rideId,
      userId: currentUserId,
      clientRef: clientRef,
      kind: kind,
      status: SosStatus.active,
      createdAt: DateTime.now().toUtc(),
      lat: position?.lat,
      lng: position?.lng,
      positionSource: position == null ? null : 'device',
    );
    alerts.add(a);
    _emit();
    return a;
  }

  @override
  Future<void> acknowledge(String alertId) async {
    calls.add('ack:$alertId');
    addAck(alertId, currentUserId);
  }

  @override
  Future<SosAlert> close(
    String alertId,
    SosStatus status, {
    String? note,
  }) async {
    calls.add('close:$alertId:${status.dbValue}');
    final i = alerts.indexWhere((a) => a.id == alertId);
    final a = alerts[i];
    alerts[i] = SosAlert(
      id: a.id,
      rideId: a.rideId,
      userId: a.userId,
      clientRef: a.clientRef,
      kind: a.kind,
      status: status,
      createdAt: a.createdAt,
      closedAt: DateTime.now().toUtc(),
      closedBy: currentUserId,
    );
    _emit();
    return alerts[i];
  }

  @override
  Stream<List<SosAlert>> watchRideAlerts(String rideId) async* {
    List<SosAlert> forRide(List<SosAlert> all) =>
        all.where((a) => a.rideId == rideId).toList();
    yield forRide(alerts);
    yield* _alertsCtrl.stream.map(forRide);
  }

  @override
  Stream<List<SosAlert>> watchRecentAlerts() async* {
    yield List.of(alerts);
    yield* _alertsCtrl.stream;
  }

  @override
  Stream<List<SosAck>> watchAcks(String rideId) async* {
    yield List.of(acks);
    yield* _acksCtrl.stream;
  }
}

class FakeExternalActions implements ExternalActions {
  final dialed = <String>[];
  final maps = <String>[];

  @override
  Future<bool> dial(String number) async {
    dialed.add(number);
    return true;
  }

  @override
  Future<bool> openMap(double lat, double lng) async {
    maps.add('$lat,$lng');
    return true;
  }
}

/// Doublure de la communauté : règles serveur simplifiées (blocage,
/// audience club, auteur), pannes simulables.
class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({
    required this.currentUserId,
    this.profiles = const {},
    this.clubMembers = const {},
  });

  String currentUserId;
  final Map<String, Profile> profiles;

  /// club → membres.
  final Map<String, Set<String>> clubMembers;
  final posts = <Post>[];
  final commentList = <PostComment>[];
  final blocks = <(String, String)>{};
  final reports = <String>[];
  final calls = <String>[];
  final createdRefs = <String>[];
  final moderators = <String>{};
  final queue = <ModerationItem>[];
  AppException? createError;
  var _seq = 0;

  bool _blocked(String a, String b) =>
      blocks.contains((a, b)) || blocks.contains((b, a));

  bool _visible(Post p) =>
      p.authorId == currentUserId ||
      (!p.hidden &&
          !_blocked(p.authorId, currentUserId) &&
          (p.audience == PostAudience.public ||
              (clubMembers[p.clubId] ?? const {}).contains(currentUserId)));

  Post addPost({
    required String authorId,
    String body = 'Sortie au fleuve',
    String? clubId,
    PostAudience audience = PostAudience.public,
    List<String> mediaPaths = const [],
    bool hidden = false,
  }) {
    final p = Post(
      id: 'post-${++_seq}',
      authorId: authorId,
      authorName: profiles[authorId]?.displayName ?? '',
      clubId: clubId,
      clubName: clubId == null ? null : 'Club $clubId',
      audience: audience,
      body: body,
      hidden: hidden,
      mediaPaths: mediaPaths,
      createdAt: DateTime.now().toUtc().subtract(Duration(minutes: _seq)),
    );
    posts.insert(0, p);
    return p;
  }

  Post _withCounts(Post p) => Post(
    id: p.id,
    authorId: p.authorId,
    authorName: p.authorName,
    clubId: p.clubId,
    clubName: p.clubName,
    audience: p.audience,
    body: p.body,
    hidden: p.hidden,
    createdAt: p.createdAt,
    mediaPaths: p.mediaPaths,
    commentCount: commentList.where((c) => c.postId == p.id).length,
    reactions: p.reactions,
    myReaction: p.myReaction,
  );

  @override
  Future<List<Post>> feed({
    String? clubId,
    String? authorId,
    DateTime? before,
    int limit = 20,
  }) async => [
    for (final p in posts)
      if (_visible(p) &&
          (clubId == null || p.clubId == clubId) &&
          (authorId == null || p.authorId == authorId))
        _withCounts(p),
  ];

  @override
  Future<Post?> post(String postId) async {
    for (final p in posts) {
      if (p.id == postId && _visible(p)) return _withCounts(p);
    }
    return null;
  }

  @override
  Future<String> createPost({
    required String clientRef,
    required String body,
    PostAudience audience = PostAudience.public,
    String? clubId,
    List<String> mediaPaths = const [],
  }) async {
    calls.add('createPost:${audience.dbValue}:${mediaPaths.length}');
    createdRefs.add(clientRef);
    if (createError != null) throw createError!;
    return addPost(
      authorId: currentUserId,
      body: body,
      clubId: clubId,
      audience: audience,
      mediaPaths: mediaPaths,
    ).id;
  }

  @override
  Future<List<String>> deletePost(String postId) async {
    calls.add('deletePost:$postId');
    final p = posts.firstWhere((p) => p.id == postId);
    posts.remove(p);
    return p.mediaPaths;
  }

  @override
  Future<List<PostComment>> comments(String postId) async => [
    for (final c in commentList)
      if (c.postId == postId && !_blocked(c.authorId, currentUserId)) c,
  ];

  @override
  Future<void> addComment(String postId, String body, String clientRef) async {
    calls.add('addComment');
    commentList.add(
      PostComment(
        id: 'c-${++_seq}',
        postId: postId,
        authorId: currentUserId,
        authorName: profiles[currentUserId]?.displayName ?? '',
        body: body,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    calls.add('deleteComment:$commentId');
    commentList.removeWhere((c) => c.id == commentId);
  }

  @override
  Future<void> setReaction(String postId, ReactionKind? kind) async {
    calls.add('react:$postId:${kind?.dbValue}');
    final i = posts.indexWhere((p) => p.id == postId);
    posts[i] = posts[i].withMyReaction(kind);
  }

  @override
  Future<void> block(String userId) async {
    calls.add('block:$userId');
    blocks.add((currentUserId, userId));
  }

  @override
  Future<void> unblock(String userId) async {
    calls.add('unblock:$userId');
    blocks.remove((currentUserId, userId));
  }

  @override
  Future<List<BlockedUser>> blockedUsers() async => [
    for (final (a, b) in blocks)
      if (a == currentUserId)
        BlockedUser(
          userId: b,
          displayName: profiles[b]?.displayName ?? b,
          username: profiles[b]?.username ?? b,
        ),
  ];

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? details,
  }) async {
    reports.add('${target.name}:$targetId:${reason.name}');
  }

  @override
  Future<List<RiderHit>> searchRiders(String query) async {
    String fold(String v) => v.toLowerCase().replaceAll('ph', 'f');
    final q = fold(query.replaceFirst('@', '').trim());
    if (q.length < 2) return const [];
    return [
      for (final p in profiles.values)
        if (p.id != currentUserId &&
            (fold(p.displayName).contains(q) || fold(p.username).contains(q)))
          RiderHit(id: p.id, username: p.username, displayName: p.displayName),
    ];
  }

  @override
  Future<bool> amIModerator() async => moderators.contains(currentUserId);

  @override
  Future<List<ModerationItem>> moderationQueue() async =>
      moderators.contains(currentUserId) ? List.of(queue) : const [];

  @override
  Future<void> moderate(
    ReportTarget target,
    String targetId,
    ModerationAction action, {
    String? note,
  }) async {
    calls.add('moderate:${target.name}:$targetId:${action.name}');
    queue.removeWhere((i) => i.targetId == targetId);
  }
}

/// Doublure de la messagerie : flux pilotés par le test, pannes réseau.
class FakeMessagingRepository implements MessagingRepository {
  FakeMessagingRepository({
    required this.currentUserId,
    this.profiles = const {},
  });

  String currentUserId;
  final Map<String, Profile> profiles;
  final conversations = <ConversationSummary>[];
  final members = <String, Set<String>>{};
  final messages = <ChatMessage>[];
  final calls = <String>[];
  final sentRefs = <String>[];
  final _changes = StreamController<void>.broadcast();
  AppException? sendError;
  var _seq = 0;

  ConversationSummary addConversation({
    ConversationKind kind = ConversationKind.direct,
    String title = 'Conversation',
    String? otherUserId,
    String? rideId,
    Set<String> memberIds = const {},
    bool blocked = false,
  }) {
    final c = ConversationSummary(
      id: 'conv-${++_seq}',
      kind: kind,
      title: title,
      otherUserId: otherUserId,
      rideId: rideId,
      blocked: blocked,
    );
    conversations.add(c);
    members[c.id] = {currentUserId, ...memberIds, ?otherUserId};
    return c;
  }

  ChatMessage addMessage(String conversationId, String senderId, String body) {
    final m = ChatMessage(
      id: 'm-${++_seq}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: profiles[senderId]?.displayName,
      body: body,
      clientRef: 'ref-$_seq',
      createdAt: DateTime.now().toUtc().add(Duration(milliseconds: _seq)),
    );
    messages.add(m);
    _changes.add(null);
    return m;
  }

  final _read = <String, DateTime>{};

  @override
  Future<List<ConversationSummary>> inbox() async => [
    for (final c in conversations)
      if (members[c.id]?.contains(currentUserId) ?? false)
        ConversationSummary(
          id: c.id,
          kind: c.kind,
          title: c.title,
          otherUserId: c.otherUserId,
          rideId: c.rideId,
          blocked: c.blocked,
          lastMessage: messages
              .where((m) => m.conversationId == c.id)
              .lastOrNull
              ?.body,
          lastMessageAt: messages
              .where((m) => m.conversationId == c.id)
              .lastOrNull
              ?.createdAt,
          unreadCount: messages
              .where(
                (m) =>
                    m.conversationId == c.id &&
                    m.senderId != currentUserId &&
                    m.createdAt.isAfter(
                      _read[c.id] ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ),
              )
              .length,
        ),
  ];

  @override
  Stream<void> inboxChanges() => _changes.stream;

  @override
  Future<String> openDirect(String userId) async {
    calls.add('openDirect:$userId');
    for (final c in conversations) {
      if (c.kind == ConversationKind.direct && c.otherUserId == userId) {
        return c.id;
      }
    }
    return addConversation(
      otherUserId: userId,
      title: profiles[userId]?.displayName ?? '',
    ).id;
  }

  @override
  Future<String> createGroup(String title, List<String> memberIds) async {
    calls.add('createGroup:$title:${memberIds.join(',')}');
    return addConversation(
      kind: ConversationKind.group,
      title: title,
      memberIds: memberIds.toSet(),
    ).id;
  }

  @override
  Future<String> openRide(String rideId) async {
    calls.add('openRide:$rideId');
    for (final c in conversations) {
      if (c.rideId == rideId) return c.id;
    }
    return addConversation(
      kind: ConversationKind.ride,
      title: 'Balade',
      rideId: rideId,
    ).id;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) async* {
    List<ChatMessage> now() =>
        messages.where((m) => m.conversationId == conversationId).toList();
    yield now();
    yield* _changes.stream.map((_) => now());
  }

  @override
  Future<ChatMessage> send(
    String conversationId,
    String body,
    String clientRef,
  ) async {
    calls.add('send:$body');
    sentRefs.add(clientRef);
    if (sendError != null) throw sendError!;
    for (final m in messages) {
      if (m.clientRef == clientRef) return m;
    }
    final m = ChatMessage(
      id: 'm-${++_seq}',
      conversationId: conversationId,
      senderId: currentUserId,
      body: body,
      clientRef: clientRef,
      createdAt: DateTime.now().toUtc(),
    );
    messages.add(m);
    _changes.add(null);
    return m;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    calls.add('delete:$messageId');
  }

  @override
  Future<void> markRead(String conversationId) async {
    _read[conversationId] = DateTime.now().toUtc().add(const Duration(days: 1));
  }

  @override
  Future<void> removeMember(String conversationId, String userId) async {
    calls.add('remove:$conversationId:$userId');
    members[conversationId]?.remove(userId);
  }
}

/// Doublure de la marketplace : filtres simplifiés, pannes simulables.
class FakeMarketplaceRepository implements MarketplaceRepository {
  FakeMarketplaceRepository({
    required this.currentUserId,
    this.profiles = const {},
  });

  String currentUserId;
  final Map<String, Profile> profiles;
  final listings = <Listing>[];
  final favorites = <String>{};
  final calls = <String>[];
  final createdRefs = <String>[];
  AppException? createError;
  var _seq = 0;

  Listing add({
    required String sellerId,
    String title = 'Casque LS2',
    ListingCategory category = ListingCategory.helmet,
    double? price = 80,
    Currency currency = Currency.usd,
    ListingStatus status = ListingStatus.available,
    String city = 'Kinshasa',
    List<String> mediaPaths = const [],
  }) {
    final l = Listing(
      id: 'listing-${++_seq}',
      sellerId: sellerId,
      sellerName: profiles[sellerId]?.displayName ?? '',
      category: category,
      title: title,
      condition: ListingCondition.good,
      city: city,
      price: price,
      currency: currency,
      status: status,
      mediaPaths: mediaPaths,
      createdAt: DateTime.now().toUtc(),
    );
    listings.insert(0, l);
    return l;
  }

  Listing _view(Listing l) => Listing(
    id: l.id,
    sellerId: l.sellerId,
    sellerName: l.sellerName,
    category: l.category,
    title: l.title,
    description: l.description,
    condition: l.condition,
    city: l.city,
    area: l.area,
    price: l.price,
    currency: l.currency,
    status: l.status,
    mediaPaths: l.mediaPaths,
    createdAt: l.createdAt,
    isFavorite: favorites.contains(l.id),
  );

  @override
  Future<List<Listing>> search(ListingFilter f, {required String me}) async {
    String fold(String v) => v.toLowerCase().replaceAll('ph', 'f');
    return [
      for (final l in listings)
        if ((f.scope != ListingScope.mine || l.sellerId == me) &&
            (f.scope != ListingScope.favorites || favorites.contains(l.id)) &&
            (f.scope == ListingScope.mine || l.status != ListingStatus.sold) &&
            (f.category == null || l.category == f.category) &&
            (f.query.trim().length < 2 ||
                fold(l.title).contains(fold(f.query.trim()))) &&
            (f.maxPrice == null ||
                (l.price != null && l.price! <= f.maxPrice!)))
          _view(l),
    ];
  }

  @override
  Future<Listing?> listing(String id) async {
    for (final l in listings) {
      if (l.id == id) return _view(l);
    }
    return null;
  }

  @override
  Future<String> create(
    ListingDraft draft, {
    required String clientRef,
    List<String> mediaPaths = const [],
  }) async {
    calls.add('create:${draft.category.name}:${mediaPaths.length}');
    createdRefs.add(clientRef);
    if (createError != null) throw createError!;
    return add(
      sellerId: currentUserId,
      title: draft.title,
      category: draft.category,
      price: draft.price,
      currency: draft.currency,
      city: draft.city,
      mediaPaths: mediaPaths,
    ).id;
  }

  @override
  Future<List<String>> update(
    String id,
    ListingDraft draft, {
    List<String> mediaPaths = const [],
  }) async {
    calls.add('update:$id:${draft.title}');
    final i = listings.indexWhere((l) => l.id == id);
    final old = listings[i];
    listings[i] = Listing(
      id: id,
      sellerId: old.sellerId,
      sellerName: old.sellerName,
      category: draft.category,
      title: draft.title,
      condition: draft.condition,
      city: draft.city,
      price: draft.price,
      currency: draft.currency,
      status: old.status,
      mediaPaths: mediaPaths,
      createdAt: old.createdAt,
    );
    return [
      for (final p in old.mediaPaths)
        if (!mediaPaths.contains(p)) p,
    ];
  }

  @override
  Future<void> setStatus(String id, ListingStatus status) async {
    calls.add('status:$id:${status.name}');
    final i = listings.indexWhere((l) => l.id == id);
    final old = listings[i];
    listings[i] = Listing(
      id: id,
      sellerId: old.sellerId,
      sellerName: old.sellerName,
      category: old.category,
      title: old.title,
      condition: old.condition,
      city: old.city,
      price: old.price,
      currency: old.currency,
      status: status,
      mediaPaths: old.mediaPaths,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<List<String>> delete(String id) async {
    calls.add('delete:$id');
    final l = listings.firstWhere((l) => l.id == id);
    listings.remove(l);
    return l.mediaPaths;
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    calls.add('favorite:$id:$favorite');
    if (favorite) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
  }
}
