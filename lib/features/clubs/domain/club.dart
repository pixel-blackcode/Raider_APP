/// Visibilité d'un club.
enum ClubVisibility {
  public('public'),
  private('private');

  const ClubVisibility(this.dbValue);

  final String dbValue;

  static ClubVisibility parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

/// Conditions d'adhésion.
enum ClubJoinPolicy {
  open('open'),
  approval('approval'),
  inviteOnly('invite_only');

  const ClubJoinPolicy(this.dbValue);

  final String dbValue;

  static ClubJoinPolicy parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);

  /// Modes autorisés selon la visibilité (miroir de la contrainte SQL
  /// `clubs_policy_consistency`).
  static List<ClubJoinPolicy> allowedFor(ClubVisibility visibility) =>
      switch (visibility) {
        ClubVisibility.public => const [open, approval],
        ClubVisibility.private => const [approval, inviteOnly],
      };
}

/// Responsabilité d'un membre au sein d'un club.
enum ClubRole {
  owner('owner', 4),
  admin('admin', 3),
  moderator('moderator', 2),
  member('member', 1);

  const ClubRole(this.dbValue, this.rank);

  final String dbValue;

  /// Rang hiérarchique (miroir de `private.club_role_rank`).
  final int rank;

  static ClubRole parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

/// Résultat d'une demande d'adhésion.
enum JoinOutcome { joined, requested }

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.city,
    required this.visibility,
    required this.joinPolicy,
    required this.ownerId,
    this.description = '',
    this.rules = '',
    this.countryCode = 'CD',
    this.isListed = true,
    this.memberCount = 0,
    this.verifiedAt,
    this.suspendedAt,
    this.createdAt,
    this.logoPath,
    this.coverPath,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    rules: (json['rules'] as String?) ?? '',
    city: json['city'] as String,
    countryCode: (json['country_code'] as String?) ?? 'CD',
    visibility: ClubVisibility.parse(json['visibility'] as String),
    isListed: (json['is_listed'] as bool?) ?? true,
    joinPolicy: ClubJoinPolicy.parse(json['join_policy'] as String),
    ownerId: json['owner_id'] as String,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    verifiedAt: _date(json['verified_at']),
    suspendedAt: _date(json['suspended_at']),
    createdAt: _date(json['created_at']),
    logoPath: json['logo_path'] as String?,
    coverPath: json['cover_path'] as String?,
  );

  final String id;
  final String name;
  final String description;
  final String rules;
  final String city;
  final String countryCode;
  final ClubVisibility visibility;
  final bool isListed;
  final ClubJoinPolicy joinPolicy;
  final String ownerId;
  final int memberCount;
  final DateTime? verifiedAt;
  final DateTime? suspendedAt;
  final DateTime? createdAt;

  /// Chemins dans le bucket privé `club-media` (`<id>/<fichier>`).
  final String? logoPath;
  final String? coverPath;

  bool get isVerified => verifiedAt != null;
  bool get isSuspended => suspendedAt != null;
  bool get isPrivate => visibility == ClubVisibility.private;
}

/// Image d'un club.
enum ClubImageKind {
  logo('logo', 'logo_path'),
  cover('cover', 'cover_path');

  const ClubImageKind(this.fileBaseName, this.column);

  final String fileBaseName;
  final String column;
}

class ClubMember {
  const ClubMember({
    required this.userId,
    required this.role,
    required this.username,
    required this.displayName,
    this.avatarPath,
    this.joinedAt,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? const {};
    return ClubMember(
      userId: json['user_id'] as String,
      role: ClubRole.parse(json['role'] as String),
      username: (profile['username'] as String?) ?? '',
      displayName: (profile['display_name'] as String?) ?? '',
      avatarPath: profile['avatar_path'] as String?,
      joinedAt: _date(json['joined_at']),
    );
  }

  final String userId;
  final ClubRole role;
  final String username;

  /// Vide si le profil n'est pas visible (préférences de confidentialité).
  final String displayName;
  final String? avatarPath;
  final DateTime? joinedAt;
}

/// Un club dont l'utilisateur est membre, avec son rôle.
class ClubMembership {
  const ClubMembership({required this.club, required this.role});

  final Club club;
  final ClubRole role;
}

class ClubJoinRequest {
  const ClubJoinRequest({
    required this.id,
    required this.clubId,
    required this.userId,
    this.username = '',
    this.displayName = '',
    this.message,
    this.createdAt,
  });

  factory ClubJoinRequest.fromJson(Map<String, dynamic> json) {
    final profile = (json['requester'] as Map<String, dynamic>?) ?? const {};
    return ClubJoinRequest(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      username: (profile['username'] as String?) ?? '',
      displayName: (profile['display_name'] as String?) ?? '',
      message: json['message'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  final String id;
  final String clubId;
  final String userId;
  final String username;
  final String displayName;
  final String? message;
  final DateTime? createdAt;
}

class ClubInvitation {
  const ClubInvitation({
    required this.id,
    required this.clubId,
    required this.clubName,
    this.clubCity = '',
    this.inviterName,
  });

  factory ClubInvitation.fromJson(Map<String, dynamic> json) {
    final club = (json['clubs'] as Map<String, dynamic>?) ?? const {};
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return ClubInvitation(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      clubName: (club['name'] as String?) ?? '',
      clubCity: (club['city'] as String?) ?? '',
      inviterName: inviter?['display_name'] as String?,
    );
  }

  final String id;
  final String clubId;
  final String clubName;
  final String clubCity;
  final String? inviterName;
}

enum VerificationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const VerificationStatus(this.dbValue);

  final String dbValue;

  static VerificationStatus parse(String value) =>
      values.firstWhere((v) => v.dbValue == value);
}

class ClubVerificationRequest {
  const ClubVerificationRequest({
    required this.id,
    required this.status,
    this.reviewNote,
  });

  factory ClubVerificationRequest.fromJson(Map<String, dynamic> json) =>
      ClubVerificationRequest(
        id: json['id'] as String,
        status: VerificationStatus.parse(json['status'] as String),
        reviewNote: json['review_note'] as String?,
      );

  final String id;
  final VerificationStatus status;
  final String? reviewNote;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
