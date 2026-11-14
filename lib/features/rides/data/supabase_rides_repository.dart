import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ride.dart';
import '../domain/ride_draft.dart';
import 'rides_repository.dart';

class SupabaseRidesRepository implements RidesRepository {
  SupabaseRidesRepository(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _clock;

  /// Colonnes lues (la colonne PostGIS `start_point` n'est jamais renvoyée
  /// au client : latitude / longitude suffisent).
  static const rideColumns =
      'id, title, description, organizer_id, club_id, starts_at, ends_at, '
      'timezone, city, start_label, start_lat, start_lng, destination_label, '
      'destination_lat, destination_lng, itinerary, difficulty, '
      'recommended_bike_types, max_participants, conditions, visibility, '
      'open_to_non_members, join_policy, status, joins_locked, '
      'participant_count, cancellation_reason, cover_path, '
      'clubs(name), organizer:profiles!rides_organizer_id_fkey(display_name)';

  static const _participantColumns =
      'user_id, status, message, '
      'profiles!ride_participants_user_id_fkey(username, display_name, avatar_path)';

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

  static const _activeStatuses = ['published', 'locked', 'in_progress'];

  @override
  Future<List<Ride>> discoverRides({
    String query = '',
    RideDifficulty? difficulty,
  }) => _guard(() async {
    // Les balades en cours restent listées pendant 12 h après leur départ.
    final since = _clock().toUtc().subtract(const Duration(hours: 12));
    var request = _client
        .from('rides')
        .select(rideColumns)
        .inFilter('status', _activeStatuses)
        .gte('starts_at', since.toIso8601String());
    if (difficulty != null) {
      request = request.eq('difficulty', difficulty.dbValue);
    }
    final q = sanitizeQuery(query);
    if (q.isNotEmpty) {
      request = request.or(
        'title.ilike.*$q*,city.ilike.*$q*,'
        'start_label.ilike.*$q*,destination_label.ilike.*$q*',
      );
    }
    final rows = await request.order('starts_at').limit(50);
    return rows.map(Ride.fromJson).toList();
  });

  @override
  Future<List<MyRide>> myRides(String userId) => _guard(() async {
    final rows = await _client
        .from('ride_participants')
        .select('status, rides($rideColumns)')
        .eq('user_id', userId)
        .inFilter('status', ['pending', 'confirmed']);
    final result = [
      for (final row in rows)
        if (row['rides'] != null)
          MyRide(
            ride: Ride.fromJson(row['rides'] as Map<String, dynamic>),
            status: ParticipantStatus.parse(row['status'] as String),
          ),
    ]..sort((a, b) => a.ride.startsAt.compareTo(b.ride.startsAt));
    return result;
  });

  @override
  Future<List<Ride>> clubRides(String clubId) => _guard(() async {
    final since = _clock().toUtc().subtract(const Duration(hours: 12));
    final rows = await _client
        .from('rides')
        .select(rideColumns)
        .eq('club_id', clubId)
        .inFilter('status', _activeStatuses)
        .gte('starts_at', since.toIso8601String())
        .order('starts_at')
        .limit(20);
    return rows.map(Ride.fromJson).toList();
  });

  @override
  Future<Ride?> getRide(String rideId) => _guard(() async {
    final row = await _client
        .from('rides')
        .select(rideColumns)
        .eq('id', rideId)
        .maybeSingle();
    return row == null ? null : Ride.fromJson(row);
  });

  @override
  Future<ParticipantStatus?> myStatus(String rideId, String userId) =>
      _guard(() async {
        final row = await _client
            .from('ride_participants')
            .select('status')
            .eq('ride_id', rideId)
            .eq('user_id', userId)
            .maybeSingle();
        return row == null
            ? null
            : ParticipantStatus.parse(row['status'] as String);
      });

  @override
  Future<List<RideParticipant>> participants(String rideId) => _guard(() async {
    final rows = await _client
        .from('ride_participants')
        .select(_participantColumns)
        .eq('ride_id', rideId)
        .eq('status', 'confirmed')
        .order('confirmed_at');
    return rows.map(RideParticipant.fromJson).toList();
  });

  @override
  Future<List<RideParticipant>> pendingRequests(String rideId) =>
      _guard(() async {
        final rows = await _client
            .from('ride_participants')
            .select(_participantColumns)
            .eq('ride_id', rideId)
            .eq('status', 'pending')
            .order('requested_at');
        return rows.map(RideParticipant.fromJson).toList();
      });

  @override
  Future<Ride> createRide(RideDraft draft, {required bool publish}) => _guard(
    () async {
      final created = await _client.rpc<Map<String, dynamic>>(
        'create_ride',
        params: {
          'p_title': draft.title.trim(),
          'p_starts_at': draft.startsAt.toUtc().toIso8601String(),
          'p_city': draft.city.trim(),
          'p_start_label': draft.startLabel.trim(),
          'p_destination_label': draft.destinationLabel.trim(),
          'p_visibility': draft.visibility.dbValue,
          'p_join_policy': draft.joinPolicy.dbValue,
          'p_club_id': draft.clubId,
          'p_open_to_non_members':
              draft.visibility == RideVisibility.club && draft.openToNonMembers,
          'p_description': draft.description.trim(),
          'p_timezone': draft.timezone,
          'p_start_lat': draft.startLat,
          'p_start_lng': draft.startLng,
          'p_destination_lat': draft.destinationLat,
          'p_destination_lng': draft.destinationLng,
          'p_itinerary': draft.itinerary.trim(),
          'p_difficulty': draft.difficulty.dbValue,
          'p_recommended_bike_types': [
            for (final t in draft.bikeTypes) t.dbValue,
          ],
          'p_max_participants': draft.maxParticipants,
          'p_conditions': draft.conditions.trim(),
          'p_publish': publish,
        },
      );
      return Ride.fromJson(created);
    },
  );

  @override
  Future<String?> setCover(String rideId, String? path) => _guard(
    () => _client.rpc<String?>(
      'set_ride_cover',
      params: {'p_ride_id': rideId, 'p_path': path},
    ),
  );

  @override
  Future<void> updateRide(String rideId, RideDraft draft) => _guard(() async {
    final rows = await _client
        .from('rides')
        .update(draft.toUpdateJson())
        .eq('id', rideId)
        .select('id');
    if (rows.isEmpty) throw const AppException(AppException.notAllowed);
  });

  @override
  Future<void> setStatus(String rideId, RideAction action, {String? reason}) =>
      _guard(
        () => _client.rpc<Map<String, dynamic>>(
          'set_ride_status',
          params: {
            'p_ride_id': rideId,
            'p_action': action.name,
            'p_reason': reason,
          },
        ),
      );

  @override
  Future<void> deleteDraft(String rideId) => _guard(
    () => _client.rpc<void>('delete_ride_draft', params: {'p_ride_id': rideId}),
  );

  @override
  Future<RideJoinOutcome> join(String rideId, {String? message}) =>
      _guard(() async {
        final result = await _client.rpc<String>(
          'join_ride',
          params: {'p_ride_id': rideId, 'p_message': message},
        );
        return result == 'joined'
            ? RideJoinOutcome.joined
            : RideJoinOutcome.requested;
      });

  @override
  Future<void> cancelRequest(String rideId) => _guard(
    () =>
        _client.rpc<void>('cancel_ride_request', params: {'p_ride_id': rideId}),
  );

  @override
  Future<void> leave(String rideId) => _guard(
    () => _client.rpc<void>('leave_ride', params: {'p_ride_id': rideId}),
  );

  @override
  Future<void> decideRequest(
    String rideId,
    String userId, {
    required bool approve,
  }) => _guard(
    () => _client.rpc<void>(
      'decide_ride_request',
      params: {'p_ride_id': rideId, 'p_user_id': userId, 'p_approve': approve},
    ),
  );

  @override
  Future<void> removeParticipant(String rideId, String userId) => _guard(
    () => _client.rpc<void>(
      'remove_ride_participant',
      params: {'p_ride_id': rideId, 'p_user_id': userId},
    ),
  );

  @override
  Future<void> invite(String rideId, String inviteeId) => _guard(
    () => _client.rpc<String>(
      'invite_to_ride',
      params: {'p_ride_id': rideId, 'p_invitee_id': inviteeId},
    ),
  );

  @override
  Future<List<RideInvitation>> myInvitations(String userId) => _guard(() async {
    final rows = await _client
        .from('ride_invitations')
        .select(
          'id, ride_id, rides(title, starts_at, timezone), '
          'inviter:profiles!ride_invitations_invited_by_fkey(display_name)',
        )
        .eq('invitee_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows.map(RideInvitation.fromJson).toList();
  });

  @override
  Future<void> respondToInvitation(
    String invitationId, {
    required bool accept,
  }) => _guard(
    () => _client.rpc<void>(
      'respond_to_ride_invitation',
      params: {'p_invitation_id': invitationId, 'p_accept': accept},
    ),
  );
}
