import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/messages/data/chat_wallpaper.dart';
import 'package:rider_group/features/profile/domain/profile.dart';
import 'package:rider_group/features/settings/data/feedback_repository.dart';

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
  testWidgets('Paramètres : envoyer un problème à l’équipe', (tester) async {
    final feedback = FakeFeedbackRepository();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      feedback: feedback,
    );
    await go(tester, container, AppRoutes.settings);
    final tile = find.byKey(const Key('settings-feedback'));
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'La carte plante sur mon téléphone',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();
    expect(feedback.sent, ['problem:La carte plante sur mon téléphone']);
  });

  testWidgets('équipe : onglet Retours, marquer traité', (tester) async {
    final feedback = FakeFeedbackRepository()
      ..items.add(
        FeedbackItem(
          id: 'f1',
          kind: FeedbackKind.suggestion,
          message: 'Mode nuit pour la carte',
          createdAt: DateTime.utc(2026, 11, 18),
        ),
      );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      feedback: feedback,
      verificationAdmin: FakeVerificationAdminRepository(isAdmin: true),
    );
    await go(tester, container, AppRoutes.verificationAdmin);
    await tester.ensureVisible(
      find.byKey(const Key('verification-tab-feedback')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('verification-tab-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('Mode nuit pour la carte'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feedback-done-f1')));
    await tester.pumpAndSettle();
    expect(feedback.items, isEmpty);
  });

  testWidgets('confidentialité : qui voit ma photo', (tester) async {
    final profiles = FakeProfileRepository(testProfiles.values);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      profiles: profiles,
    );
    await go(tester, container, AppRoutes.privacySettings);
    await tester.tap(find.text('Mes clubs'));
    await tester.pumpAndSettle();
    expect(
      profiles.settings['alice']?.avatarVisibility,
      AvatarVisibility.clubs,
    );
  });

  testWidgets('conversation : fond d’écran mémorisé', (tester) async {
    final messaging = FakeMessagingRepository(currentUserId: 'alice');
    final id = await messaging.openDirect('bob');
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      messaging: messaging,
    );
    await go(tester, container, AppRoutes.chat(id));
    await tester.tap(find.byKey(const Key('chat-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-wallpaper-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallpaper-night')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-wallpaper')), findsOneWidget);
    final w = container.read(chatWallpaperProvider)[id];
    expect(
      w is PresetWallpaper && w.preset == ChatWallpaperPreset.night,
      isTrue,
    );
  });
}
