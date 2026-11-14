import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/core/geo/point_picker.dart';
import 'package:rider_group/features/convoy/domain/convoy.dart';
import 'package:rider_group/features/rides/domain/ride.dart';
import 'package:rider_group/features/sos/data/emergency.dart';

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
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('format des distances', () {
    expect(formatDistance(850), '850 m');
    expect(formatDistance(12430), '12,4 km');
    expect(formatDistance(152000), '152 km');
  });

  testWidgets(
    'organiser : photo de couverture, départ et arrivée pointés, distance',
    (tester) async {
      final rides = FakeRidesRepository(
        currentUserId: alice.id,
        profiles: testProfiles,
      );
      final media = FakeMediaRepository();
      final picker = FakePhotoPicker(FakePhotoPicker.jpeg());
      final actions = FakeExternalActions();
      // Victoire (Kinshasa) → Kinkole.

      final container = await pumpOnlineApp(
        tester,
        auth: signedInAs(alice),
        rides: rides,
        media: media,
        picker: picker,
        actions: actions,
        extraOverrides: [
          routePickerProvider.overrideWithValue(
            (context, {start, destination}) async => (
              start: const GeoPoint(-4.3317, 15.3139),
              destination: const GeoPoint(-4.3986, 15.5017),
            ),
          ),
        ],
      );
      await go(tester, container, AppRoutes.newRide());

      await tapVisible(tester, find.byKey(const Key('ride-cover-pick')));
      await tester.enterText(
        find.byKey(const Key('ride-field-title')),
        'Kinkole',
      );
      await tester.enterText(
        find.byKey(const Key('ride-field-city')),
        'Kinshasa',
      );
      await tester.enterText(
        find.byKey(const Key('ride-field-start')),
        'Victoire',
      );
      await tester.enterText(
        find.byKey(const Key('ride-field-destination')),
        'Kinkole plage',
      );
      expect(find.byKey(const Key('ride-distance')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('ride-pick-route')));
      expect(find.text('≈ 22,1 km à vol d\'oiseau'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('ride-publish')));
      final draft = rides.lastDraft!;
      expect(draft.startLat, -4.3317);
      expect(draft.destinationLng, 15.5017);
      expect(media.uploads.single, startsWith('ride-media/ride-1/cover-'));
      expect(
        rides.calls,
        contains(startsWith('setCover:ride-1:ride-1/cover-')),
      );

      // Fiche : distance et ouverture des points sur une carte.
      expect(find.byKey(const Key('ride-detail-distance')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('ride-open-start-map')));
      expect(actions.maps, ['-4.3317,15.3139']);
    },
  );

  testWidgets('convoi : itinéraire du chef pour les retardataires', (
    tester,
  ) async {
    final rides = FakeRidesRepository(
      currentUserId: bob.id,
      profiles: testProfiles,
    );
    final ride = rides.addRide(
      title: 'Tour',
      organizerId: alice.id,
      status: RideStatus.inProgress,
      others: {bob.id: ParticipantStatus.confirmed},
    );
    final convoy = FakeConvoyRepository();
    final now = DateTime.now().toUtc();
    convoy.trailPoints.addAll([
      TrailPoint(
        lat: -4.33,
        lng: 15.31,
        recordedAt: now.subtract(const Duration(minutes: 5)),
      ),
      TrailPoint(lat: -4.36, lng: 15.40, recordedAt: now),
    ]);
    final actions = FakeExternalActions();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(bob),
      rides: rides,
      convoy: convoy,
      actions: actions,
    );
    await go(tester, container, AppRoutes.convoy(ride.id));
    expect(find.textContaining('trail:2'), findsOneWidget);
    expect(find.byKey(const Key('convoy-trail')), findsOneWidget);
    await tester.tap(find.byKey(const Key('convoy-trail-open')));
    await tester.pumpAndSettle();
    expect(actions.maps, ['-4.36,15.4']);
    expect(container.read(externalActionsProvider), actions);
  });
}
