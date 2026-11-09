import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/backend/backend_status.dart';
import 'package:rider_group/core/config/app_config.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('démarre sur l\'accueil avec les cinq onglets', (tester) async {
    await pumpRiderGroupApp(tester);

    expect(find.text('Bienvenue sur Rider Group'), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    for (final label in ['Accueil', 'Balades', 'Clubs', 'Messages', 'Profil']) {
      expect(
        find.descendant(of: navBar, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('sans configuration, l\'accueil le signale honnêtement', (
    tester,
  ) async {
    await pumpRiderGroupApp(tester);

    expect(
      find.byKey(const Key('backend-status-not-configured')),
      findsOneWidget,
    );
    expect(find.text('Serveur non configuré'), findsOneWidget);
    expect(find.byKey(const Key('backend-status-ready')), findsNothing);
  });

  testWidgets('backend initialisé : pas de bandeau sur l\'accueil', (
    tester,
  ) async {
    await pumpRiderGroupApp(
      tester,
      backendStatus: const BackendReady(AppEnvironment.development),
    );

    expect(
      find.byKey(const Key('backend-status-not-configured')),
      findsNothing,
    );
  });

  testWidgets('échec d\'initialisation affiché comme tel', (tester) async {
    await pumpRiderGroupApp(
      tester,
      backendStatus: BackendFailed(StateError('boom')),
    );

    expect(find.byKey(const Key('backend-status-failed')), findsOneWidget);
  });

  testWidgets('navigation entre les onglets', (tester) async {
    await pumpRiderGroupApp(tester);
    final navBar = find.byType(NavigationBar);

    final expectations = {
      'Balades': 'Aucune balade pour le moment',
      'Clubs': 'Aucun club pour le moment',
      'Messages': 'Aucune conversation',
      'Profil': 'Vous n\'êtes pas connecté',
    };
    for (final entry in expectations.entries) {
      await tester.tap(
        find.descendant(of: navBar, matching: find.text(entry.key)),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }

    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Accueil')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur Rider Group'), findsOneWidget);
  });

  testWidgets('accès au garage depuis l\'accueil, puis retour', (tester) async {
    await pumpRiderGroupApp(tester);

    await tester.tap(find.byKey(const Key('shortcut-garage')));
    await tester.pumpAndSettle();
    expect(find.text('Votre garage est vide'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur Rider Group'), findsOneWidget);
  });

  testWidgets('la marketplace annonce l\'absence de paiement intégré', (
    tester,
  ) async {
    await pumpRiderGroupApp(tester);

    await tester.tap(find.byKey(const Key('shortcut-marketplace')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune annonce pour le moment'), findsOneWidget);
    expect(
      find.textContaining('Aucun paiement n\'est effectué'),
      findsOneWidget,
    );
  });

  testWidgets('les paramètres changent le thème et le conservent', (
    tester,
  ) async {
    await pumpRiderGroupApp(tester);

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Environnement : dev'), findsOneWidget);

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Sombre'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('une route inconnue affiche la page introuvable', (tester) async {
    final container = await pumpRiderGroupApp(tester);

    container.read(routerProvider).go('/inexistant');
    await tester.pumpAndSettle();
    expect(find.text('Page introuvable'), findsWidgets);

    await tester.tap(find.text('Retour à l\'accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur Rider Group'), findsOneWidget);
    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      AppRoutes.home,
    );
  });

  testWidgets('la racine redirige vers l\'accueil', (tester) async {
    final container = await pumpRiderGroupApp(tester);
    final GoRouter router = container.read(routerProvider);

    router.go(AppRoutes.clubs);
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
  });
}
