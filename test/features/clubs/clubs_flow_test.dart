import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/clubs/domain/club.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

Future<void> openClubsTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Clubs'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openClub(
  WidgetTester tester,
  ProviderContainer container,
  String clubId,
) async {
  unawaited(container.read(routerProvider).push(AppRoutes.club(clubId)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('créer un club sans approbation (acceptation 3)', (tester) async {
    final clubs = FakeClubsRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    await pumpOnlineApp(tester, auth: signedInAs(alice), clubs: clubs);
    await openClubsTab(tester);
    expect(find.text('Vous n\'avez rejoint aucun club'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clubs-create')));
    await tester.pumpAndSettle();

    // Validation locale.
    await tester.ensureVisible(find.byKey(const Key('club-submit')));
    await tester.tap(find.byKey(const Key('club-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Entre 3 et 80 caractères'), findsOneWidget);
    expect(clubs.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('club-field-name')),
      'Kin Riders',
    );
    await tester.enterText(
      find.byKey(const Key('club-field-city')),
      'Kinshasa',
    );

    // Passer en privé : « adhésion libre » disparaît, le référencement apparaît.
    await tester.tap(find.text('Privé'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-join-open')), findsNothing);
    expect(find.byKey(const Key('club-join-invite_only')), findsOneWidget);
    expect(find.byKey(const Key('club-field-listed')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('club-join-invite_only')));
    await tester.tap(find.byKey(const Key('club-join-invite_only')));
    await tester.ensureVisible(find.byKey(const Key('club-submit')));
    await tester.tap(find.byKey(const Key('club-submit')));
    await tester.pumpAndSettle();

    expect(clubs.calls, ['createClub']);
    final created = clubs.clubs.values.single;
    expect(created.visibility, ClubVisibility.private);
    expect(created.joinPolicy, ClubJoinPolicy.inviteOnly);
    expect(find.byKey(const Key('club-detail-name')), findsOneWidget);
    expect(find.text('Propriétaire'), findsWidgets);
    // Le propriétaire administre le club et peut demander la vérification.
    expect(find.byKey(const Key('club-invite')), findsOneWidget);
    expect(find.byKey(const Key('club-request-verification')), findsOneWidget);
    expect(find.byKey(const Key('club-leave')), findsNothing);
  });

  testWidgets('nom déjà pris : l\'erreur serveur est affichée', (tester) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id)
      ..addClub(name: 'Kin Riders', ownerId: bob.id);
    await pumpOnlineApp(tester, auth: signedInAs(alice), clubs: clubs);
    await openClubsTab(tester);
    await tester.tap(find.byKey(const Key('clubs-create')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('club-field-name')),
      'kin riders',
    );
    await tester.enterText(
      find.byKey(const Key('club-field-city')),
      'Kinshasa',
    );
    await tester.ensureVisible(find.byKey(const Key('club-submit')));
    await tester.tap(find.byKey(const Key('club-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Ce nom de club est déjà pris.'), findsOneWidget);
  });

  testWidgets('découvrir, rechercher et rejoindre un club libre ; '
      'appartenir à plusieurs clubs (acceptation 2)', (tester) async {
    final clubs = FakeClubsRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final kin = clubs.addClub(name: 'Kin Riders', ownerId: alice.id);
    clubs
      ..addClub(
        name: 'Goma Bikers',
        ownerId: carol.id,
        members: {bob.id: ClubRole.member},
      )
      ..addClub(
        name: 'Club masqué',
        ownerId: carol.id,
        visibility: ClubVisibility.private,
        joinPolicy: ClubJoinPolicy.inviteOnly,
        isListed: false,
      );
    await pumpOnlineApp(tester, auth: signedInAs(bob), clubs: clubs);
    await openClubsTab(tester);
    expect(find.text('Goma Bikers'), findsOneWidget);

    await tester.tap(find.text('Découvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Kin Riders'), findsOneWidget);
    expect(find.text('Club masqué'), findsNothing);

    await tester.enterText(find.byKey(const Key('clubs-search')), 'goma');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Kin Riders'), findsNothing);
    expect(find.text('Goma Bikers'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('clubs-search')), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kin Riders'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('club-join')));
    await tester.pumpAndSettle();
    expect(clubs.roles[kin.id]![bob.id], ClubRole.member);
    expect(find.byKey(const Key('club-leave')), findsOneWidget);
    expect(find.textContaining('2 membres'), findsWidgets);

    final memberships = await clubs.myClubs(bob.id);
    expect(memberships.length, 2);
  });

  testWidgets('club sur approbation : demande puis validation par le '
      'propriétaire', (tester) async {
    final clubs = FakeClubsRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final lions = clubs.addClub(
      name: 'Lions',
      ownerId: alice.id,
      visibility: ClubVisibility.private,
      joinPolicy: ClubJoinPolicy.approval,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      clubs: clubs,
    );
    await openClub(tester, container, lions.id);

    // Club privé : membres cachés aux non-membres (acceptation 5).
    expect(
      find.text('La liste des membres est réservée aux membres du club.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('club-request')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('text-dialog-field')),
      'Bonjour',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-request-pending')), findsOneWidget);
    expect(clubs.requests.single.message, 'Bonjour');

    // Le propriétaire voit et approuve la demande.
    clubs.currentUserId = alice.id;
    await tester.pumpWidget(const SizedBox());
    final ownerContainer = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
    );
    await openClub(tester, ownerContainer, lions.id);
    final request = clubs.requests.single;
    expect(find.byKey(Key('club-request-${request.id}')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(Key('club-request-approve-${request.id}')),
    );
    await tester.tap(find.byKey(Key('club-request-approve-${request.id}')));
    await tester.pumpAndSettle();
    expect(clubs.roles[lions.id]![bob.id], ClubRole.member);
    expect(find.byKey(Key('club-member-${bob.id}')), findsOneWidget);
  });

  testWidgets('club sur invitation : pas de bouton d\'adhésion ; '
      'invitation acceptée depuis « Mes clubs »', (tester) async {
    final clubs = FakeClubsRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final secret = clubs.addClub(
      name: 'Secret MC',
      ownerId: alice.id,
      visibility: ClubVisibility.private,
      joinPolicy: ClubJoinPolicy.inviteOnly,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      clubs: clubs,
    );
    await openClub(tester, container, secret.id);
    expect(find.byKey(const Key('club-invite-only')), findsOneWidget);
    expect(find.byKey(const Key('club-join')), findsNothing);
    expect(find.byKey(const Key('club-request')), findsNothing);

    await clubs.invite(secret.id, bob.id);
    container.read(routerProvider).go(AppRoutes.clubs);
    await tester.pumpAndSettle();
    final invitation = clubs.invitations.single;
    expect(find.text('Invitation à rejoindre « Secret MC »'), findsOneWidget);
    await tester.tap(find.byKey(Key('invitation-accept-${invitation.id}')));
    await tester.pumpAndSettle();
    expect(clubs.roles[secret.id]![bob.id], ClubRole.member);
    expect(find.text('Secret MC'), findsOneWidget);
  });

  testWidgets('un simple membre n\'a ni édition ni administration', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final kin = clubs.addClub(
      name: 'Kin Riders',
      ownerId: alice.id,
      members: {bob.id: ClubRole.member, carol.id: ClubRole.member},
      verified: true,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      clubs: clubs,
    );
    await openClub(tester, container, kin.id);

    expect(find.byKey(const Key('club-verified-badge')), findsOneWidget);
    expect(find.byKey(const Key('club-edit')), findsNothing);
    expect(find.byKey(const Key('club-invite')), findsNothing);
    expect(find.byKey(const Key('club-request-verification')), findsNothing);
    expect(find.byKey(Key('club-member-menu-${carol.id}')), findsNothing);

    // Accès direct à l'écran de modification : refusé.
    unawaited(container.read(routerProvider).push(AppRoutes.editClub(kin.id)));
    await tester.pumpAndSettle();
    expect(find.text('Action non autorisée'), findsOneWidget);
  });

  testWidgets(
    'le propriétaire gère les rôles et retire un membre (acceptation 15)',
    (tester) async {
      final clubs = FakeClubsRepository(
        currentUserId: alice.id,
        profiles: testProfiles,
      );
      final kin = clubs.addClub(
        name: 'Kin Riders',
        ownerId: alice.id,
        members: {bob.id: ClubRole.member, carol.id: ClubRole.member},
      );
      final container = await pumpOnlineApp(
        tester,
        auth: signedInAs(alice),
        clubs: clubs,
      );
      await openClub(tester, container, kin.id);

      expect(find.byKey(Key('club-member-menu-${alice.id}')), findsNothing);
      await tester.ensureVisible(find.byKey(Key('club-member-menu-${bob.id}')));
      await tester.tap(find.byKey(Key('club-member-menu-${bob.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Nommer Administrateur'), findsOneWidget);
      expect(find.text('Transférer la propriété'), findsOneWidget);
      await tester.tap(find.text('Nommer Administrateur'));
      await tester.pumpAndSettle();
      expect(clubs.calls, contains('setRole:bob:admin'));

      await tester.ensureVisible(
        find.byKey(Key('club-member-menu-${carol.id}')),
      );
      await tester.tap(find.byKey(Key('club-member-menu-${carol.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer du club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-dialog-ok')));
      await tester.pumpAndSettle();
      expect(clubs.calls, contains('remove:carol'));
      expect(find.byKey(Key('club-member-${carol.id}')), findsNothing);
    },
  );

  testWidgets('invitation par pseudonyme et demande de vérification', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final kin = clubs.addClub(name: 'Kin Riders', ownerId: alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
    );
    await openClub(tester, container, kin.id);

    await tester.tap(find.byKey(const Key('club-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('text-dialog-field')),
      'inconnu',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucun motard trouvé avec ce pseudonyme.'),
      findsOneWidget,
    );
    expect(clubs.calls.where((c) => c.startsWith('invite')), isEmpty);

    await tester.tap(find.byKey(const Key('club-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('text-dialog-field')), 'carol');
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(clubs.calls, contains('invite:carol'));

    await tester.ensureVisible(
      find.byKey(const Key('club-request-verification')),
    );
    await tester.tap(find.byKey(const Key('club-request-verification')));
    await tester.pumpAndSettle();
    // Formulaire : avantages, AUCUN prix ni paiement (règles des stores).
    expect(find.text('Pourquoi faire vérifier votre club ?'), findsOneWidget);
    for (final word in ['prix', 'payer', 'paiement', 'tarif', r'$', 'USD']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    // Validation locale.
    await tester.ensureVisible(find.byKey(const Key('verification-submit')));
    await tester.tap(find.byKey(const Key('verification-submit')));
    await tester.pumpAndSettle();
    expect(clubs.calls, isNot(contains('requestVerification')));
    await tester.enterText(
      find.byKey(const Key('verification-official-name')),
      'Kin Riders ASBL',
    );
    await tester.enterText(
      find.byKey(const Key('verification-contact-name')),
      'Alice Kabila',
    );
    await tester.enterText(
      find.byKey(const Key('verification-phone')),
      '+243 81 234 5678',
    );
    await tester.ensureVisible(find.byKey(const Key('verification-submit')));
    await tester.tap(find.byKey(const Key('verification-submit')));
    await tester.pumpAndSettle();
    expect(clubs.calls, contains('requestVerification'));
    expect(clubs.lastVerificationForm!.contactPhone, '+243812345678');
    expect(find.byKey(const Key('club-verification-pending')), findsOneWidget);
    // Le badge n'apparaît pas tant que l'administration n'a pas validé.
    expect(find.byKey(const Key('club-verified-badge')), findsNothing);
  });

  testWidgets('l\'accueil présente des clubs réels à découvrir', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(currentUserId: bob.id)
      ..addClub(name: 'Kin Riders', ownerId: alice.id);
    await pumpOnlineApp(tester, auth: signedInAs(bob), clubs: clubs);

    expect(find.text('Kin Riders'), findsOneWidget);
    expect(find.text('Aucun club à afficher pour le moment.'), findsNothing);
  });

  testWidgets('le propriétaire ajoute un logo et une couverture', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final kin = clubs.addClub(name: 'Kin Riders', ownerId: alice.id);
    final media = FakeMediaRepository();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
      media: media,
      picker: FakePhotoPicker(FakePhotoPicker.jpeg()),
    );
    unawaited(container.read(routerProvider).push(AppRoutes.editClub(kin.id)));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('club-image-logo')),
        matching: find.text('Choisir'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('club-image-cover')),
        matching: find.text('Choisir'),
      ),
    );
    await tester.pumpAndSettle();

    expect(media.uploads, [
      'club-media/${kin.id}/logo-1.jpg',
      'club-media/${kin.id}/cover-2.jpg',
    ]);
    expect(clubs.images[kin.id]![ClubImageKind.logo], '${kin.id}/logo-1.jpg');
    expect(clubs.images[kin.id]![ClubImageKind.cover], '${kin.id}/cover-2.jpg');
  });
}
