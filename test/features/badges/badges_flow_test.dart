import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/badges/domain/badges.dart';

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

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

FakeBadgesRepository sampleBadges() {
  final now = DateTime.now();
  return FakeBadgesRepository()
    ..mine.addAll([
      RiderBadge(
        code: 'ride_of_month',
        title: 'Meilleure balade du mois · octobre 2026',
        period: '2026-10',
        earned: true,
        awardedAt: now.toUtc(),
      ),
      RiderBadge(
        code: 'road_1000',
        title: 'Traversée',
        description: 'Une balade de 1 000 km (ex. Kinshasa–Lubumbashi)',
        earned: true,
        awardedAt: now.toUtc(),
      ),
      const RiderBadge(
        code: 'loyal',
        title: 'Fidèle',
        description: '10 balades terminées',
        earned: false,
        progress: 4,
        target: 10,
      ),
    ])
    ..challengeList.addAll([
      Challenge(
        id: 'ch-1',
        title: 'Plus longue balade',
        description: 'Une balade de 1 000 km ce mois-ci',
        metric: 'ride_distance',
        target: 1000,
        startsOn: now.subtract(const Duration(days: 3)),
        endsOn: now.add(const Duration(days: 9)),
        progress: 420,
        completed: false,
      ),
      Challenge(
        id: 'ch-2',
        title: 'Moto en forme',
        description: '',
        metric: 'maintenance',
        target: 1,
        startsOn: now.subtract(const Duration(days: 3)),
        endsOn: now.add(const Duration(days: 9)),
        progress: 1,
        completed: true,
      ),
    ]);
}

void main() {
  testWidgets('profil : mes badges, puis la page des badges et des défis', (
    tester,
  ) async {
    final badges = sampleBadges();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      badges: badges,
    );
    await go(tester, container, AppRoutes.profile);
    expect(
      find.text('Meilleure balade du mois · octobre 2026'),
      findsOneWidget,
    );
    expect(find.text('1 défi en cours'), findsOneWidget);

    await tapKey(tester, 'profile-badges-all');
    expect(find.text('2 obtenus sur 3'), findsOneWidget);
    expect(find.text('Traversée'), findsOneWidget);
    expect(find.byKey(const Key('next-badge-loyal')), findsOneWidget);
    expect(find.text('4/10'), findsOneWidget);

    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    await tapKey(tester, 'profile-challenges');
    expect(find.text('Plus longue balade'), findsOneWidget);
    expect(find.text('420 / 1000 km'), findsOneWidget);
    expect(find.text('RÉUSSI'), findsOneWidget);
  });

  testWidgets('les badges d\'un motard se voient sur son profil', (
    tester,
  ) async {
    final badges = FakeBadgesRepository()
      ..others['bob'] = const [
        RiderBadge(code: 'road_500', title: 'Grand voyageur', earned: true),
        RiderBadge(
          code: 'challenge',
          title: 'Rouler ensemble',
          period: '2026-11',
          earned: true,
        ),
      ];
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      badges: badges,
    );
    await go(tester, container, AppRoutes.rider('bob'));
    expect(find.byKey(const Key('rider-badges')), findsOneWidget);
    expect(find.text('2 badges'), findsOneWidget);
    expect(find.text('Grand voyageur'), findsOneWidget);
    expect(find.text('Rouler ensemble · novembre 2026'), findsOneWidget);
  });

  testWidgets('compte suspendu : bandeau avec la raison', (tester) async {
    final badges = FakeBadgesRepository()
      ..suspension = AccountSuspension(
        reason: 'Annonces frauduleuses',
        until: DateTime.utc(2026, 12, 21, 12),
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      badges: badges,
    );
    await go(tester, container, AppRoutes.profile);
    expect(find.byKey(const Key('suspension-banner')), findsOneWidget);
    expect(find.text('Compte suspendu jusqu\'au 21/12/2026'), findsOneWidget);
    expect(find.text('Raison : Annonces frauduleuses'), findsOneWidget);
  });

  testWidgets('annonce officielle de l\'équipe dans le fil', (tester) async {
    final community =
        FakeCommunityRepository(currentUserId: 'alice', profiles: testProfiles)
          ..addPost(
            authorId: 'carol',
            body: 'Meilleure balade du mois · octobre 2026 : « Kin Lushi »',
            isOfficial: true,
          );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      community: community,
    );
    await go(tester, container, AppRoutes.home);
    expect(find.byKey(const Key('post-official-post-1')), findsOneWidget);
    expect(find.text('Équipe Rider Group'), findsOneWidget);
  });
}
