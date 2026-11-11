import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/rides/domain/ride.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openRide(
  WidgetTester tester,
  ProviderContainer container,
  String rideId,
) async {
  unawaited(container.read(routerProvider).push(AppRoutes.ride(rideId)));
  await tester.pumpAndSettle();
}

FakeRidesRepository ridesFor(String userId) =>
    FakeRidesRepository(currentUserId: userId, profiles: testProfiles);

Future<void> fillRideForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('ride-field-title')),
    'Tour du fleuve',
  );
  await tester.enterText(find.byKey(const Key('ride-field-city')), 'Kinshasa');
  await tester.enterText(
    find.byKey(const Key('ride-field-start')),
    'Rond-point Victoire',
  );
  await tester.enterText(
    find.byKey(const Key('ride-field-destination')),
    'Kinkole',
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('organiser et publier une balade', (tester) async {
    final rides = ridesFor(alice.id);
    await pumpOnlineApp(tester, auth: signedInAs(alice), rides: rides);
    await openTab(tester, 'Balades');

    await tester.tap(find.byKey(const Key('rides-create')));
    await tester.pumpAndSettle();

    // Validation locale : rien n'est envoyé.
    await tapVisible(tester, find.byKey(const Key('ride-publish')));
    expect(find.text('Entre 3 et 100 caractères'), findsOneWidget);
    expect(rides.calls, isEmpty);

    await fillRideForm(tester);
    await tapVisible(tester, find.byKey(const Key('ride-join-approval')));
    await tapVisible(tester, find.byKey(const Key('ride-difficulty-hard')));
    await tapVisible(tester, find.byKey(const Key('ride-bike-trail')));
    await tester.enterText(find.byKey(const Key('ride-field-max')), '12');
    await tapVisible(tester, find.byKey(const Key('ride-publish')));

    expect(rides.calls, ['createRide:publish']);
    final draft = rides.lastDraft!;
    expect(draft.joinPolicy, RideJoinPolicy.approval);
    expect(draft.difficulty, RideDifficulty.hard);
    expect(draft.bikeTypes, {BikeType.trail});
    expect(draft.maxParticipants, 12);
    expect(draft.timezone, 'Africa/Kinshasa');
    // Par défaut : demain 08:00 heure de Kinshasa = 07:00 UTC.
    expect(draft.startsAt.toUtc().hour, 7);

    expect(find.byKey(const Key('ride-detail-title')), findsOneWidget);
    expect(find.byKey(const Key('ride-you-organize')), findsOneWidget);
    expect(find.byKey(const Key('ride-action-lock')), findsOneWidget);
    expect(find.byKey(const Key('ride-action-start')), findsOneWidget);
    expect(find.byKey(const Key('ride-action-publish')), findsNothing);
  });

  testWidgets('brouillon puis publication depuis la fiche', (tester) async {
    final rides = ridesFor(alice.id);
    await pumpOnlineApp(tester, auth: signedInAs(alice), rides: rides);
    await openTab(tester, 'Balades');
    await tester.tap(find.byKey(const Key('rides-create')));
    await tester.pumpAndSettle();
    await fillRideForm(tester);
    await tapVisible(tester, find.byKey(const Key('ride-save-draft')));

    expect(rides.calls, ['createRide:draft']);
    expect(find.text('Brouillon'), findsWidgets);
    expect(find.byKey(const Key('ride-invite')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('ride-action-publish')));
    expect(rides.calls.last, 'status:publish');
    expect(find.text('Inscriptions ouvertes'), findsWidgets);
  });

  testWidgets('cycle de vie : verrouiller, démarrer, terminer', (tester) async {
    final rides = ridesFor(alice.id);
    final ride = rides.addRide(title: 'Tour du fleuve', organizerId: alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
    );
    await openRide(tester, container, ride.id);

    await tapVisible(tester, find.byKey(const Key('ride-action-lock')));
    expect(find.text('Verrouillée'), findsWidgets);
    expect(find.byKey(const Key('ride-action-unlock')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('ride-action-start')));
    await tester.tap(find.byKey(const Key('confirm-dialog-ok')));
    await tester.pumpAndSettle();
    expect(find.text('En cours · inscriptions fermées'), findsWidgets);
    // Une balade en cours n'est plus modifiable.
    expect(find.byKey(const Key('ride-edit')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('ride-action-finish')));
    await tester.tap(find.byKey(const Key('confirm-dialog-ok')));
    await tester.pumpAndSettle();
    expect(find.text('Terminée'), findsWidgets);
    expect(
      find.text('La balade est close : plus aucune action n\'est possible.'),
      findsOneWidget,
    );
    expect(rides.calls, ['status:lock', 'status:start', 'status:finish']);
  });

  testWidgets('annulation avec motif', (tester) async {
    final rides = ridesFor(alice.id);
    final ride = rides.addRide(title: 'Tour du fleuve', organizerId: alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
    );
    await openRide(tester, container, ride.id);

    await tapVisible(tester, find.byKey(const Key('ride-action-cancel')));
    await tester.enterText(
      find.byKey(const Key('text-dialog-field')),
      'Pluie annoncée',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(rides.calls, ['status:cancel:Pluie annoncée']);
    expect(find.text('Annulée'), findsWidgets);
  });

  testWidgets('participation libre puis départ', (tester) async {
    final rides = ridesFor(bob.id);
    final ride = rides.addRide(title: 'Tour du fleuve', organizerId: alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
    );
    await openRide(tester, container, ride.id);

    expect(find.byKey(const Key('ride-edit')), findsNothing);
    expect(find.text('Gestion de la balade'), findsNothing);

    await tapVisible(tester, find.byKey(const Key('ride-join')));
    expect(rides.members[ride.id]![bob.id], ParticipantStatus.confirmed);
    expect(find.byKey(const Key('ride-you-participate')), findsOneWidget);
    expect(find.byKey(Key('ride-participant-${bob.id}')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('ride-leave')));
    await tester.tap(find.byKey(const Key('confirm-dialog-ok')));
    await tester.pumpAndSettle();
    expect(rides.members[ride.id]![bob.id], ParticipantStatus.left);
    expect(find.byKey(const Key('ride-join')), findsOneWidget);
  });

  testWidgets('les trois modes d\'adhésion (acceptation 6)', (tester) async {
    final rides = ridesFor(bob.id);
    final approval = rides.addRide(
      title: 'Sur approbation',
      organizerId: alice.id,
      joinPolicy: RideJoinPolicy.approval,
    );
    final invite = rides.addRide(
      title: 'Sur invitation',
      organizerId: alice.id,
      joinPolicy: RideJoinPolicy.inviteOnly,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
    );

    await openRide(tester, container, invite.id);
    expect(find.byKey(const Key('ride-invite-only')), findsOneWidget);
    expect(find.byKey(const Key('ride-join')), findsNothing);
    expect(find.byKey(const Key('ride-request')), findsNothing);

    await openRide(tester, container, approval.id);
    await tapVisible(tester, find.byKey(const Key('ride-request')));
    await tester.enterText(
      find.byKey(const Key('text-dialog-field')),
      'Je roule en trail',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(rides.members[approval.id]![bob.id], ParticipantStatus.pending);
    expect(find.byKey(const Key('ride-request-pending')), findsOneWidget);
  });

  testWidgets('l\'organisateur approuve une demande', (tester) async {
    final rides = ridesFor(alice.id);
    final ride = rides.addRide(
      title: 'Sur approbation',
      organizerId: alice.id,
      joinPolicy: RideJoinPolicy.approval,
      others: {bob.id: ParticipantStatus.pending},
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
    );
    await openRide(tester, container, ride.id);

    expect(find.byKey(Key('ride-request-${bob.id}')), findsOneWidget);
    await tapVisible(tester, find.byKey(Key('ride-request-approve-${bob.id}')));
    expect(rides.calls, ['decide:bob:true']);
    expect(find.byKey(Key('ride-participant-${bob.id}')), findsOneWidget);
  });

  testWidgets('balade verrouillée ou complète : aucune adhésion proposée '
      '(acceptation 7)', (tester) async {
    final rides = ridesFor(bob.id);
    final locked = rides.addRide(
      title: 'Verrouillée',
      organizerId: alice.id,
      status: RideStatus.locked,
    );
    final runningLocked = rides.addRide(
      title: 'En cours fermée',
      organizerId: alice.id,
      status: RideStatus.inProgress,
      joinsLocked: true,
    );
    final full = rides.addRide(
      title: 'Complète',
      organizerId: alice.id,
      maxParticipants: 2,
      others: {carol.id: ParticipantStatus.confirmed},
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
    );

    for (final ride in [locked, runningLocked]) {
      await openRide(tester, container, ride.id);
      expect(find.byKey(const Key('ride-joins-closed')), findsOneWidget);
      expect(find.byKey(const Key('ride-join')), findsNothing);
    }
    await openRide(tester, container, full.id);
    expect(find.byKey(const Key('ride-full')), findsOneWidget);
    expect(find.byKey(const Key('ride-join')), findsNothing);
  });

  testWidgets('une invitation sur une balade verrouillée est refusée avec un '
      'message clair', (tester) async {
    final rides = ridesFor(bob.id);
    final ride = rides.addRide(
      title: 'Verrouillée',
      organizerId: alice.id,
      status: RideStatus.locked,
    );
    await rides.invite(ride.id, bob.id);
    await pumpOnlineApp(tester, auth: signedInAs(bob), rides: rides);
    await openTab(tester, 'Balades');
    await tester.tap(find.text('Mes balades'));
    await tester.pumpAndSettle();

    final invitation = rides.invitations.single;
    await tapVisible(
      tester,
      find.byKey(Key('ride-invitation-accept-${invitation.id}')),
    );
    expect(
      find.text('Les inscriptions à cette balade sont fermées.'),
      findsOneWidget,
    );
    expect(rides.members[ride.id]![bob.id], isNull);
  });

  testWidgets('retrait d\'un participant', (tester) async {
    final rides = ridesFor(alice.id);
    final ride = rides.addRide(
      title: 'Tour du fleuve',
      organizerId: alice.id,
      others: {bob.id: ParticipantStatus.confirmed},
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      rides: rides,
    );
    await openRide(tester, container, ride.id);

    expect(find.byKey(Key('ride-remove-${alice.id}')), findsNothing);
    await tapVisible(tester, find.byKey(Key('ride-remove-${bob.id}')));
    await tester.tap(find.byKey(const Key('confirm-dialog-ok')));
    await tester.pumpAndSettle();
    expect(rides.calls, ['remove:bob']);
    expect(find.byKey(Key('ride-participant-${bob.id}')), findsNothing);
  });

  testWidgets('un participant retiré voit pourquoi il ne peut pas revenir', (
    tester,
  ) async {
    final rides = ridesFor(bob.id);
    final ride = rides.addRide(
      title: 'Tour du fleuve',
      organizerId: alice.id,
      others: {bob.id: ParticipantStatus.removed},
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
    );
    await openRide(tester, container, ride.id);
    expect(find.byKey(const Key('ride-removed')), findsOneWidget);
    expect(find.byKey(const Key('ride-join')), findsNothing);
  });

  testWidgets('horaire affiché dans le fuseau de la balade', (tester) async {
    final rides = ridesFor(bob.id);
    final ride = rides.addRide(
      title: 'Lubumbashi – Likasi',
      organizerId: alice.id,
      startsAt: DateTime.utc(2030, 12, 5, 6),
      timezone: 'Africa/Lubumbashi',
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
    );
    await openRide(tester, container, ride.id);
    expect(
      find.text('jeudi 5 décembre 2030 · 08:00 (Heure de Lubumbashi (UTC+2))'),
      findsOneWidget,
    );
  });

  testWidgets('balade de club créée depuis la fiche du club', (tester) async {
    final clubs = FakeClubsRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final club = clubs.addClub(name: 'Kin Riders', ownerId: alice.id);
    final rides = ridesFor(alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
      rides: rides,
    );
    unawaited(container.read(routerProvider).push(AppRoutes.club(club.id)));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('club-organize-ride')));
    await fillRideForm(tester);
    expect(
      find.byKey(const Key('ride-field-open-to-non-members')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ride-field-visibility')), findsNothing);
    await tapVisible(
      tester,
      find.byKey(const Key('ride-field-open-to-non-members')),
    );
    await tapVisible(tester, find.byKey(const Key('ride-publish')));

    final draft = rides.lastDraft!;
    expect(draft.clubId, club.id);
    expect(draft.visibility, RideVisibility.club);
    expect(draft.openToNonMembers, isTrue);
  });

  testWidgets('l\'accueil et la fiche club présentent les balades', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final club = clubs.addClub(
      name: 'Kin Riders',
      ownerId: alice.id,
      members: {bob.id: ClubRole.member},
    );
    final rides = ridesFor(bob.id)
      ..addRide(title: 'Tour du fleuve', organizerId: alice.id)
      ..addRide(
        title: 'Sortie du club',
        organizerId: alice.id,
        visibility: RideVisibility.club,
        clubId: club.id,
        clubName: 'Kin Riders',
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      clubs: clubs,
      rides: rides,
    );
    expect(find.text('Tour du fleuve'), findsOneWidget);

    unawaited(container.read(routerProvider).push(AppRoutes.club(club.id)));
    await tester.pumpAndSettle();
    expect(find.text('Balades du club'), findsOneWidget);
    expect(find.text('Sortie du club'), findsOneWidget);
    // Un simple membre ne peut pas organiser au nom du club.
    expect(find.byKey(const Key('club-organize-ride')), findsNothing);
  });

  testWidgets('recherche et filtre de difficulté', (tester) async {
    final rides = ridesFor(bob.id)
      ..addRide(title: 'Tour du fleuve', organizerId: alice.id)
      ..addRide(title: 'Route de Matadi', organizerId: alice.id);
    await pumpOnlineApp(tester, auth: signedInAs(bob), rides: rides);
    await openTab(tester, 'Balades');
    expect(find.text('Tour du fleuve'), findsOneWidget);
    expect(find.text('Route de Matadi'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('rides-search')), 'matadi');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Tour du fleuve'), findsNothing);
    expect(find.text('Route de Matadi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rides-filter-expert')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune balade à venir'), findsOneWidget);
  });
}
