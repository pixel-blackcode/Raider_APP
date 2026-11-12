import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/features/convoy/domain/convoy.dart';

RiderPosition at(String id, double lat, double lng, DateTime t) =>
    RiderPosition(userId: id, lat: lat, lng: lng, recordedAt: t);

void main() {
  final now = DateTime.utc(2026, 11, 12, 10);

  test('distance haversine : deux points de Kinshasa ≈ 10 km', () {
    final d = ConvoyMath.distanceMeters(-4.3217, 15.3125, -4.2634, 15.2429);
    expect(d, inInclusiveRange(9500, 10500));
    expect(ConvoyMath.distanceMeters(0, 0, 0, 0), 0);
  });

  test('fraîcheur des positions', () {
    expect(ConvoyMath.freshness(now, now), Freshness.live);
    expect(
      ConvoyMath.freshness(now.subtract(const Duration(minutes: 2)), now),
      Freshness.aging,
    );
    expect(
      ConvoyMath.freshness(now.subtract(const Duration(minutes: 5)), now),
      Freshness.stale,
    );
  });

  test(
    'alertes : signal ancien, séparation, tri chef / autres / serre-file',
    () {
      final members = buildConvoy(
        participants: {
          'a': 'Alice',
          'b': 'Bob',
          'c': 'Carol',
          'd': 'Dan',
          'e': 'Eve',
        },
        positions: [
          at('a', -4.3217, 15.3125, now),
          at('b', -4.3220, 15.3130, now), // proche
          at('c', -4.40, 15.40, now), // ~13 km
          at('d', -4.3217, 15.3125, now.subtract(const Duration(minutes: 10))),
        ],
        roles: {ConvoyRole.leader: 'a', ConvoyRole.sweeper: 'b'},
        now: now,
      );
      expect(members.map((m) => m.userId), ['a', 'c', 'd', 'e', 'b']);
      final byId = {for (final m in members) m.userId: m};
      expect(byId['a']!.role, ConvoyRole.leader);
      expect(byId['b']!.alert, isNull);
      expect(byId['c']!.alert, ConvoyAlert.possiblySeparated);
      expect(byId['d']!.alert, ConvoyAlert.staleSignal);
      expect(byId['e']!.position, isNull);
      expect(byId['e']!.alert, isNull);
    },
  );

  test('pas de fausse alerte de séparation si le chef est sans signal', () {
    final members = buildConvoy(
      participants: {'a': 'Alice', 'c': 'Carol'},
      positions: [
        at('a', -4.3217, 15.3125, now.subtract(const Duration(minutes: 10))),
        at('c', -4.40, 15.40, now),
      ],
      roles: {ConvoyRole.leader: 'a'},
      now: now,
    );
    expect(members.firstWhere((m) => m.userId == 'c').alert, isNull);
  });

  test('cadence adaptative', () {
    expect(PublishCadence.intervalFor(), const Duration(seconds: 30));
    expect(
      PublishCadence.intervalFor(speedMps: 5),
      const Duration(seconds: 15),
    );
    expect(
      PublishCadence.intervalFor(speedMps: 20),
      const Duration(seconds: 8),
    );
  });

  test('rôle inconnu ignoré', () {
    expect(ConvoyRole.tryParse('leader'), ConvoyRole.leader);
    expect(ConvoyRole.tryParse('pilot'), isNull);
  });
}
