/// Profil public d'un motard.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.city,
    this.countryCode = 'CD',
    this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    city: json['city'] as String?,
    countryCode: (json['country_code'] as String?) ?? 'CD',
    bio: json['bio'] as String?,
  );

  final String id;
  final String username;
  final String displayName;
  final String? city;
  final String countryCode;
  final String? bio;

  Profile copyWith({
    String? username,
    String? displayName,
    String? city,
    String? bio,
  }) => Profile(
    id: id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    city: city ?? this.city,
    countryCode: countryCode,
    bio: bio ?? this.bio,
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
