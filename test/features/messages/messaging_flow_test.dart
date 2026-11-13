import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/messages/domain/messaging.dart';
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
  late FakeMessagingRepository messaging;

  setUp(() {
    messaging = FakeMessagingRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
  });

  Future<ProviderContainer> start(
    WidgetTester tester, {
    FakeRidesRepository? rides,
  }) => pumpOnlineApp(
    tester,
    auth: signedInAs(alice),
    messaging: messaging,
    rides: rides,
  );

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('boîte de réception : non-lus, lecture, badge', (tester) async {
    final c = messaging.addConversation(otherUserId: bob.id, title: 'Bob');
    messaging.addMessage(c.id, bob.id, 'Tu viens dimanche ?');
    final container = await start(tester);
    // Badge de l'onglet Messages.
    expect(
      find.descendant(
        of: find.byKey(const Key('nav-unread-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await openTab(tester, 'Messages');
    expect(find.byKey(Key('conv-unread-${c.id}')), findsOneWidget);
    expect(find.text('Tu viens dimanche ?'), findsOneWidget);

    await tester.tap(find.byKey(Key('conv-${c.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Tu viens dimanche ?'), findsOneWidget);
    // Lu : le badge disparaît.
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(Key('conv-unread-${c.id}')), findsNothing);
  });

  testWidgets(
    'message non envoyé : jamais affiché envoyé, renvoi sans doublon',
    (tester) async {
      final c = messaging.addConversation(otherUserId: bob.id, title: 'Bob');
      final container = await start(tester);
      await go(tester, container, AppRoutes.chat(c.id));

      messaging.sendError = const AppException(AppException.network);
      await tester.enterText(find.byKey(const Key('chat-field')), 'Salut');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      final ref = messaging.sentRefs.single;
      expect(find.byKey(Key('msg-failed-$ref')), findsOneWidget);
      expect(find.text('Non envoyé — touchez pour réessayer'), findsOneWidget);
      expect(messaging.messages, isEmpty);

      messaging.sendError = null;
      await tester.tap(find.byKey(Key('msg-out-$ref')));
      await tester.pumpAndSettle();
      expect(messaging.sentRefs, [ref, ref]);
      expect(messaging.messages, hasLength(1));
      expect(find.byKey(Key('msg-failed-$ref')), findsNothing);
      expect(find.text('Salut'), findsOneWidget);
    },
  );

  testWidgets('message reçu en temps réel dans la conversation ouverte', (
    tester,
  ) async {
    final c = messaging.addConversation(
      kind: ConversationKind.group,
      title: 'Sortie dimanche',
      memberIds: {bob.id, carol.id},
    );
    final container = await start(tester);
    await go(tester, container, AppRoutes.chat(c.id));
    expect(find.text('Sortie dimanche'), findsOneWidget);
    messaging.addMessage(c.id, carol.id, 'RDV 8h');
    await tester.pumpAndSettle();
    expect(find.text('RDV 8h'), findsOneWidget);
    // Groupe : le nom de l'expéditeur est affiché.
    expect(find.text('Carol'), findsOneWidget);
  });

  testWidgets('nouvelle conversation privée par pseudonyme', (tester) async {
    final container = await start(tester);
    await go(tester, container, AppRoutes.newConversation);
    await tester.enterText(
      find.byKey(const Key('new-conv-username')),
      'nobody',
    );
    await tester.tap(find.byKey(const Key('new-conv-open')));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucun motard visible avec ce pseudonyme.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('new-conv-username')), 'bob');
    await tester.tap(find.byKey(const Key('new-conv-open')));
    await tester.pumpAndSettle();
    expect(messaging.calls, ['openDirect:bob']);
    expect(find.byKey(const Key('chat-field')), findsOneWidget);
  });

  testWidgets('créer un groupe', (tester) async {
    final container = await start(tester);
    await go(tester, container, AppRoutes.newConversation);
    await tester.tap(find.byKey(const Key('new-conv-group-tab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-group-title')), 'Kin MC');
    for (final name in ['bob', 'carol']) {
      await tester.enterText(find.byKey(const Key('new-conv-username')), name);
      await tester.tap(find.byKey(const Key('new-group-add')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('new-group-create')));
    await tester.pumpAndSettle();
    expect(messaging.calls, ['createGroup:Kin MC:bob,carol']);
    expect(find.byKey(const Key('chat-field')), findsOneWidget);
  });

  testWidgets('discussion de balade depuis la fiche', (tester) async {
    final rides = FakeRidesRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final ride = rides.addRide(
      title: 'Tour du fleuve',
      organizerId: bob.id,
      others: {alice.id: ParticipantStatus.confirmed},
    );
    final container = await start(tester, rides: rides);
    await go(tester, container, AppRoutes.ride(ride.id));
    await tapVisible(tester, find.byKey(const Key('ride-open-chat')));
    expect(messaging.calls, ['openRide:${ride.id}']);
    expect(find.byKey(const Key('chat-field')), findsOneWidget);
  });

  testWidgets('pas de discussion pour un non-participant', (tester) async {
    final rides = FakeRidesRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final ride = rides.addRide(title: 'Tour', organizerId: bob.id);
    final container = await start(tester, rides: rides);
    await go(tester, container, AppRoutes.ride(ride.id));
    expect(find.byKey(const Key('ride-open-chat')), findsNothing);
  });

  testWidgets('conversation avec un motard bloqué : écriture impossible', (
    tester,
  ) async {
    final c = messaging.addConversation(
      otherUserId: bob.id,
      title: 'Bob',
      blocked: true,
    );
    final container = await start(tester);
    await go(tester, container, AppRoutes.chat(c.id));
    expect(find.byKey(const Key('chat-blocked')), findsOneWidget);
    expect(find.byKey(const Key('chat-field')), findsNothing);
  });
}
