import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/convoy/data/location_service.dart';
import 'package:rider_group/features/convoy/domain/convoy.dart';
import 'package:rider_group/features/rides/domain/ride.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

Future<void> go(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  unawaited(container.read(routerProvider).push(path));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FakeRidesRepository rides;
  late FakeConvoyRepository convoy;
  late FakeLocationService location;

  setUp(() {
    rides = FakeRidesRepository(currentUserId: bob.id, profiles: testProfiles);
    convoy = FakeConvoyRepository();
    location = FakeLocationService();
  });

  Future<(ProviderContainer, String)> openConvoyAs(
    WidgetTester tester, {
    RideStatus status = RideStatus.inProgress,
    String me = 'bob',
  }) async {
    final ride = rides.addRide(
      title: 'Tour du fleuve',
      organizerId: alice.id,
      status: status,
      others: {bob.id: ParticipantStatus.confirmed},
    );
    rides.currentUserId = me;
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(testProfiles[me]!),
      rides: rides,
      convoy: convoy,
      location: location,
    );
    return (container, ride.id);
  }

  testWidgets('un participant ouvre le convoi depuis la balade en cours', (
    tester,
  ) async {
    final (container, id) = await openConvoyAs(tester);
    await go(tester, container, AppRoutes.ride(id));
    await tapVisible(tester, find.byKey(const Key('ride-open-convoy')));
    expect(find.byKey(const Key('convoy-map-fake')), findsOneWidget);
    expect(find.byKey(const Key('convoy-member-alice')), findsOneWidget);
    expect(find.byKey(const Key('convoy-member-bob')), findsOneWidget);
    expect(find.text("Votre position n'est pas partagée."), findsOneWidget);
  });

  testWidgets('pas de bouton convoi tant que la balade n’a pas démarré', (
    tester,
  ) async {
    final (container, id) = await openConvoyAs(
      tester,
      status: RideStatus.published,
    );
    await go(tester, container, AppRoutes.ride(id));
    expect(find.byKey(const Key('ride-open-convoy')), findsNothing);
    await go(tester, container, AppRoutes.convoy(id));
    expect(find.text("La balade n'est pas en cours"), findsOneWidget);
  });

  testWidgets('non-participant : accès refusé, aucune position', (
    tester,
  ) async {
    final (container, id) = await openConvoyAs(tester, me: 'carol');
    await go(tester, container, AppRoutes.convoy(id));
    expect(
      find.text('Le mode Convoi est réservé aux participants confirmés.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('convoy-share-toggle')), findsNothing);
  });

  testWidgets('partage volontaire : consentement, envoi, arrêt', (
    tester,
  ) async {
    final (container, id) = await openConvoyAs(tester);
    await go(tester, container, AppRoutes.convoy(id));
    expect(convoy.calls, isEmpty, reason: 'rien sans action du motard');

    await tapVisible(tester, find.byKey(const Key('convoy-share-toggle')));
    expect(location.permissionRequests, 1);
    expect(convoy.calls, ['setSharing:true']);

    location.emit(-4.32, 15.31, speedMps: 10);
    await tester.pumpAndSettle();
    expect(convoy.published, hasLength(1));
    // Cadence : un second point immédiat n'est pas envoyé.
    location.emit(-4.321, 15.311, speedMps: 10);
    await tester.pumpAndSettle();
    expect(convoy.published, hasLength(1));

    await tapVisible(tester, find.byKey(const Key('convoy-share-toggle')));
    expect(
      convoy.calls,
      contains('setSharing:false'),
      reason: '${convoy.calls}',
    );
    expect(find.text("Votre position n'est pas partagée."), findsOneWidget);
  });

  testWidgets('permission refusée : message clair, aucun envoi', (
    tester,
  ) async {
    location.access = LocationAccess.denied;
    final (container, id) = await openConvoyAs(tester);
    await go(tester, container, AppRoutes.convoy(id));
    await tapVisible(tester, find.byKey(const Key('convoy-share-toggle')));
    expect(find.byKey(const Key('convoy-share-error')), findsOneWidget);
    expect(convoy.calls, isEmpty);
  });

  testWidgets('balade terminée côté serveur : l’envoi s’arrête', (
    tester,
  ) async {
    final (container, id) = await openConvoyAs(tester);
    await go(tester, container, AppRoutes.convoy(id));
    await tapVisible(tester, find.byKey(const Key('convoy-share-toggle')));
    convoy.publishError = const AppException('ride_not_in_progress');
    location.emit(-4.32, 15.31);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('convoy-share-error')), findsOneWidget);
    expect(find.text("Votre position n'est pas partagée."), findsOneWidget);
  });

  testWidgets('alertes : motard éloigné du chef et signal ancien', (
    tester,
  ) async {
    convoy.roleMap[ConvoyRole.leader] = alice.id;
    final now = DateTime.now().toUtc();
    convoy.current = [
      RiderPosition(
        userId: alice.id,
        lat: -4.3217,
        lng: 15.3125,
        recordedAt: now,
      ),
      RiderPosition(userId: bob.id, lat: -4.40, lng: 15.40, recordedAt: now),
    ];
    final (container, id) = await openConvoyAs(tester);
    await go(tester, container, AppRoutes.convoy(id));
    expect(find.textContaining('peut-être séparé'), findsOneWidget);
    expect(find.textContaining('chef de convoi'), findsWidgets);

    convoy.push([
      RiderPosition(
        userId: bob.id,
        lat: -4.32,
        lng: 15.31,
        recordedAt: now.subtract(const Duration(minutes: 10)),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Position ancienne'), findsOneWidget);
  });

  testWidgets('l’organisateur désigne le chef de convoi', (tester) async {
    final (container, id) = await openConvoyAs(tester, me: 'alice');
    await go(tester, container, AppRoutes.ride(id));
    await tapVisible(tester, find.byKey(const Key('ride-convoy-role-bob')));
    await tester.tap(find.text('Nommer chef de convoi').last);
    await tester.pumpAndSettle();
    expect(convoy.calls, contains('setRole:leader:bob'));
  });
}
