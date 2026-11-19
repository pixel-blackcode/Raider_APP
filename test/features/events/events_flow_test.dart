import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/geo/point_picker.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/events/domain/moto_event.dart';

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

void main() {
  testWidgets('club vérifié : créer un événement depuis le club', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id);
    final club = clubs.addClub(
      name: 'Phoenix Riders',
      ownerId: alice.id,
      verified: true,
    );
    final events = FakeEventsRepository();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
      events: events,
      extraOverrides: [
        placePickerProvider.overrideWithValue(
          (context, {initial}) async => const GeoPoint(-4.31, 15.29),
        ),
      ],
    );
    await go(tester, container, AppRoutes.club(club.id));
    final create = find.byKey(const Key('club-create-event'));
    await tester.scrollUntilVisible(create, 200);
    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('event-title')),
      'Grand rassemblement',
    );
    await tester.enterText(
      find.byKey(const Key('event-place')),
      'Boulevard du 30 Juin',
    );
    final point = find.byKey(const Key('event-map-point'));
    await tester.ensureVisible(point);
    await tester.tap(point);
    await tester.pumpAndSettle();
    expect(find.text('Lieu pointé sur la carte ✓'), findsOneWidget);
    final submit = find.byKey(const Key('event-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(events.calls, ['create:${club.id}']);
    expect(events.lastDraft?.lat, -4.31);
    expect(find.text('Grand rassemblement'), findsOneWidget);

    await tester.tap(find.byKey(const Key('event-going')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-not-going')), findsOneWidget);
  });

  testWidgets('club non vérifié : pas de création d’événement', (tester) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id);
    final club = clubs.addClub(name: 'Petit Club', ownerId: alice.id);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
    );
    await go(tester, container, AppRoutes.club(club.id));
    expect(find.byKey(const Key('club-create-event')), findsNothing);
  });

  testWidgets('accueil : prochains événements, annulation par l’organisateur', (
    tester,
  ) async {
    final events = FakeEventsRepository()
      ..events['e1'] = MotoEvent(
        id: 'e1',
        clubId: 'c1',
        clubName: 'Phoenix Riders',
        title: 'Salon de la moto',
        startsAt: DateTime.now().toUtc().add(const Duration(days: 5)),
        placeName: 'Palais du peuple',
        city: 'Kinshasa',
        canManage: true,
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      events: events,
    );
    await go(tester, container, AppRoutes.events);
    await tester.tap(find.text('Salon de la moto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-menu-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler l\'événement').last);
    await tester.pumpAndSettle();
    expect(events.calls, ['cancel:e1']);
    expect(find.byKey(const Key('event-cancelled')), findsOneWidget);
  });

  testWidgets('annonce : réactualisation pour un vendeur vérifié', (
    tester,
  ) async {
    final market = FakeMarketplaceRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final l = market.add(
      sellerId: alice.id,
      sellerVerified: true,
      bumpedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      marketplace: market,
    );
    await go(tester, container, AppRoutes.listing(l.id));
    expect(find.byKey(const Key('listing-seller-verified')), findsOneWidget);
    final bump = find.byKey(const Key('listing-bump'));
    await tester.ensureVisible(bump);
    await tester.tap(bump);
    await tester.pumpAndSettle();
    expect(market.calls, contains('bump:${l.id}'));
  });

  test('ordre de découverte : vérifiés d’abord', () {
    // Couvert par search_clubs (SQL) ; ici, le modèle expose isVerified.
    final c = Club(
      id: 'c',
      name: 'n',
      city: 'k',
      visibility: ClubVisibility.public,
      joinPolicy: ClubJoinPolicy.open,
      ownerId: 'o',
      verifiedAt: DateTime(2026),
    );
    expect(c.isVerified, isTrue);
  });
}
