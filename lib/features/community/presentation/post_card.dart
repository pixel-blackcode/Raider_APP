import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';
import 'community_ui.dart';

/// Publication en bloc (style « Vibrant & Block ») : auteur en gras, texte
/// lisible, photos bord à bord, grandes zones de réaction (48 dp).
class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post, this.inDetail = false});

  final Post post;

  /// Sur l'écran de détail : pas de navigation vers soi-même.
  final bool inDetail;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late Post _post = widget.post;
  bool _busy = false;

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) _post = widget.post;
  }

  Future<void> _react(ReactionKind kind) async {
    if (_busy) return;
    final before = _post;
    final next = _post.myReaction == kind ? null : kind;
    setState(() {
      _busy = true;
      _post = _post.withMyReaction(next);
    });
    try {
      await ref.read(communityRepositoryProvider)!.setReaction(_post.id, next);
    } catch (error) {
      if (mounted) {
        setState(() => _post = before);
        showSnack(context, describeError(context, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.postDeleteTitle,
      message: l10n.postDeleteBody,
      confirmLabel: l10n.actionDelete,
    );
    if (!ok || !mounted) return;
    try {
      final paths = await ref
          .read(communityRepositoryProvider)!
          .deletePost(_post.id);
      // Photos effacées ensuite (meilleur effort).
      try {
        await ref
            .read(mediaRepositoryProvider)
            ?.remove(MediaBucket.postMedia, paths);
      } catch (_) {}
      if (!mounted) return;
      refreshCommunity(ref);
      showSnack(context, l10n.postDeleted);
      if (widget.inDetail && context.canPop()) context.pop();
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final me = ref.watch(currentUserIdProvider);
    final media = ref.watch(mediaRepositoryProvider);
    final p = _post;
    final mine = p.authorId == me;

    void openDetail() {
      if (!widget.inDetail) context.push(AppRoutes.post(p.id));
    }

    return Card(
      key: Key('post-${p.id}'),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              0,
              0,
            ),
            child: Row(
              children: [
                InkWell(
                  key: Key('post-author-${p.id}'),
                  onTap: () => context.push(AppRoutes.rider(p.authorId)),
                  customBorder: const CircleBorder(),
                  child: RemoteAvatar(
                    label: p.authorName,
                    radius: 22,
                    image: media?.imageProvider(
                      MediaBucket.avatars,
                      p.authorAvatar,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.authorName.isEmpty
                            ? l10n.profileHidden
                            : p.authorName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: timeAgo(l10n, p.createdAt)),
                            if (p.clubName != null) ...[
                              const TextSpan(text: ' · '),
                              TextSpan(
                                text: p.clubName,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (p.audience == PostAudience.club)
                              TextSpan(
                                text: ' · ${l10n.postAudienceClubShort}',
                              ),
                          ],
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key('post-menu-${p.id}'),
                  onSelected: (action) async {
                    switch (action) {
                      case 'delete':
                        await _delete();
                      case 'report':
                        await showReportDialog(
                          context,
                          ref,
                          ReportTarget.post,
                          p.id,
                        );
                      case 'block':
                        await confirmBlock(
                          context,
                          ref,
                          p.authorId,
                          p.authorName,
                        );
                    }
                  },
                  itemBuilder: (_) => [
                    if (mine)
                      PopupMenuItem(
                        key: const Key('post-action-delete'),
                        value: 'delete',
                        child: Text(l10n.actionDelete),
                      )
                    else ...[
                      PopupMenuItem(
                        key: const Key('post-action-report'),
                        value: 'report',
                        child: Text(l10n.reportAction),
                      ),
                      PopupMenuItem(
                        key: const Key('post-action-block'),
                        value: 'block',
                        child: Text(l10n.blockAction(p.authorName)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (p.hidden)
            Container(
              key: Key('post-hidden-${p.id}'),
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l10n.postHiddenNotice),
            ),
          if (p.body.isNotEmpty)
            InkWell(
              onTap: openDetail,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  p.body,
                  style: theme.textTheme.bodyLarge,
                  maxLines: widget.inDetail ? null : 8,
                  overflow: widget.inDetail ? null : TextOverflow.ellipsis,
                ),
              ),
            ),
          if (p.mediaPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: GestureDetector(
                onTap: openDetail,
                child: _PostPhotos(paths: p.mediaPaths),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                for (final kind in ReactionKind.values)
                  _ReactionButton(
                    key: Key('post-react-${kind.name}-${p.id}'),
                    kind: kind,
                    count: p.reactions[kind] ?? 0,
                    selected: p.myReaction == kind,
                    enabled: !p.hidden,
                    onTap: () => _react(kind),
                  ),
                const Spacer(),
                TextButton.icon(
                  key: Key('post-comments-${p.id}'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  onPressed: widget.inDetail ? null : openDetail,
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text(
                    '${p.commentCount}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    super.key,
    required this.kind,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ReactionKind kind;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      label: kind.label(l10n),
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: selected
              ? BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: 22, color: color),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostPhotos extends ConsumerWidget {
  const _PostPhotos({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget photo(String path) {
      final provider = media?.imageProvider(MediaBucket.postMedia, path);
      final placeholder = ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      );
      if (provider == null) return placeholder;
      return Image(
        image: provider,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    if (paths.length == 1) {
      return AspectRatio(aspectRatio: 4 / 3, child: photo(paths.first));
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [for (final p in paths) photo(p)],
    );
  }
}
