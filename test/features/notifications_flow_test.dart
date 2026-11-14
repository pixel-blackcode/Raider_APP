import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/rides/domain/ride.dart';

import '../helpers/fakes.dart';
import '../helpers/signed_in_app.dart';

Future<void> go(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  unawaited(container.read(routerProvider).push(path));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cloche : pastille, son, approbation depuis la notification', (
    tester,
  ) async {
    final rides = FakeRidesRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final ride = rides.addRide(
      title: 'Kinkole',
      organizerId: alice.id,
      joinPolicy: RideJoinPolicy.approval,
      others: {bob.id: ParticipantStatus.pending},
    );
    final notifications = FakeNotificationsRepository();
    final sound = FakeAlertSound();
    await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
      notifications: notifications,
      sound: sound,
    );
    expect(sound.played, isEmpty);

    // Une demande arrive en temps réel : pastille + son.
    notifications.add(
      'ride_join_request',
      actorId: bob.id,
      actorName: 'Bob',
      rideId: ride.id,
      rideTitle: 'Kinkole',
      refId: bob.id,
      actionable: true,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('notifications-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(sound.played, ['notification']);

    await tester.tap(find.byKey(const Key('notifications-bell')));
    await tester.pumpAndSettle();
    expect(find.text('Bob demande à rejoindre « Kinkole »'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notif-accept-n-1')));
    await tester.pumpAndSettle();
    expect(rides.calls, contains('decide:bob:true'));
    expect(notifications.calls, contains('markRead:n-1'));
    expect(find.text("C'est fait."), findsOneWidget);
  });

  testWidgets('sons désactivés dans les Paramètres : pas de son', (
    tester,
  ) async {
    final notifications = FakeNotificationsRepository();
    final sound = FakeAlertSound();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      notifications: notifications,
      sound: sound,
    );
    await go(tester, container, AppRoutes.settings);
    await tester.tap(find.byKey(const Key('settings-sounds')));
    await tester.pumpAndSettle();
    notifications.add('post_comment', actorName: 'Carol', postId: 'p1');
    await tester.pumpAndSettle();
    expect(sound.played, isEmpty);
  });

  testWidgets('tout lire ; une notification ouvre la balade', (tester) async {
    final rides = FakeRidesRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final ride = rides.addRide(
      title: 'Tour',
      organizerId: bob.id,
      status: RideStatus.inProgress,
      others: {alice.id: ParticipantStatus.confirmed},
    );
    final notifications = FakeNotificationsRepository()
      ..add(
        'ride_started',
        actorName: 'Bob',
        rideId: ride.id,
        rideTitle: 'Tour',
      )
      ..add('post_reaction', actorName: 'Carol', postId: 'p1');
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
      notifications: notifications,
    );
    await go(tester, container, AppRoutes.notifications);
    expect(
      find.text('« Tour » a démarré : ouvrez le mode Convoi'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('notifications-read-all')));
    await tester.pumpAndSettle();
    expect(notifications.calls, contains('markRead:all'));
    await tester.tap(find.text('« Tour » a démarré : ouvrez le mode Convoi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-detail-title')), findsOneWidget);
  });
}
