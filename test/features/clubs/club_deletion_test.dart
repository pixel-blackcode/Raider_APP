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

void main() {
  testWidgets('club vérifié : demande motivée, bandeau, annulation', (
    tester,
  ) async {
    final clubs = FakeClubsRepository(currentUserId: alice.id);
    final club = clubs.addClub(
      name: 'Phoenix Riders',
      ownerId: alice.id,
      verified: true,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      clubs: clubs,
    );
    await go(tester, container, AppRoutes.club(club.id));
    await tester.tap(find.byKey(const Key('club-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('club-menu-delete')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Le club arrête ses activités',
    );
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(
      clubs.calls,
      contains('requestDeletion:Le club arrête ses activités'),
    );
    expect(clubs.clubs.containsKey(club.id), isTrue, reason: 'pas supprimé');

    final banner = find.byKey(const Key('club-deletion-pending'));
    await tester.scrollUntilVisible(banner, 200);
    expect(find.text('« Le club arrête ses activités »'), findsOneWidget);
    await tester.tap(find.byKey(const Key('club-deletion-cancel')));
    await tester.pumpAndSettle();
    expect(clubs.deletions, isEmpty);
  });

  testWidgets('équipe : onglet Suppressions avec la raison', (tester) async {
    final admin = FakeVerificationAdminRepository(isAdmin: true)
      ..deletionItems.add(
        DeletionQueueItem(
          requestId: 'd1',
          clubId: 'c1',
          clubName: 'Phoenix Riders',
          clubCity: 'Kinshasa',
          memberCount: 42,
          requesterName: 'Bob',
          reason: 'Conflit avec les autres admins',
          dueAt: DateTime.utc(2026, 12, 3),
        ),
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      verificationAdmin: admin,
    );
    await go(tester, container, AppRoutes.verificationAdmin);
    await tester.tap(find.byKey(const Key('verification-tab-deletions')));
    await tester.pumpAndSettle();
    expect(find.text('« Conflit avec les autres admins »'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deletion-reject-d1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-dialog-ok')));
    await tester.pumpAndSettle();
    expect(admin.calls, ['reviewDeletion:d1:false']);
  });
}
