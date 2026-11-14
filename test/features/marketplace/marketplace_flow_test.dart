import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/marketplace/domain/marketplace.dart';

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
  test('format des prix', () {
    expect(formatPrice(80, Currency.usd), '80 \$');
    expect(formatPrice(120000, Currency.cdf), '120 000 FC');
    expect(formatPrice(12.5, Currency.usd), '12,50 \$');
  });

  late FakeMarketplaceRepository market;
  late FakeMediaRepository media;
  late FakePhotoPicker picker;
  late FakeMessagingRepository messaging;

  setUp(() {
    market = FakeMarketplaceRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    media = FakeMediaRepository();
    picker = FakePhotoPicker();
    messaging = FakeMessagingRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
  });

  Future<ProviderContainer> start(WidgetTester tester, {String me = 'alice'}) {
    market.currentUserId = me;
    messaging.currentUserId = me;
    return pumpOnlineApp(
      tester,
      auth: signedInAs(testProfiles[me]!),
      marketplace: market,
      media: media,
      picker: picker,
      messaging: messaging,
    );
  }

  testWidgets('vendre : annonce avec photos, prix indicatif, sans paiement', (
    tester,
  ) async {
    final container = await start(tester);
    await go(tester, container, AppRoutes.marketplace);
    expect(find.byKey(const Key('market-safety')), findsOneWidget);
    await tester.tap(find.byKey(const Key('market-sell')));
    await tester.pumpAndSettle();

    // Validation locale.
    await tapVisible(tester, find.byKey(const Key('listing-submit')));
    expect(find.text('Au moins 3 caractères'), findsOneWidget);
    expect(market.calls, isEmpty);

    picker.next = FakePhotoPicker.jpeg();
    await tester.tap(find.byKey(const Key('listing-add-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Photos (1/10)'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('listing-title')),
      'Casque AGV',
    );
    await tester.enterText(find.byKey(const Key('listing-price-field')), '95');
    await tapVisible(tester, find.byKey(const Key('listing-submit')));

    expect(media.uploads.single, startsWith('listing-media/alice/annonce-'));
    expect(market.calls, ['create:parts:1']);
    expect(find.text('Annonce publiée.'), findsOneWidget);
    expect(find.byKey(const Key('listing-price')), findsOneWidget);
    expect(find.text('95 \$'), findsOneWidget);
    // Ma propre annonce : statut et suppression, pas de contact.
    expect(find.byKey(const Key('listing-contact')), findsNothing);
    expect(find.byKey(const Key('listing-status')), findsOneWidget);
  });

  testWidgets('annonce non envoyée : renvoi sans doublon', (tester) async {
    final container = await start(tester);
    await go(tester, container, AppRoutes.newListing);
    await tester.enterText(find.byKey(const Key('listing-title')), 'Pneu');
    market.createError = const AppException(AppException.network);
    await tapVisible(tester, find.byKey(const Key('listing-submit')));
    expect(find.textContaining('Annonce NON envoyée.'), findsOneWidget);
    market.createError = null;
    await tapVisible(tester, find.byKey(const Key('listing-submit')));
    expect(market.createdRefs, hasLength(2));
    expect(market.createdRefs[0], market.createdRefs[1]);
    expect(find.text('Annonce publiée.'), findsOneWidget);
  });

  testWidgets('chercher, filtrer, favori, contacter le vendeur', (
    tester,
  ) async {
    market
      ..add(
        sellerId: bob.id,
        title: 'Honda CG 125 Phoenix',
        category: ListingCategory.motorcycle,
        price: 950,
      )
      ..add(sellerId: bob.id, title: 'Casque intégral', price: 60)
      ..add(sellerId: bob.id, title: 'Vieux pneu', status: ListingStatus.sold);
    final container = await start(tester);
    await go(tester, container, AppRoutes.marketplace);
    expect(find.text('Honda CG 125 Phoenix'), findsOneWidget);
    expect(find.text('Casque intégral'), findsOneWidget);
    expect(find.text('Vieux pneu'), findsNothing, reason: 'vendue : masquée');

    // Recherche (la tolérance aux fautes est vérifiée en SQL).
    await tester.enterText(find.byKey(const Key('market-search')), 'PHOENIX');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Honda CG 125 Phoenix'), findsOneWidget);
    expect(find.text('Casque intégral'), findsNothing);
    await tester.enterText(find.byKey(const Key('market-search')), '');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Filtre par catégorie.
    await tapVisible(tester, find.byKey(const Key('market-cat-helmet')));
    expect(find.text('Honda CG 125 Phoenix'), findsNothing);
    expect(find.text('Casque intégral'), findsOneWidget);

    await tester.tap(find.text('Casque intégral'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listing-favorite')));
    await tester.pumpAndSettle();
    expect(market.calls, contains('favorite:listing-2:true'));

    await tapVisible(tester, find.byKey(const Key('listing-contact')));
    expect(messaging.calls, ['openDirect:bob']);
    final field = tester.widget<TextField>(find.byKey(const Key('chat-field')));
    expect(field.controller!.text, contains('« Casque intégral »'));
    expect(messaging.sentRefs, isEmpty, reason: 'brouillon, pas envoyé');
  });

  testWidgets('le vendeur marque vendu puis supprime', (tester) async {
    final l = market.add(
      sellerId: alice.id,
      title: 'Gants',
      mediaPaths: ['alice/g.jpg'],
    );
    final container = await start(tester);
    await go(tester, container, AppRoutes.listing(l.id));
    await tapVisible(tester, find.text('Vendu'));
    expect(market.calls, contains('status:${l.id}:sold'));
    await tapVisible(tester, find.byKey(const Key('listing-delete')));
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(market.calls, contains('delete:${l.id}'));
    expect(media.removed, ['listing-media/alice/g.jpg']);
    expect(find.text('Annonce supprimée.'), findsOneWidget);
  });

  testWidgets('signaler une annonce', (tester) async {
    final l = market.add(sellerId: bob.id, title: 'Arnaque ?');
    final community = FakeCommunityRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      marketplace: market,
      community: community,
    );
    await go(tester, container, AppRoutes.listing(l.id));
    await tapVisible(tester, find.byKey(const Key('listing-report')));
    await tester.tap(find.byKey(const Key('report-reason-scam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-send')));
    await tester.pumpAndSettle();
    expect(community.reports, ['listing:${l.id}:scam']);
  });
}
