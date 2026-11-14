import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';

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
  testWidgets('photos d’une publication : grille « +N » et visionneuse', (
    tester,
  ) async {
    final community = FakeCommunityRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final post = community.addPost(
      authorId: bob.id,
      mediaPaths: [for (var i = 0; i < 7; i++) 'bob/p$i.jpg'],
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      community: community,
    );
    await go(tester, container, AppRoutes.post(post.id));
    // 4 vignettes au plus, la dernière indique les photos restantes.
    expect(find.byKey(Key('post-photo-${post.id}-3')), findsOneWidget);
    expect(find.byKey(Key('post-photo-${post.id}-4')), findsNothing);
    expect(find.text('+3'), findsOneWidget);

    await tester.tap(find.byKey(Key('post-photo-${post.id}-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    expect(find.text('2 / 7'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('3 / 7'), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
  });

  testWidgets('nouveau message : motard trouvé malgré une faute', (
    tester,
  ) async {
    final messaging = FakeMessagingRepository(
      currentUserId: alice.id,
      profiles: testProfiles,
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      messaging: messaging,
    );
    await go(tester, container, AppRoutes.newConversation);
    await tester.enterText(find.byKey(const Key('new-conv-username')), 'car');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rider-hit-carol')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rider-hit-carol')));
    await tester.pumpAndSettle();
    expect(messaging.calls, ['openDirect:carol']);
    expect(find.byKey(const Key('chat-field')), findsOneWidget);
  });
}
