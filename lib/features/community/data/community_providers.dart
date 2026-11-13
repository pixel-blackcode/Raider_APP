import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../domain/community.dart';
import 'community_repository.dart';

/// Fil filtré : tout (null, null), un club, ou un motard.
typedef FeedQuery = ({String? clubId, String? authorId});

const homeFeed = (clubId: null, authorId: null);

final feedProvider = FutureProvider.autoDispose.family<List<Post>, FeedQuery>((
  ref,
  query,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) return const [];
  return repo.feed(clubId: query.clubId, authorId: query.authorId, limit: 30);
});

final postProvider = FutureProvider.autoDispose.family<Post?, String>((
  ref,
  postId,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) return null;
  return repo.post(postId);
});

final postCommentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) async {
      final repo = ref.watch(communityRepositoryProvider);
      if (repo == null) return const [];
      return repo.comments(postId);
    });

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUser>>((
  ref,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) return const [];
  return repo.blockedUsers();
});

final amIModeratorProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) return false;
  return repo.amIModerator();
});

final moderationQueueProvider =
    FutureProvider.autoDispose<List<ModerationItem>>((ref) async {
      final repo = ref.watch(communityRepositoryProvider);
      if (repo == null) return const [];
      return repo.moderationQueue();
    });

final riderProfileProvider = FutureProvider.autoDispose
    .family<Profile?, String>((ref, userId) async {
      final repo = ref.watch(profileRepositoryProvider);
      if (repo == null) return null;
      return repo.fetchProfile(userId);
    });

/// Après une action qui change le contenu visible (publication, blocage,
/// modération), rafraîchit tous les fils affichés.
void refreshCommunity(WidgetRef ref) {
  ref
    ..invalidate(feedProvider)
    ..invalidate(postProvider)
    ..invalidate(postCommentsProvider)
    ..invalidate(blockedUsersProvider)
    ..invalidate(moderationQueueProvider);
}
