import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/errors/app_exception.dart';
import 'package:rider_group/features/community/domain/community.dart';

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
  late FakeCommunityRepository community;
  late FakeMediaRepository media;
  late FakePhotoPicker picker;
  late FakeMessagingRepository messaging;

  setUp(() {
    community = FakeCommunityRepository(
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
    community.currentUserId = me;
    messaging.currentUserId = me;
    return pumpOnlineApp(
      tester,
      auth: signedInAs(testProfiles[me]!),
      community: community,
      media: media,
      picker: picker,
      messaging: messaging,
    );
  }

  testWidgets('publier depuis l’accueil : texte et photo', (tester) async {
    await start(tester);
    // Fil vide : état vide explicite, aucune donnée fictive.
    expect(find.text('Aucune publication pour le moment.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-new-post')));
    await tester.pumpAndSettle();

    // Rien à publier : message clair, aucun envoi.
    await tester.tap(find.byKey(const Key('post-publish')));
    await tester.pumpAndSettle();
    expect(find.text('Écrivez un texte ou ajoutez une photo.'), findsOneWidget);
    expect(community.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('post-body')),
      'Sortie à Kinkole ce matin',
    );
    picker.next = FakePhotoPicker.jpeg();
    await tester.tap(find.byKey(const Key('post-add-photo')));
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('post-publish')));
    await tester.pumpAndSettle();
    expect(media.uploads.single, startsWith('post-media/alice/post-'));
    expect(community.calls, ['createPost:public:1']);
    expect(find.text('Publication partagée.'), findsOneWidget);
    expect(find.text('Sortie à Kinkole ce matin'), findsOneWidget);
  });

  testWidgets(
    'publication non envoyée : jamais affichée publiée, renvoi sans doublon',
    (tester) async {
      final container = await start(tester);
      await go(tester, container, AppRoutes.newPost());
      await tester.enterText(find.byKey(const Key('post-body')), 'Test');
      picker.next = FakePhotoPicker.jpeg();
      await tester.tap(find.byKey(const Key('post-add-photo')));
      await tester.pumpAndSettle();

      community.createError = const AppException(AppException.network);
      await tester.tap(find.byKey(const Key('post-publish')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Publication NON envoyée.'), findsOneWidget);
      expect(find.text('Publication partagée.'), findsNothing);

      community.createError = null;
      await tester.tap(find.byKey(const Key('post-publish')));
      await tester.pumpAndSettle();
      // Même identifiant d'envoi, photo envoyée une seule fois.
      expect(community.createdRefs, hasLength(2));
      expect(community.createdRefs[0], community.createdRefs[1]);
      expect(media.uploads, hasLength(1));
      expect(find.text('Publication partagée.'), findsOneWidget);
    },
  );

  testWidgets('réagir, commenter, signaler', (tester) async {
    final post = community.addPost(authorId: bob.id, body: 'Pneus neufs !');
    final container = await start(tester);
    await go(tester, container, AppRoutes.post(post.id));

    await tester.tap(find.byKey(Key('post-react-fire-${post.id}')));
    await tester.pumpAndSettle();
    expect(community.calls.last, 'react:${post.id}:fire');
    await tester.tap(find.byKey(Key('post-react-fire-${post.id}')));
    await tester.pumpAndSettle();
    expect(community.calls.last, 'react:${post.id}:null');

    await tester.enterText(find.byKey(const Key('comment-field')), 'Bravo');
    await tester.tap(find.byKey(const Key('comment-send')));
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsOneWidget);

    await tester.tap(find.byKey(Key('post-menu-${post.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-action-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-reason-scam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-send')));
    await tester.pumpAndSettle();
    expect(community.reports, ['post:${post.id}:scam']);
    expect(find.text('Signalement envoyé. Merci.'), findsOneWidget);
  });

  testWidgets('bloquer un auteur : ses publications disparaissent', (
    tester,
  ) async {
    final post = community.addPost(authorId: bob.id, body: 'Post de Bob');
    final container = await start(tester);
    expect(find.text('Post de Bob'), findsOneWidget);

    await tapVisible(tester, find.byKey(Key('post-menu-${post.id}')));
    await tester.tap(find.byKey(const Key('post-action-block')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquer'));
    await tester.pumpAndSettle();
    expect(community.calls, contains('block:bob'));
    expect(find.text('Post de Bob'), findsNothing);

    await go(tester, container, AppRoutes.blockedUsers);
    expect(find.byKey(const Key('blocked-bob')), findsOneWidget);
    await tester.tap(find.byKey(const Key('unblock-bob')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blocked-bob')), findsNothing);
  });

  testWidgets('publication masquée : l’auteur voit la mention', (tester) async {
    final post = community.addPost(authorId: alice.id, hidden: true);
    await start(tester);
    expect(find.byKey(Key('post-hidden-${post.id}')), findsOneWidget);
  });

  testWidgets('publication de club : réservée aux membres', (tester) async {
    final clubPost = community.addPost(
      authorId: bob.id,
      body: 'Réunion du club',
      clubId: 'c1',
      audience: PostAudience.club,
    );
    final container = await start(tester, me: 'carol');
    expect(find.text('Réunion du club'), findsNothing);
    await go(tester, container, AppRoutes.post(clubPost.id));
    expect(find.text('Publication introuvable'), findsOneWidget);

    // Publier dans un club : audience « membres » par défaut.
    await go(tester, container, AppRoutes.newPost(clubId: 'c1'));
    await tester.enterText(find.byKey(const Key('post-body')), 'Hello club');
    await tester.tap(find.byKey(const Key('post-publish')));
    await tester.pumpAndSettle();
    expect(community.calls.last, 'createPost:club:0');
  });

  testWidgets('profil public : publications et message privé', (tester) async {
    community.addPost(authorId: bob.id, body: 'Ma nouvelle moto');
    final container = await start(tester);
    await tapVisible(tester, find.byKey(const Key('post-author-post-1')));
    expect(find.byKey(const Key('rider-name')), findsOneWidget);
    expect(find.text('Ma nouvelle moto'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('rider-message')));
    expect(messaging.calls, ['openDirect:bob']);
    expect(find.byKey(const Key('chat-field')), findsOneWidget);
    expect(container, isNotNull);
  });

  testWidgets('modération : file et décision', (tester) async {
    community.moderators.add(alice.id);
    community.queue.add(
      ModerationItem(
        target: ReportTarget.post,
        targetId: 'post-x',
        reportCount: 3,
        reasons: const [ReportReason.spam],
        lastReportedAt: DateTime.utc(2026, 11, 13),
        preview: 'Achetez maintenant',
        authorName: 'Bob',
      ),
    );
    final container = await start(tester);
    await go(tester, container, AppRoutes.profile);
    await tapVisible(tester, find.byKey(const Key('profile-moderation')));
    expect(find.text('3 signalements'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mod-hide-post-x')));
    await tester.pumpAndSettle();
    expect(community.calls.last, 'moderate:post:post-x:hide');
    expect(find.text('Rien à traiter'), findsOneWidget);
  });

  testWidgets('motard ordinaire : pas d’accès à la modération', (tester) async {
    final container = await start(tester);
    await go(tester, container, AppRoutes.profile);
    expect(find.byKey(const Key('profile-moderation')), findsNothing);
  });
}
