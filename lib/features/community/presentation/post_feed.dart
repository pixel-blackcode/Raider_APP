import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/community_providers.dart';
import 'post_card.dart';

/// Liste de publications à insérer dans un écran défilant.
class PostFeed extends ConsumerWidget {
  const PostFeed({super.key, required this.query, this.emptyMessage});

  final FeedQuery query;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(feedProvider(query));
    return feed.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) =>
          InfoCard(icon: Icons.cloud_off, message: l10n.feedLoadError),
      data: (posts) => posts.isEmpty
          ? InfoCard(
              icon: Icons.forum_outlined,
              message: emptyMessage ?? l10n.homeNoPosts,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in posts) PostCard(key: ValueKey(p.id), post: p),
              ],
            ),
    );
  }
}

/// Version « sliver » du fil, pour un CustomScrollView : chaque publication
/// est construite à la demande (fil long sans à-coups ni surconsommation).
class PostSliverFeed extends ConsumerWidget {
  const PostSliverFeed({super.key, required this.query, this.emptyMessage});

  final FeedQuery query;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(feedProvider(query));
    // Pendant un rafraîchissement, la liste précédente reste affichée.
    final posts = feed.value;
    if (posts == null) {
      return SliverToBoxAdapter(
        child: feed.hasError
            ? InfoCard(icon: Icons.cloud_off, message: l10n.feedLoadError)
            : const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
      );
    }
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: InfoCard(
          icon: Icons.forum_outlined,
          message: emptyMessage ?? l10n.homeNoPosts,
        ),
      );
    }
    return SliverList.builder(
      itemCount: posts.length,
      itemBuilder: (context, i) =>
          PostCard(key: ValueKey(posts[i].id), post: posts[i]),
    );
  }
}
