import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/profile/domain/profile.dart';
import 'package:rider_group/features/shops/domain/shop.dart';

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

final verifiedAlice = Profile(
  id: 'alice',
  username: 'alice',
  displayName: 'Alice',
  verifiedAt: DateTime(2026),
  verifiedUntil: DateTime.now().add(const Duration(days: 200)),
);

void main() {
  testWidgets('motard non vérifié : invité à se faire vérifier', (
    tester,
  ) async {
    final container = await pumpOnlineApp(tester, auth: signedInAs(alice));
    await go(tester, container, AppRoutes.myShop);
    expect(find.byKey(const Key('shop-get-verified')), findsOneWidget);
    expect(find.byKey(const Key('shop-save')), findsNothing);
  });

  testWidgets('motard vérifié : ouvrir sa boutique', (tester) async {
    final shops = FakeShopsRepository(currentUserId: 'alice');
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: FakeProfileRepository([verifiedAlice, bob, carol]),
      shops: shops,
    );
    await go(tester, container, AppRoutes.myShop);
    // Aucune transaction ni paiement dans l'application.
    for (final w in ['paiement', 'payer', r'$']) {
      expect(find.textContaining(w), findsNothing, reason: w);
    }
    await tester.enterText(
      find.byKey(const Key('shop-field-name')),
      'Moto Pièces Kin',
    );
    await tester.enterText(
      find.byKey(const Key('shop-field-phone')),
      '+243 81 000 0000',
    );
    final save = find.byKey(const Key('shop-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(shops.calls, ['save:Moto Pièces Kin:+243810000000']);
    expect(find.byKey(const Key('shop-name')), findsOneWidget);
    expect(find.byKey(const Key('shop-edit')), findsOneWidget);
  });

  testWidgets('acheteur : boutique, annonces, WhatsApp', (tester) async {
    final shops = FakeShopsRepository(currentUserId: 'alice')
      ..shops['s1'] = const Shop(
        id: 's1',
        ownerId: 'bob',
        ownerName: 'Bob',
        name: 'Bob Motos',
        city: 'Kinshasa',
        phone: '+243810000000',
      );
    final market = FakeMarketplaceRepository(
      currentUserId: 'alice',
      profiles: testProfiles,
    )..add(sellerId: 'bob', title: 'Casque Bob');
    final actions = FakeExternalActions();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      shops: shops,
      marketplace: market,
      actions: actions,
    );
    await go(tester, container, AppRoutes.marketplace);
    await tester.tap(find.byKey(const Key('marketplace-shops')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob Motos'));
    await tester.pumpAndSettle();
    expect(find.text('Casque Bob'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-whatsapp')));
    await tester.pumpAndSettle();
    expect(actions.whatsapp, ['+243810000000']);
  });
}
