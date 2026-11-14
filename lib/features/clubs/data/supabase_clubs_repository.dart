import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/club.dart';
import '../domain/club_draft.dart';
import 'clubs_repository.dart';

class SupabaseClubsRepository implements ClubsRepository {
  SupabaseClubsRepository(this._client);

  final SupabaseClient _client;

  static const _clubColumns =
      'id, name, description, rules, city, country_code, visibility, '
      'is_listed, join_policy, owner_id, member_count, verified_at, verified_until, '
      'suspended_at, created_at, logo_path, cover_path';

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Retire les caractères ayant un sens dans la syntaxe de filtre PostgREST.
  static String sanitizeQuery(String query) =>
      query.replaceAll(RegExp(r'[,()%*\\.:"]'), ' ').trim();

  @override
  Future<List<Club>> discoverClubs({String query = ''}) => _guard(() async {
    // Recherche tolérante côté serveur (fautes, accents, « ph » = « f »).
    if (query.trim().length >= 2) {
      final data = await _client.rpc<Object?>(
        'search_clubs',
        params: {'p_query': query.trim(), 'p_limit': 50},
      );
      return [
        for (final r in (data as List?) ?? const [])
          Club.fromJson(r as Map<String, dynamic>),
      ];
    }
    var request = _client
        .from('clubs')
        .select(_clubColumns)
        .eq('is_listed', true)
        .isFilter('suspended_at', null);
    final q = sanitizeQuery(query);
    if (q.isNotEmpty) {
      request = request.or('name.ilike.*$q*,city.ilike.*$q*');
    }
    final rows = await request
        .order('member_count', ascending: false)
        .order('name')
        .limit(50);
    return rows.map(Club.fromJson).toList();
  });

  @override
  Future<List<ClubMembership>> myClubs(String userId) => _guard(() async {
    final rows = await _client
        .from('club_members')
        .select('role, clubs($_clubColumns)')
        .eq('user_id', userId)
        .order('joined_at');
    return [
      for (final row in rows)
        if (row['clubs'] != null)
          ClubMembership(
            club: Club.fromJson(row['clubs'] as Map<String, dynamic>),
            role: ClubRole.parse(row['role'] as String),
          ),
    ];
  });

  @override
  Future<Club?> getClub(String clubId) => _guard(() async {
    final row = await _client
        .from('clubs')
        .select(_clubColumns)
        .eq('id', clubId)
        .maybeSingle();
    return row == null ? null : Club.fromJson(row);
  });

  @override
  Future<ClubRole?> roleOf(String clubId, String userId) => _guard(() async {
    final row = await _client
        .from('club_members')
        .select('role')
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : ClubRole.parse(row['role'] as String);
  });

  @override
  Future<List<ClubMember>> members(String clubId) => _guard(() async {
    final rows = await _client
        .from('club_members')
        .select(
          'user_id, role, joined_at, '
          'profiles(username, display_name, avatar_path)',
        )
        .eq('club_id', clubId)
        .order('joined_at');
    final members = rows.map(ClubMember.fromJson).toList()
      ..sort((a, b) => b.role.rank.compareTo(a.role.rank));
    return members;
  });

  @override
  Future<Club> createClub(ClubDraft draft) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_club',
      params: {
        'p_name': draft.name.trim(),
        'p_city': draft.city.trim(),
        'p_visibility': draft.visibility.dbValue,
        'p_join_policy': draft.joinPolicy.dbValue,
        'p_is_listed': draft.effectiveIsListed,
        'p_description': draft.description.trim(),
        'p_rules': draft.rules.trim(),
        'p_country_code': draft.countryCode,
      },
    );
    return Club.fromJson(row);
  });

  @override
  Future<void> updateClub(String clubId, ClubDraft draft) => _guard(() async {
    final rows = await _client
        .from('clubs')
        .update(draft.toUpdateJson())
        .eq('id', clubId)
        .select('id');
    // RLS : 0 ligne modifiée = pas l'autorisation.
    if (rows.isEmpty) throw const AppException(AppException.notAllowed);
  });

  @override
  Future<void> setClubImage(String clubId, ClubImageKind kind, String? path) =>
      _guard(() async {
        final rows = await _client
            .from('clubs')
            .update({kind.column: path})
            .eq('id', clubId)
            .select('id');
        if (rows.isEmpty) throw const AppException(AppException.notAllowed);
      });

  @override
  Future<void> deleteClub(String clubId) => _guard(
    () => _client.rpc<void>('delete_club', params: {'p_club_id': clubId}),
  );

  @override
  Future<JoinOutcome> joinClub(String clubId, {String? message}) =>
      _guard(() async {
        final result = await _client.rpc<String>(
          'join_club',
          params: {'p_club_id': clubId, 'p_message': message},
        );
        return result == 'joined' ? JoinOutcome.joined : JoinOutcome.requested;
      });

  @override
  Future<void> leaveClub(String clubId) => _guard(
    () => _client.rpc<void>('leave_club', params: {'p_club_id': clubId}),
  );

  @override
  Future<ClubJoinRequest?> myPendingRequest(String clubId, String userId) =>
      _guard(() async {
        final row = await _client
            .from('club_join_requests')
            .select('id, club_id, user_id, message, created_at')
            .eq('club_id', clubId)
            .eq('user_id', userId)
            .eq('status', 'pending')
            .maybeSingle();
        return row == null ? null : ClubJoinRequest.fromJson(row);
      });

  @override
  Future<void> cancelJoinRequest(String requestId) => _guard(
    () => _client.rpc<void>(
      'cancel_club_join_request',
      params: {'p_request_id': requestId},
    ),
  );

  @override
  Future<List<ClubJoinRequest>> pendingRequests(String clubId) =>
      _guard(() async {
        final rows = await _client
            .from('club_join_requests')
            .select(
              'id, club_id, user_id, message, created_at, '
              'requester:profiles!club_join_requests_user_id_fkey'
              '(username, display_name)',
            )
            .eq('club_id', clubId)
            .eq('status', 'pending')
            .order('created_at');
        return rows.map(ClubJoinRequest.fromJson).toList();
      });

  @override
  Future<void> decideJoinRequest(String requestId, {required bool approve}) =>
      _guard(
        () => _client.rpc<void>(
          'decide_club_join_request',
          params: {'p_request_id': requestId, 'p_approve': approve},
        ),
      );

  @override
  Future<void> invite(String clubId, String inviteeId) => _guard(
    () => _client.rpc<void>(
      'invite_to_club',
      params: {'p_club_id': clubId, 'p_invitee_id': inviteeId},
    ),
  );

  @override
  Future<List<ClubInvitation>> myInvitations(String userId) => _guard(() async {
    final rows = await _client
        .from('club_invitations')
        .select(
          'id, club_id, clubs(name, city), '
          'inviter:profiles!club_invitations_invited_by_fkey(display_name)',
        )
        .eq('invitee_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows.map(ClubInvitation.fromJson).toList();
  });

  @override
  Future<void> respondToInvitation(
    String invitationId, {
    required bool accept,
  }) => _guard(
    () => _client.rpc<void>(
      'respond_to_club_invitation',
      params: {'p_invitation_id': invitationId, 'p_accept': accept},
    ),
  );

  @override
  Future<void> setMemberRole(String clubId, String userId, ClubRole role) =>
      _guard(
        () => _client.rpc<void>(
          'set_club_member_role',
          params: {
            'p_club_id': clubId,
            'p_user_id': userId,
            'p_role': role.dbValue,
          },
        ),
      );

  @override
  Future<void> removeMember(String clubId, String userId) => _guard(
    () => _client.rpc<void>(
      'remove_club_member',
      params: {'p_club_id': clubId, 'p_user_id': userId},
    ),
  );

  @override
  Future<void> transferOwnership(String clubId, String newOwnerId) => _guard(
    () => _client.rpc<void>(
      'transfer_club_ownership',
      params: {'p_club_id': clubId, 'p_new_owner_id': newOwnerId},
    ),
  );

  @override
  Future<ClubVerificationRequest?> latestVerificationRequest(String clubId) =>
      _guard(() async {
        final row = await _client
            .from('club_verification_requests')
            .select('id, status, review_note')
            .eq('club_id', clubId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return row == null ? null : ClubVerificationRequest.fromJson(row);
      });

  @override
  Future<void> requestVerification(String clubId, VerificationForm form) =>
      _guard(
        () => _client.rpc<Object?>(
          'request_club_verification',
          params: {
            'p_club_id': clubId,
            'p_official_name': form.officialName,
            'p_contact_name': form.contactName,
            'p_contact_phone': form.contactPhone,
            'p_message': form.message,
            'p_document_paths': form.documentPaths,
          },
        ),
      );
}
