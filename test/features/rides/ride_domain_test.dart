import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rider_group/features/rides/data/supabase_rides_repository.dart';
import 'package:rider_group/features/rides/domain/ride.dart';
import 'package:rider_group/features/rides/domain/ride_draft.dart';
import 'package:rider_group/features/rides/domain/ride_state_machine.dart';
import 'package:rider_group/features/rides/domain/ride_time.dart';

const draft = RideState(RideStatus.draft);
const published = RideState(RideStatus.published);
const locked = RideState(RideStatus.locked, joinsLocked: true);
const running = RideState(RideStatus.inProgress);
const runningLocked = RideState(RideStatus.inProgress, joinsLocked: true);
const finished = RideState(RideStatus.finished);
const cancelled = RideState(RideStatus.cancelled);

void main() {
  group('RideStateMachine (miroir de private.ride_transition)', () {
    // Table complète : état × action → état attendu (null = interdit).
    final expected = <RideState, Map<RideAction, RideState?>>{
      draft: {
        RideAction.publish: published,
        RideAction.lock: null,
        RideAction.unlock: null,
        RideAction.start: null,
        RideAction.finish: null,
        RideAction.cancel: null,
      },
      published: {
        RideAction.publish: null,
        RideAction.lock: locked,
        RideAction.unlock: null,
        RideAction.start: running,
        RideAction.finish: null,
        RideAction.cancel: cancelled,
      },
      locked: {
        RideAction.publish: null,
        RideAction.lock: null,
        RideAction.unlock: published,
        RideAction.start: runningLocked,
        RideAction.finish: null,
        RideAction.cancel: cancelled,
      },
      running: {
        RideAction.publish: null,
        RideAction.lock: runningLocked,
        RideAction.unlock: null,
        RideAction.start: null,
        RideAction.finish: finished,
        RideAction.cancel: cancelled,
      },
      runningLocked: {
        RideAction.publish: null,
        RideAction.lock: null,
        RideAction.unlock: running,
        RideAction.start: null,
        RideAction.finish: finished,
        RideAction.cancel: cancelled,
      },
      finished: {for (final a in RideAction.values) a: null},
      cancelled: {for (final a in RideAction.values) a: null},
    };

    expected.forEach((state, transitions) {
      transitions.forEach((action, target) {
        test('$state --${action.name}--> ${target ?? 'interdit'}', () {
          expect(RideStateMachine.next(state, action), target);
        });
      });
    });

    test('une balade verrouillée démarre verrouillée', () {
      expect(RideStateMachine.next(locked, RideAction.start), runningLocked);
    });

    test('actions proposées', () {
      expect(RideStateMachine.availableActions(published), [
        RideAction.lock,
        RideAction.start,
        RideAction.cancel,
      ]);
      expect(RideStateMachine.availableActions(finished), isEmpty);
    });

    test('nouvelles adhésions (miroir de ride_accepts_participants)', () {
      expect(RideStateMachine.acceptsParticipants(published), isTrue);
      expect(RideStateMachine.acceptsParticipants(running), isTrue);
      for (final s in [draft, locked, runningLocked, finished, cancelled]) {
        expect(RideStateMachine.acceptsParticipants(s), isFalse, reason: '$s');
      }
    });

    test('modifiable seulement avant le départ', () {
      expect(RideStateMachine.isEditable(RideStatus.draft), isTrue);
      expect(RideStateMachine.isEditable(RideStatus.locked), isTrue);
      expect(RideStateMachine.isEditable(RideStatus.inProgress), isFalse);
      expect(RideStateMachine.isEditable(RideStatus.finished), isFalse);
    });
  });

  group('RideTime : deux fuseaux en RDC', () {
    setUpAll(() => initializeDateFormatting('fr'));

    test('08:00 à Kinshasa (UTC+1) = 07:00 UTC', () {
      final utc = RideTime.toUtc(
        localDate: DateTime(2026, 12, 5),
        hour: 8,
        minute: 0,
        zoneId: 'Africa/Kinshasa',
      );
      expect(utc, DateTime.utc(2026, 12, 5, 7));
    });

    test('08:00 à Lubumbashi (UTC+2) = 06:00 UTC', () {
      final utc = RideTime.toUtc(
        localDate: DateTime(2026, 12, 5),
        hour: 8,
        minute: 0,
        zoneId: 'Africa/Lubumbashi',
      );
      expect(utc, DateTime.utc(2026, 12, 5, 6));
    });

    test('un même instant s\'affiche selon le fuseau de la balade', () {
      final instant = DateTime.utc(2026, 12, 5, 7, 30);
      expect(RideTime.formatTime(instant, 'Africa/Kinshasa'), '08:30');
      expect(RideTime.formatTime(instant, 'Africa/Lubumbashi'), '09:30');
      expect(
        RideTime.formatDate(instant, 'Africa/Kinshasa'),
        'samedi 5 décembre 2026',
      );
    });

    test('passage de minuit selon le fuseau', () {
      final instant = DateTime.utc(2026, 12, 5, 22, 30);
      expect(RideTime.inZone(instant, 'Africa/Kinshasa').day, 5);
      expect(RideTime.inZone(instant, 'Africa/Lubumbashi').day, 6);
    });
  });

  group('RideDraft', () {
    final now = DateTime.utc(2026, 11, 11, 12);
    RideDraft make({
      String title = 'Tour du fleuve',
      DateTime? startsAt,
      RideVisibility visibility = RideVisibility.public,
      String? clubId,
      int? max,
      Set<BikeType> bikes = const {BikeType.any},
    }) => RideDraft(
      title: title,
      startsAt: startsAt ?? now.add(const Duration(days: 1)),
      city: 'Kinshasa',
      startLabel: 'Victoire',
      destinationLabel: 'Kinkole',
      visibility: visibility,
      joinPolicy: RideJoinPolicy.open,
      clubId: clubId,
      maxParticipants: max,
      bikeTypes: bikes,
    );

    test('brouillon valide', () {
      expect(make().validate(now: now, publishing: true), isEmpty);
    });

    test('erreurs de saisie (miroir des contraintes SQL)', () {
      expect(make(title: 'Ab').validate(now: now), [RideDraftIssue.title]);
      expect(make(max: 1).validate(now: now), [RideDraftIssue.maxParticipants]);
      expect(make(visibility: RideVisibility.club).validate(now: now), [
        RideDraftIssue.club,
      ]);
      expect(make(clubId: 'c1').validate(now: now), [RideDraftIssue.club]);
      expect(make(bikes: {}).validate(now: now), [RideDraftIssue.bikeTypes]);
    });

    test('publication : date passée refusée, brouillon accepté', () {
      final past = make(startsAt: now.subtract(const Duration(hours: 1)));
      expect(past.validate(now: now), isEmpty);
      expect(past.validate(now: now, publishing: true), [
        RideDraftIssue.startInPast,
      ]);
    });

    test('n\'envoie que les colonnes modifiables', () {
      final json = make().toUpdateJson();
      for (final forbidden in [
        'status',
        'organizer_id',
        'club_id',
        'participant_count',
        'joins_locked',
      ]) {
        expect(json.keys, isNot(contains(forbidden)));
      }
      expect(json['open_to_non_members'], isFalse);
    });
  });

  test('Ride.fromJson lit une ligne PostgREST avec relations', () {
    final ride = Ride.fromJson({
      'id': 'r1',
      'title': 'Lubumbashi – Likasi',
      'organizer_id': 'u1',
      'club_id': 'c1',
      'starts_at': '2026-12-05T06:00:00+00:00',
      'timezone': 'Africa/Lubumbashi',
      'city': 'Lubumbashi',
      'start_label': 'Poste',
      'destination_label': 'Likasi',
      'visibility': 'club',
      'join_policy': 'approval',
      'status': 'in_progress',
      'joins_locked': true,
      'difficulty': 'hard',
      'recommended_bike_types': ['trail', 'inconnu'],
      'max_participants': 10,
      'participant_count': 10,
      'clubs': {'name': 'Lions'},
      'organizer': {'display_name': 'Alice'},
    });
    expect(ride.startsAt, DateTime.utc(2026, 12, 5, 6));
    expect(ride.clubName, 'Lions');
    expect(ride.organizerName, 'Alice');
    expect(ride.bikeTypes, [BikeType.trail]);
    expect(ride.isFull, isTrue);
    expect(ride.acceptsParticipants, isFalse);
  });

  test('la recherche neutralise la syntaxe de filtre PostgREST', () {
    expect(
      SupabaseRidesRepository.sanitizeQuery('kin,status.eq.draft'),
      'kin status eq draft',
    );
  });
}
