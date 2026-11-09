import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

void main() {
  testWidgets('backend prêt et déconnecté : écran de connexion imposé', (
    tester,
  ) async {
    await pumpOnlineApp(tester, auth: FakeAuthRepository());

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('connexion refusée : message clair, aucune navigation', (
    tester,
  ) async {
    await pumpOnlineApp(
      tester,
      auth: FakeAuthRepository(accounts: {'joel@rider.cd': 'moto2026'}),
    );

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();
    expect(find.text('Adresse e-mail invalide'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'joel@rider.cd',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'mauvais1',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Adresse e-mail ou mot de passe incorrect.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('connexion puis déconnexion (acceptation 1 : se reconnecter)', (
    tester,
  ) async {
    final auth = FakeAuthRepository(accounts: {'alice@test.cd': 'moto2026'});
    await pumpOnlineApp(tester, auth: auth);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'alice@test.cd',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'moto2026',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Bienvenue sur Rider Group'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'alice@test.cd',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'moto2026',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('inscription avec confirmation d\'e-mail', (tester) async {
    final auth = FakeAuthRepository(requireConfirmation: true);
    await pumpOnlineApp(tester, auth: auth);

    await tester.tap(find.text('Pas encore de compte ? Créer un compte'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-up-submit')));
    await tester.pump();
    expect(find.text('Entre 1 et 60 caractères'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sign-up-display-name')),
      'Joël',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-username')),
      'Joel_243',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-email')),
      'joel@rider.cd',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-password')),
      'moto2026',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-confirm')),
      'moto2027',
    );
    await tester.tap(find.byKey(const Key('sign-up-submit')));
    await tester.pump();
    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sign-up-confirm')),
      'moto2026',
    );
    await tester.tap(find.byKey(const Key('sign-up-submit')));
    await tester.pumpAndSettle();

    expect(auth.accounts['joel@rider.cd'], 'moto2026');
    expect(find.byKey(const Key('sign-in-notice')), findsOneWidget);
    expect(auth.currentSession, isNull);
  });

  testWidgets('profil : affichage, modification et déconnexion', (
    tester,
  ) async {
    final auth = signedInAs(alice);
    final profiles = FakeProfileRepository([alice]);
    await pumpOnlineApp(tester, auth: auth, profiles: profiles);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('@alice'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-field-display-name')),
      'Alice la motarde',
    );
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(profiles.profiles['alice']!.displayName, 'Alice la motarde');
    expect(find.text('Alice la motarde'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
  });
}
