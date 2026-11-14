import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/clubs/domain/club.dart';
import 'package:rider_group/features/profile/domain/profile.dart';

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
  testWidgets('motard : demande de vérification sans prix ni paiement', (
    tester,
  ) async {
    final profiles = FakeProfileRepository(testProfiles.values);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: profiles,
    );
    await go(tester, container, AppRoutes.profile);
    final cta = find.byKey(const Key('profile-request-verification'));
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();
    for (final word in ['prix', 'paiement', 'payer', r'$']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    expect(find.byKey(const Key('verification-official-name')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('verification-contact-name')),
      'Alice Mbuyi',
    );
    await tester.enterText(
      find.byKey(const Key('verification-phone')),
      '+243 81 234 5678',
    );
    final submit = find.byKey(const Key('verification-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(profiles.verificationForms.single.realName, 'Alice Mbuyi');
    expect(profiles.verificationForms.single.contactPhone, '+243812345678');
    expect(find.text('Demande en cours d\'examen'), findsOneWidget);
  });

  testWidgets('badge bleu sur un motard vérifié', (tester) async {
    final verified = Profile(
      id: 'bob',
      username: 'bob',
      displayName: 'Bob',
      verifiedAt: DateTime(2026),
      verifiedUntil: DateTime.now().add(const Duration(days: 200)),
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: FakeProfileRepository([alice, verified, carol]),
    );
    await go(tester, container, AppRoutes.rider('bob'));
    expect(find.byKey(const Key('rider-verified-badge')), findsOneWidget);
  });

  testWidgets('équipe : onglet Motards, validation', (tester) async {
    final admin = FakeVerificationAdminRepository(isAdmin: true)
      ..riderItems.add(
        RiderVerificationQueueItem(
          requestId: 'r-1',
          userId: 'bob',
          username: 'bob',
          displayName: 'Bob',
          realName: 'Bob Kabila',
          contactPhone: '+243810000000',
          createdAt: DateTime.utc(2026, 11, 14),
        ),
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      verificationAdmin: admin,
    );
    await go(tester, container, AppRoutes.verificationAdmin);
    await tester.tap(find.byKey(const Key('verification-tab-riders')));
    await tester.pumpAndSettle();
    expect(find.text('Nom réel : Bob Kabila'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rider-verification-approve-r-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('verification-duration-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(admin.calls, ['reviewRider:r-1:true:true']);
  });

  testWidgets('création d’un regroupement', (tester) async {
    final clubs = FakeClubsRepository(currentUserId: 'alice');
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
    );
    await go(tester, container, AppRoutes.newClub);
    await tester.tap(find.text('Regroupement'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('club-field-name')),
      'Motards de Gombe',
    );
    await tester.enterText(
      find.byKey(const Key('club-field-city')),
      'Kinshasa',
    );
    final create = find.text('Créer le regroupement');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(clubs.clubs.values.single.isRegroupement, isTrue);
    expect(find.byKey(const Key('club-kind-regroupement')), findsOneWidget);
  });
}
