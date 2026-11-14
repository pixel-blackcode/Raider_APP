import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/rides/domain/ride.dart';
import 'package:rider_group/features/sos/data/emergency.dart';
import 'package:rider_group/features/sos/data/sos_outbox.dart';
import 'package:rider_group/features/sos/domain/sos.dart';

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
  test('identifiant d’alerte : UUID v4 aléatoire', () {
    final ref = newClientRef(Random(1));
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(ref),
      isTrue,
    );
    expect(newClientRef(), isNot(newClientRef()));
  });

  test('numéro d’urgence : validation', () {
    expect(EmergencyNumberController.isValid('112'), isTrue);
    expect(EmergencyNumberController.isValid('+243810000000'), isTrue);
    expect(EmergencyNumberController.isValid('1'), isFalse);
    expect(EmergencyNumberController.isValid('11a'), isFalse);
  });

  late FakeRidesRepository rides;
  late FakeSosRepository sos;
  late FakeLocationService location;
  late FakeExternalActions actions;

  setUp(() {
    rides = FakeRidesRepository(currentUserId: bob.id, profiles: testProfiles);
    sos = FakeSosRepository(currentUserId: bob.id);
    location = FakeLocationService();
    actions = FakeExternalActions();
  });

  Future<(ProviderContainer, String)> start(
    WidgetTester tester, {
    String me = 'bob',
    RideStatus status = RideStatus.inProgress,
    void Function(String rideId)? seed,
  }) async {
    final ride = rides.addRide(
      title: 'Tour du fleuve',
      organizerId: alice.id,
      status: status,
      others: {bob.id: ParticipantStatus.confirmed},
    );
    rides.currentUserId = me;
    sos.currentUserId = me;
    seed?.call(ride.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(testProfiles[me]!),
      rides: rides,
      location: location,
      sos: sos,
      actions: actions,
    );
    return (container, ride.id);
  }

  Future<void> sendAccident(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('sos-kind-accident')));
    expect(find.text('Envoyer l\'alerte « Accident » ?'), findsOneWidget);
    await tester.tap(find.text('Envoyer l\'alerte'));
    await tester.pumpAndSettle();
  }

  testWidgets('un participant envoie un SOS : confirmation puis transmission', (
    tester,
  ) async {
    final (container, id) = await start(tester);
    await go(tester, container, AppRoutes.ride(id));
    await tapVisible(tester, find.byKey(const Key('ride-open-sos')));

    // Annuler la confirmation n'envoie rien.
    await tapVisible(tester, find.byKey(const Key('sos-kind-breakdown')));
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(sos.calls, isEmpty);

    await sendAccident(tester);
    expect(sos.calls, ['raise:accident']);
    expect(sos.raised.single.position?.lat, -4.3217);
    expect(find.byKey(const Key('sos-status-sent')), findsOneWidget);
    expect(find.textContaining('Alerte transmise à'), findsOneWidget);
    expect(find.text('Pas encore d\'accusé de réception.'), findsOneWidget);

    // Accusé de réception reçu en temps réel.
    sos.addAck(sos.alerts.single.id, alice.id);
    await tester.pumpAndSettle();
    expect(find.text('Vu par : Alice'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('sos-resolved')));
    expect(sos.calls.last, 'close:${sos.alerts.single.id}:resolved');
    expect(find.byKey(const Key('sos-kind-accident')), findsOneWidget);
  });

  testWidgets(
    'critère 12 : une alerte non transmise n’est jamais présentée comme envoyée',
    (tester) async {
      sos.raiseError = const AppException(AppException.network);
      final (container, id) = await start(tester);
      await go(tester, container, AppRoutes.sos(id));
      await sendAccident(tester);

      expect(find.byKey(const Key('sos-status-failed')), findsOneWidget);
      expect(find.text('ALERTE NON TRANSMISE'), findsOneWidget);
      expect(find.textContaining('transmise à'), findsNothing);
      expect(find.byKey(const Key('sos-status-sent')), findsNothing);
      expect(
        container.read(sosOutboxProvider)[id]!.delivery,
        SosDelivery.failed,
      );

      // Le réseau revient : renvoi avec le MÊME identifiant (pas de doublon).
      sos.raiseError = null;
      await tapVisible(tester, find.byKey(const Key('sos-retry')));
      expect(sos.raised, hasLength(2));
      expect(sos.raised[0].clientRef, sos.raised[1].clientRef);
      expect(sos.alerts, hasLength(1));
      expect(find.byKey(const Key('sos-status-sent')), findsOneWidget);
    },
  );

  testWidgets('pendant l’envoi : « pas encore transmise »', (tester) async {
    sos.raiseGate = Completer<void>();
    final (container, id) = await start(tester);
    await go(tester, container, AppRoutes.sos(id));
    await tapVisible(tester, find.byKey(const Key('sos-kind-delay')));
    await tester.tap(find.text('Envoyer l\'alerte'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('sos-status-sending')), findsOneWidget);
    expect(find.textContaining('PAS encore transmise'), findsOneWidget);
    sos.raiseGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-status-sent')), findsOneWidget);
  });

  testWidgets('sans GPS : l’alerte part quand même', (tester) async {
    location.fix = null;
    final (container, id) = await start(tester);
    await go(tester, container, AppRoutes.sos(id));
    await sendAccident(tester);
    expect(sos.raised.single.position, isNull);
    expect(find.byKey(const Key('sos-status-sent')), findsOneWidget);
  });

  testWidgets('destinataire : bandeau, son, accusé de réception, carte', (
    tester,
  ) async {
    late SosAlert alert;
    final (container, id) = await start(
      tester,
      me: 'alice',
      seed: (rideId) => alert = sos.addAlert(
        rideId: rideId,
        userId: bob.id,
        kind: SosKind.breakdown,
        message: 'Pneu crevé',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-banner')), findsOneWidget);
    expect(find.text('SOS : Panne dans votre balade'), findsOneWidget);
    // Le son peut être coupé sans quitter l'application.
    await tester.tap(find.byKey(const Key('sos-banner-mute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-banner-mute')), findsNothing);

    await tester.tap(find.byKey(const Key('sos-banner-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('sos-incoming-${alert.id}')), findsOneWidget);
    expect(find.text('Panne — Bob'), findsOneWidget);
    expect(find.text('« Pneu crevé »'), findsOneWidget);

    await tapVisible(tester, find.byKey(Key('sos-map-${alert.id}')));
    expect(actions.maps, ['-4.33,15.32']);

    await tapVisible(tester, find.byKey(Key('sos-ack-${alert.id}')));
    expect(sos.calls, contains('ack:${alert.id}'));
    expect(find.byKey(Key('sos-acked-${alert.id}')), findsOneWidget);
    // Accusé envoyé : le bandeau disparaît.
    expect(find.byKey(const Key('sos-banner')), findsNothing);

    // L'organisatrice peut marquer l'alerte résolue.
    await tapVisible(tester, find.byKey(Key('sos-resolve-${alert.id}')));
    expect(sos.calls.last, 'close:${alert.id}:resolved');
    expect(find.byKey(Key('sos-incoming-${alert.id}')), findsNothing);
    expect(container, isNotNull);
    expect(id, isNotEmpty);
  });

  testWidgets('on ne reçoit pas de bandeau pour sa propre alerte', (
    tester,
  ) async {
    await start(
      tester,
      seed: (rideId) => sos.addAlert(rideId: rideId, userId: bob.id),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-banner')), findsNothing);
  });

  testWidgets('non-participant : pas de SOS ; hors balade : pas de SOS', (
    tester,
  ) async {
    final (container, id) = await start(tester, me: 'carol');
    await go(tester, container, AppRoutes.sos(id));
    expect(
      find.text('Le SOS est réservé aux participants de la balade en cours.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sos-kind-accident')), findsNothing);
    // L'appel d'urgence reste toujours accessible.
    await tapVisible(tester, find.byKey(const Key('sos-call')));
    expect(actions.dialed, ['112']);
  });

  testWidgets('balade non démarrée : bouton SOS absent de la fiche', (
    tester,
  ) async {
    final (container, id) = await start(tester, status: RideStatus.published);
    await go(tester, container, AppRoutes.ride(id));
    expect(find.byKey(const Key('ride-open-sos')), findsNothing);
    await go(tester, container, AppRoutes.sos(id));
    expect(find.byKey(const Key('sos-kind-accident')), findsNothing);
  });

  testWidgets('numéro d’urgence modifiable dans les Paramètres', (
    tester,
  ) async {
    final (container, id) = await start(tester);
    await go(tester, container, AppRoutes.settings);
    await tapVisible(
      tester,
      find.byKey(const Key('settings-emergency-number')),
    );
    await tester.enterText(find.byKey(const Key('text-dialog-field')), 'abc');
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(
      find.text('Numéro invalide (chiffres uniquement, + autorisé au début).'),
      findsOneWidget,
    );
    await tapVisible(
      tester,
      find.byKey(const Key('settings-emergency-number')),
    );
    await tester.enterText(
      find.byKey(const Key('text-dialog-field')),
      '+243 81 000 0000',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();

    await go(tester, container, AppRoutes.sos(id));
    expect(find.text('Appeler le +243810000000'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('sos-call')));
    expect(actions.dialed, ['+243810000000']);
  });

  testWidgets('le mode Convoi donne accès au SOS', (tester) async {
    final (container, id) = await start(tester);
    await go(tester, container, AppRoutes.convoy(id));
    await tester.tap(find.byKey(const Key('convoy-sos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-kind-accident')), findsOneWidget);
  });
}
