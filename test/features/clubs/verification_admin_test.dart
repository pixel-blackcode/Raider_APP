import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/clubs/domain/club.dart';

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

VerificationQueueItem request() => VerificationQueueItem(
  requestId: 'req-1',
  clubId: 'club-1',
  clubName: 'Phoenix Riders',
  clubCity: 'Kinshasa',
  officialName: 'Phoenix Riders ASBL',
  contactName: 'Jean Mukendi',
  contactPhone: '+243812345678',
  status: VerificationStatus.pending,
  createdAt: DateTime.utc(2026, 11, 14),
);

void main() {
  testWidgets('équipe : contacter par WhatsApp puis valider pour 1 an', (
    tester,
  ) async {
    final admin = FakeVerificationAdminRepository(isAdmin: true)
      ..items.add(request());
    final actions = FakeExternalActions();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      verificationAdmin: admin,
      actions: actions,
    );
    await go(tester, container, AppRoutes.profile);
    await tester.ensureVisible(
      find.byKey(const Key('profile-verification-admin')),
    );
    await tester.tap(find.byKey(const Key('profile-verification-admin')));
    await tester.pumpAndSettle();
    expect(find.text('Nom officiel : Phoenix Riders ASBL'), findsOneWidget);
    // Aucun prix ni paiement, même dans l'outil de l'équipe.
    for (final word in ['prix', 'paiement', r'$']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }

    await tester.tap(find.byKey(const Key('verification-whatsapp-req-1')));
    await tester.pumpAndSettle();
    expect(actions.whatsapp, ['+243812345678']);

    await tester.tap(find.byKey(const Key('verification-approve-req-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('verification-duration-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(admin.calls, ['review:req-1:true:true']);
    expect(find.text('Aucune demande en attente'), findsOneWidget);
  });

  testWidgets('motard ordinaire : pas d’onglet équipe', (tester) async {
    final container = await pumpOnlineApp(tester, auth: signedInAs(alice));
    await go(tester, container, AppRoutes.profile);
    expect(find.byKey(const Key('profile-verification-admin')), findsNothing);
  });
}
