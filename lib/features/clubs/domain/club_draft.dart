import 'club.dart';

/// Données saisies pour créer ou modifier un club.
class ClubDraft {
  const ClubDraft({
    required this.name,
    required this.city,
    required this.visibility,
    required this.joinPolicy,
    this.isListed = true,
    this.description = '',
    this.rules = '',
    this.countryCode = 'CD',
  });

  factory ClubDraft.fromClub(Club club) => ClubDraft(
    name: club.name,
    city: club.city,
    visibility: club.visibility,
    joinPolicy: club.joinPolicy,
    isListed: club.isListed,
    description: club.description,
    rules: club.rules,
    countryCode: club.countryCode,
  );

  final String name;
  final String city;
  final ClubVisibility visibility;
  final ClubJoinPolicy joinPolicy;
  final bool isListed;
  final String description;
  final String rules;
  final String countryCode;

  /// Un club public est toujours référencé.
  bool get effectiveIsListed =>
      visibility == ClubVisibility.public ? true : isListed;

  /// Problèmes de saisie (miroir des contraintes SQL).
  List<ClubDraftIssue> validate() {
    final issues = <ClubDraftIssue>[];
    final nameLength = name.trim().length;
    if (nameLength < 3 || nameLength > 80) issues.add(ClubDraftIssue.name);
    final cityLength = city.trim().length;
    if (cityLength < 2 || cityLength > 80) issues.add(ClubDraftIssue.city);
    if (description.length > 2000) issues.add(ClubDraftIssue.description);
    if (rules.length > 5000) issues.add(ClubDraftIssue.rules);
    if (!ClubJoinPolicy.allowedFor(visibility).contains(joinPolicy)) {
      issues.add(ClubDraftIssue.joinPolicy);
    }
    return issues;
  }

  /// Colonnes modifiables directement (cf. GRANT UPDATE dans la migration).
  Map<String, dynamic> toUpdateJson() => {
    'name': name.trim(),
    'city': city.trim(),
    'description': description.trim(),
    'rules': rules.trim(),
    'visibility': visibility.dbValue,
    'is_listed': effectiveIsListed,
    'join_policy': joinPolicy.dbValue,
  };
}

enum ClubDraftIssue { name, city, description, rules, joinPolicy }
