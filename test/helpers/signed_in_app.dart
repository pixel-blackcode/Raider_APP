import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/core/backend/backend_status.dart';
import 'package:rider_group/core/config/app_config.dart';
import 'package:rider_group/core/media/media_repository.dart';
import 'package:rider_group/core/media/photo_picker.dart';
import 'package:rider_group/features/auth/data/auth_providers.dart';
import 'package:rider_group/features/auth/domain/auth_session.dart';
import 'package:rider_group/features/clubs/data/clubs_providers.dart';
import 'package:rider_group/features/community/data/community_repository.dart';
import 'package:rider_group/features/convoy/data/convoy_repository.dart';
import 'package:rider_group/features/convoy/data/location_service.dart';
import 'package:rider_group/features/convoy/presentation/convoy_map.dart';
import 'package:rider_group/features/marketplace/data/marketplace_repository.dart';
import 'package:rider_group/features/messages/data/messaging_repository.dart';
import 'package:rider_group/features/profile/data/profile_repository.dart';
import 'package:rider_group/features/profile/domain/profile.dart';
import 'package:rider_group/features/rides/data/rides_providers.dart';
import 'package:rider_group/features/sos/data/emergency.dart';
import 'package:rider_group/features/sos/data/sos_repository.dart';

import 'fakes.dart';
import 'pump_app.dart';

const alice = Profile(id: 'alice', username: 'alice', displayName: 'Alice');
const bob = Profile(id: 'bob', username: 'bob', displayName: 'Bob');
const carol = Profile(id: 'carol', username: 'carol', displayName: 'Carol');

final testProfiles = {
  for (final p in [alice, bob, carol]) p.id: p,
};

/// Lance l'application avec un backend « prêt » simulé par des doublures.
Future<ProviderContainer> pumpOnlineApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeClubsRepository? clubs,
  FakeProfileRepository? profiles,
  FakeMediaRepository? media,
  FakePhotoPicker? picker,
  FakeRidesRepository? rides,
  FakeConvoyRepository? convoy,
  FakeLocationService? location,
  FakeSosRepository? sos,
  FakeExternalActions? actions,
  FakeCommunityRepository? community,
  FakeMessagingRepository? messaging,
  FakeMarketplaceRepository? marketplace,
}) {
  return pumpRiderGroupApp(
    tester,
    backendStatus: const BackendReady(AppEnvironment.development),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      clubsRepositoryProvider.overrideWithValue(
        clubs ??
            FakeClubsRepository(
              currentUserId: auth.currentSession?.userId ?? '',
            ),
      ),
      profileRepositoryProvider.overrideWithValue(
        profiles ?? FakeProfileRepository(testProfiles.values),
      ),
      mediaRepositoryProvider.overrideWithValue(media ?? FakeMediaRepository()),
      ridesRepositoryProvider.overrideWithValue(
        rides ??
            FakeRidesRepository(
              currentUserId: auth.currentSession?.userId ?? '',
              profiles: testProfiles,
            ),
      ),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      convoyRepositoryProvider.overrideWithValue(
        convoy ?? FakeConvoyRepository(),
      ),
      locationServiceProvider.overrideWithValue(
        location ?? FakeLocationService(),
      ),
      sosRepositoryProvider.overrideWithValue(
        sos ??
            FakeSosRepository(currentUserId: auth.currentSession?.userId ?? ''),
      ),
      externalActionsProvider.overrideWithValue(
        actions ?? FakeExternalActions(),
      ),
      communityRepositoryProvider.overrideWithValue(
        community ??
            FakeCommunityRepository(
              currentUserId: auth.currentSession?.userId ?? '',
              profiles: testProfiles,
            ),
      ),
      messagingRepositoryProvider.overrideWithValue(
        messaging ??
            FakeMessagingRepository(
              currentUserId: auth.currentSession?.userId ?? '',
              profiles: testProfiles,
            ),
      ),
      marketplaceRepositoryProvider.overrideWithValue(
        marketplace ??
            FakeMarketplaceRepository(
              currentUserId: auth.currentSession?.userId ?? '',
              profiles: testProfiles,
            ),
      ),
      // La carte native (MapLibre) n'existe pas en test : simple liste.
      convoyMapBuilderProvider.overrideWithValue(
        (members, meId) => Text(
          'map:${members.where((m) => m.position != null).length}',
          key: const Key('convoy-map-fake'),
        ),
      ),
    ],
  );
}

FakeAuthRepository signedInAs(Profile profile) => FakeAuthRepository(
  initial: AuthSession(
    userId: profile.id,
    email: '${profile.username}@test.cd',
  ),
);
