import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/clubs/domain/club_draft.dart';
import 'package:rider_group/features/clubs/domain/club_permissions.dart';

ClubMember member(ClubRole role) => ClubMember(
  userId: role.name,
  role: role,
  username: role.name,
  displayName: role.name,
);

void main() {
  group('ClubJoinPolicy.allowedFor (miroir de la contrainte SQL)', () {
    test('public : libre ou approbation', () {
      expect(ClubJoinPolicy.allowedFor(ClubVisibility.public), [
        ClubJoinPolicy.open,
        ClubJoinPolicy.approval,
      ]);
    });
    test('privé : approbation ou invitation', () {
      expect(ClubJoinPolicy.allowedFor(ClubVisibility.private), [
        ClubJoinPolicy.approval,
        ClubJoinPolicy.inviteOnly,
      ]);
    });
  });

  group('ClubDraft', () {
    const valid = ClubDraft(
      name: 'Kin Riders',
      city: 'Kinshasa',
      visibility: ClubVisibility.public,
      joinPolicy: ClubJoinPolicy.open,
    );

    test('brouillon valide', () => expect(valid.validate(), isEmpty));

    test('détecte les erreurs de saisie', () {
      const draft = ClubDraft(
        name: 'Ab',
        city: 'K',
        visibility: ClubVisibility.public,
        joinPolicy: ClubJoinPolicy.inviteOnly,
      );
      expect(draft.validate(), [
        ClubDraftIssue.name,
        ClubDraftIssue.city,
        ClubDraftIssue.joinPolicy,
      ]);
    });

    test('un club public est toujours référencé', () {
      const draft = ClubDraft(
        name: 'Kin Riders',
        city: 'Kinshasa',
        visibility: ClubVisibility.public,
        joinPolicy: ClubJoinPolicy.open,
        isListed: false,
      );
      expect(draft.effectiveIsListed, isTrue);
      expect(draft.toUpdateJson()['is_listed'], isTrue);
    });

    test('n\'envoie que les colonnes modifiables', () {
      expect(valid.toUpdateJson().keys, isNot(contains('verified_at')));
      expect(valid.toUpdateJson().keys, isNot(contains('owner_id')));
      expect(valid.toUpdateJson().keys, isNot(contains('member_count')));
    });
  });

  group('ClubPermissions (miroir des fonctions serveur)', () {
    test('non-membre', () {
      const p = ClubPermissions(null);
      expect(p.isMember, isFalse);
      expect(p.canEditDetails, isFalse);
      expect(p.canLeave, isFalse);
      expect(p.canRemove(member(ClubRole.member)), isFalse);
    });

    test('propriétaire', () {
      const p = ClubPermissions(ClubRole.owner);
      expect(p.canChangeSettings, isTrue);
      expect(p.canRequestVerification, isTrue);
      expect(p.canDeleteClub, isTrue);
      expect(p.canLeave, isFalse);
      expect(p.assignableRoles(member(ClubRole.member)), [
        ClubRole.admin,
        ClubRole.moderator,
      ]);
      expect(p.canRemove(member(ClubRole.admin)), isTrue);
    });

    test('administrateur', () {
      const p = ClubPermissions(ClubRole.admin);
      expect(p.canEditDetails, isTrue);
      expect(p.canChangeSettings, isFalse);
      expect(p.canRequestVerification, isTrue);
      expect(p.canLeave, isTrue);
      expect(p.assignableRoles(member(ClubRole.member)), [ClubRole.moderator]);
      expect(p.assignableRoles(member(ClubRole.admin)), isEmpty);
      expect(p.canRemove(member(ClubRole.moderator)), isTrue);
      expect(p.canRemove(member(ClubRole.owner)), isFalse);
    });

    test('modérateur', () {
      const p = ClubPermissions(ClubRole.moderator);
      expect(p.canEditDetails, isFalse);
      expect(p.canInvite, isFalse);
      expect(p.canRemove(member(ClubRole.member)), isTrue);
      expect(p.canRemove(member(ClubRole.moderator)), isFalse);
      expect(p.assignableRoles(member(ClubRole.member)), isEmpty);
    });

    test('membre', () {
      const p = ClubPermissions(ClubRole.member);
      expect(p.canRemove(member(ClubRole.member)), isFalse);
      expect(p.assignableRoles(member(ClubRole.member)), isEmpty);
    });
  });

  test('Club.fromJson lit une ligne PostgREST', () {
    final club = Club.fromJson({
      'id': 'c1',
      'name': 'Lions',
      'city': 'Lubumbashi',
      'visibility': 'private',
      'is_listed': false,
      'join_policy': 'invite_only',
      'owner_id': 'u1',
      'member_count': 12,
      'verified_at': '2026-11-10T10:00:00Z',
      'suspended_at': null,
    });
    expect(club.isPrivate, isTrue);
    expect(club.isListed, isFalse);
    expect(club.joinPolicy, ClubJoinPolicy.inviteOnly);
    expect(club.memberCount, 12);
    expect(club.isVerified, isTrue);
    expect(club.isSuspended, isFalse);
  });

  test('ClubMember.fromJson lit le profil imbriqué', () {
    final m = ClubMember.fromJson({
      'user_id': 'u1',
      'role': 'moderator',
      'profiles': {'username': 'joel', 'display_name': 'Joël'},
    });
    expect(m.role, ClubRole.moderator);
    expect(m.displayName, 'Joël');
  });
}
