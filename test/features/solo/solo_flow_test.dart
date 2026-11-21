import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/solo/domain/solo.dart';

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

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

const names = {'alice': 'Alice', 'bob': 'Bob', 'carol': 'Carol'};

void main() {
  testWidgets('sans proche : on ajoute un motard qui devra accepter', (
    tester,
  ) async {
    final solo = FakeSoloRepository(names: names);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      solo: solo,
    );
    await go(tester, container, AppRoutes.home);
    await tapKey(tester, 'shortcut-solo');
    expect(find.text('Mode solo'), findsWidgets);
    expect(find.byKey(const Key('solo-add-contact')), findsOneWidget);

    await tapKey(tester, 'solo-add-contact');
    await tester.enterText(find.byKey(const Key('solo-contact-search')), 'bo');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapKey(tester, 'solo-hit-bob');
    expect(solo.calls, ['request:bob']);
    expect(find.text('En attente de réponse'), findsOneWidget);
  });

  testWidgets('départ, « je vais bien », position, puis « je suis arrivé »', (
    tester,
  ) async {
    final solo = FakeSoloRepository(names: names)..addAccepted('bob');
    final location = FakeLocationService();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      solo: solo,
      location: location,
    );
    await go(tester, container, AppRoutes.solo);
    await tapKey(tester, 'solo-start');
    expect(find.text('Choisissez au moins un proche.'), findsOneWidget);

    await tapKey(tester, 'solo-watcher-bob');
    await tapKey(tester, 'solo-minutes-45');
    await tester.enterText(find.byKey(const Key('solo-destination')), 'Maison');
    await tapKey(tester, 'solo-start');
    expect(solo.calls.last, 'start:bob:45:false:Maison');
    expect(find.text('Trajet solo vers : Maison'), findsOneWidget);
    expect(find.text('Suivi par Bob'), findsOneWidget);

    await tapKey(tester, 'solo-ok');
    expect(solo.calls.last, 'ok:15');
    await tapKey(tester, 'solo-send-position');
    expect(solo.calls.last, 'send:-4.3217,15.3125');
    expect(find.text('Position envoyée à vos proches.'), findsOneWidget);

    await tapKey(tester, 'solo-arrived');
    expect(solo.calls.last, 'arrive');
    expect(
      find.text('Bien arrivé ! Vos proches sont prévenus.'),
      findsOneWidget,
    );
    // Le trajet est fini : on peut repartir.
    expect(find.byKey(const Key('solo-start')), findsOneWidget);
  });

  testWidgets('position partagée : envoyée pendant le trajet', (tester) async {
    final solo = FakeSoloRepository(names: names)..addAccepted('bob');
    final location = FakeLocationService();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      solo: solo,
      location: location,
    );
    await go(tester, container, AppRoutes.solo);
    await tapKey(tester, 'solo-watcher-bob');
    await tapKey(tester, 'solo-share');
    await tapKey(tester, 'solo-start');
    expect(solo.calls.last, 'start:bob:30:true:null');
    location.emit(-4.30, 15.30);
    await tester.pumpAndSettle();
    expect(solo.calls, contains('location:-4.3,15.3'));

    await tapKey(tester, 'solo-cancel');
    await tester.tap(find.byKey(const Key('solo-cancel-confirm')));
    await tester.pumpAndSettle();
    expect(solo.calls.last, 'cancel');
  });

  testWidgets('le proche voit le retard et demande des nouvelles', (
    tester,
  ) async {
    final solo = FakeSoloRepository(names: names);
    final now = DateTime.now().toUtc();
    solo.tripList.add(
      SoloTrip(
        id: 'trip-bob',
        userId: 'bob',
        displayName: 'Bob',
        mine: false,
        status: SoloTripStatus.active,
        startedAt: now.subtract(const Duration(hours: 1)),
        expectedAt: now.subtract(const Duration(minutes: 20)),
        shareLocation: true,
        destination: 'Maison',
        lastLat: -4.31,
        lastLng: 15.29,
        lastPositionAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    final actions = FakeExternalActions();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      solo: solo,
      actions: actions,
    );
    await go(tester, container, AppRoutes.home);
    expect(find.byKey(const Key('solo-watched-trip-bob')), findsOneWidget);
    await tapKey(tester, 'solo-watched-trip-bob');
    expect(find.textContaining('Pas encore arrivé (prévu à'), findsOneWidget);
    await tapKey(tester, 'solo-ask-news');
    expect(solo.calls.last, 'ask:news');
    expect(find.text('Demande envoyée.'), findsOneWidget);
    await tapKey(tester, 'solo-ask-position');
    expect(solo.calls.last, 'ask:position');
    await tapKey(tester, 'solo-open-map');
    expect(actions.maps, ['-4.31,15.29']);
    await tapKey(tester, 'solo-call-emergency');
    expect(actions.dialed, ['112']);
  });

  testWidgets('demande de proche acceptée depuis la cloche', (tester) async {
    final solo = FakeSoloRepository(names: names);
    solo.contactList.add(
      const SoloContact(
        id: 'c-bob',
        userId: 'bob',
        displayName: 'Bob',
        accepted: false,
        incoming: true,
      ),
    );
    final notifications = FakeNotificationsRepository()
      ..add(
        'solo_contact_request',
        actorId: 'bob',
        actorName: 'Bob',
        refId: 'c-bob',
        actionable: true,
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      solo: solo,
      notifications: notifications,
    );
    await go(tester, container, AppRoutes.notifications);
    expect(
      find.text('Bob vous demande de suivre ses trajets en mode solo'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('notif-accept-n-1')));
    await tester.pumpAndSettle();
    expect(solo.calls, ['respond:c-bob:true']);
  });
}
