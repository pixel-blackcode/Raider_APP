/// Profil public d'un motard.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.city,
    this.countryCode = 'CD',
    this.bio,
    this.avatarPath,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    city: json['city'] as String?,
    countryCode: (json['country_code'] as String?) ?? 'CD',
    bio: json['bio'] as String?,
    avatarPath: json['avatar_path'] as String?,
  );

  final String id;
  final String username;
  final String displayName;
  final String? city;
  final String countryCode;
  final String? bio;

  /// Chemin dans le bucket privé `avatars` (`<id>/<fichier>`).
  final String? avatarPath;

  Profile copyWith({
    String? username,
    String? displayName,
    String? city,
    String? bio,
    String? avatarPath,
    bool clearAvatar = false,
  }) => Profile(
    id: id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    city: city ?? this.city,
    countryCode: countryCode,
    bio: bio ?? this.bio,
    avatarPath: clearAvatar ? null : avatarPath ?? this.avatarPath,
  );
}

/// Champs modifiables du profil.
class ProfileUpdate {
  const ProfileUpdate({
    required this.username,
    required this.displayName,
    this.city,
    this.bio,
  });

  final String username;
  final String displayName;
  final String? city;
  final String? bio;

  Map<String, dynamic> toJson() => {
    'username': username,
    'display_name': displayName.trim(),
    'city': _blankToNull(city),
    'bio': _blankToNull(bio),
  };

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// Préférences de confidentialité (table `profile_settings`).
class PrivacySettings {
  const PrivacySettings({
    this.discoverable = true,
    this.allowClubInvitations = true,
    this.allowRideInvitations = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        discoverable: (json['discoverable'] as bool?) ?? true,
        allowClubInvitations: (json['allow_club_invitations'] as bool?) ?? true,
        allowRideInvitations: (json['allow_ride_invitations'] as bool?) ?? true,
      );

  /// Profil visible par tous les motards connectés (sinon : seulement par
  /// les membres de ses clubs).
  final bool discoverable;

  /// Les administrateurs de club peuvent l'inviter.
  final bool allowClubInvitations;

  /// Les organisateurs de balade peuvent l'inviter.
  final bool allowRideInvitations;

  PrivacySettings copyWith({
    bool? discoverable,
    bool? allowClubInvitations,
    bool? allowRideInvitations,
  }) => PrivacySettings(
    discoverable: discoverable ?? this.discoverable,
    allowClubInvitations: allowClubInvitations ?? this.allowClubInvitations,
    allowRideInvitations: allowRideInvitations ?? this.allowRideInvitations,
  );
}
