import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/media/media_repository.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/rides/domain/ride.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profil'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mot de passe oublié : message neutre (pas d\'énumération)', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpOnlineApp(tester, auth: auth);

    await tester.tap(find.byKey(const Key('sign-in-forgot')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('forgot-password-email')),
      'inconnu@rider.cd',
    );
    await tester.tap(find.byKey(const Key('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(auth.resetRequests, ['inconnu@rider.cd']);
    expect(find.byKey(const Key('forgot-password-sent')), findsOneWidget);
    expect(find.textContaining('Si un compte correspond'), findsOneWidget);
  });

  testWidgets('lien de réinitialisation : nouveau mot de passe imposé', (
    tester,
  ) async {
    final auth = FakeAuthRepository(accounts: {'alice@test.cd': 'ancien123'});
    await pumpOnlineApp(tester, auth: auth);
    await auth.signIn(email: 'alice@test.cd', password: 'ancien123');
    auth.openRecoveryLink();
    await tester.pumpAndSettle();

    expect(find.text('Nouveau mot de passe'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
    // Pas de bouton « Annuler » pendant une réinitialisation.
    expect(find.text('Annuler'), findsNothing);

    await tester.enterText(find.byKey(const Key('new-password')), 'court');
    await tester.tap(find.byKey(const Key('new-password-submit')));
    await tester.pump();
    expect(auth.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('new-password')),
      'nouveau2026',
    );
    await tester.enterText(
      find.byKey(const Key('new-password-confirm')),
      'nouveau2026',
    );
    await tester.tap(find.byKey(const Key('new-password-submit')));
    await tester.pumpAndSettle();

    expect(auth.accounts['alice@test.cd'], 'nouveau2026');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('préférences de confidentialité enregistrées', (tester) async {
    final profiles = FakeProfileRepository([alice]);
    await pumpOnlineApp(tester, auth: signedInAs(alice), profiles: profiles);
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('privacy-discoverable')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('privacy-invitations')));
    await tester.pumpAndSettle();

    final saved = profiles.settings[alice.id]!;
    expect(saved.discoverable, isFalse);
    expect(saved.allowClubInvitations, isFalse);
    final discoverable = tester.widget<SwitchListTile>(
      find.byKey(const Key('privacy-discoverable')),
    );
    expect(discoverable.value, isFalse);
  });

  testWidgets('photo de profil : envoi, remplacement et retrait', (
    tester,
  ) async {
    final profiles = FakeProfileRepository([alice]);
    final media = FakeMediaRepository();
    final picker = FakePhotoPicker(FakePhotoPicker.jpeg());
    await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: profiles,
      media: media,
      picker: picker,
    );
    await openProfile(tester);

    Future<void> choose(String label) async {
      await tester.tap(find.byKey(const Key('profile-photo-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await choose('Changer la photo');
    expect(media.uploads, ['avatars/alice/avatar-1.jpg']);
    expect(profiles.profiles['alice']!.avatarPath, 'alice/avatar-1.jpg');

    await choose('Changer la photo');
    expect(profiles.profiles['alice']!.avatarPath, 'alice/avatar-2.jpg');
    expect(media.removed, ['avatars/alice/avatar-1.jpg']);

    await choose('Retirer la photo');
    expect(profiles.profiles['alice']!.avatarPath, isNull);
    expect(media.removed.last, 'avatars/alice/avatar-2.jpg');
  });

  testWidgets('photo refusée : format ou taille', (tester) async {
    final media = FakeMediaRepository();
    final picker = FakePhotoPicker(
      PickedImage(bytes: FakePhotoPicker.jpeg().bytes, extension: 'gif'),
    );
    await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: FakeProfileRepository([alice]),
      media: media,
      picker: picker,
    );
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-photo-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer la photo'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Format d\'image non pris en charge'),
      findsOneWidget,
    );

    picker.next = FakePhotoPicker.jpeg(size: 3 * 1024 * 1024);
    await tester.tap(find.byKey(const Key('profile-photo-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer la photo'));
    await tester.pumpAndSettle();
    expect(find.text('Image trop volumineuse.'), findsOneWidget);
    expect(media.uploads, isEmpty);
  });

  testWidgets('suppression de compte bloquée si propriétaire d\'un club '
      'avec membres', (tester) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id)
      ..addClub(
        name: 'Kin Riders',
        ownerId: alice.id,
        members: {bob.id: ClubRole.member},
      );
    final auth = signedInAs(alice);
    await pumpOnlineApp(tester, auth: auth, clubs: clubs);
    await openProfile(tester);
    await tester.tap(find.byKey(const Key('profile-delete-account')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('delete-account-blocked')), findsOneWidget);
    expect(find.textContaining('Kin Riders'), findsOneWidget);
    expect(find.byKey(const Key('delete-account-submit')), findsNothing);
  });

  testWidgets('suppression de compte confirmée', (tester) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id)
      ..addClub(name: 'Solo', ownerId: alice.id);
    final media = FakeMediaRepository();
    final auth = signedInAs(alice);
    await pumpOnlineApp(tester, auth: auth, clubs: clubs, media: media);
    await openProfile(tester);
    await tester.tap(find.byKey(const Key('profile-delete-account')));
    await tester.pumpAndSettle();

    expect(find.textContaining('seront supprimés : Solo'), findsOneWidget);
    FilledButton submit() => tester.widget<FilledButton>(
      find.byKey(const Key('delete-account-submit')),
    );
    expect(submit().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete-account-confirm')),
      'supprimer',
    );
    await tester.pump();
    expect(submit().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('delete-account-submit')));
    await tester.pumpAndSettle();

    expect(media.removedFolders, ['avatars/alice', 'post-media/alice']);
    expect(auth.calls, ['deleteAccount']);
    expect(auth.currentSession, isNull);
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('refus serveur de la suppression : erreur affichée, session '
      'conservée', (tester) async {
    final auth = signedInAs(alice)..deleteError = Exception('réseau');
    await pumpOnlineApp(tester, auth: auth);
    await openProfile(tester);
    await tester.tap(find.byKey(const Key('profile-delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-account-confirm')),
      'SUPPRIMER',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('delete-account-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Une erreur inattendue est survenue.'), findsOneWidget);
    expect(auth.currentSession, isNotNull);
  });

  testWidgets('suppression de compte bloquée par une balade active avec '
      'inscrits', (tester) async {
    final rides =
        FakeRidesRepository(currentUserId: alice.id, profiles: testProfiles)
          ..addRide(
            title: 'Tour du fleuve',
            organizerId: alice.id,
            others: {bob.id: ParticipantStatus.confirmed},
          );
    await pumpOnlineApp(tester, auth: signedInAs(alice), rides: rides);
    await openProfile(tester);
    await tester.tap(find.byKey(const Key('profile-delete-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('delete-account-blocked-rides')),
      findsOneWidget,
    );
    expect(find.textContaining('Tour du fleuve'), findsOneWidget);
    expect(find.byKey(const Key('delete-account-submit')), findsNothing);
  });
}
