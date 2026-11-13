import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/client_ref.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';
import 'community_ui.dart';
import 'post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();
  String _clientRef = newClientRef();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(communityRepositoryProvider)!
          .addComment(widget.postId, text, _clientRef);
      _comment.clear();
      _clientRef = newClientRef();
      ref
        ..invalidate(postCommentsProvider(widget.postId))
        ..invalidate(postProvider(widget.postId))
        ..invalidate(feedProvider);
    } catch (error) {
      // Le texte est conservé : même identifiant au prochain essai.
      if (mounted) {
        showSnack(
          context,
          '${l10n.commentNotSent} ${describeError(context, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = ref.watch(postProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.postTitle)),
      body: AsyncValueView(
        value: post,
        onRetry: () => ref.invalidate(postProvider(widget.postId)),
        data: (p) {
          if (p == null) {
            return EmptyState(
              icon: Icons.visibility_off_outlined,
              title: l10n.postNotFoundTitle,
              message: l10n.postNotFoundBody,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    PostCard(post: p, inDetail: true),
                    SectionHeader(title: l10n.commentsTitle),
                    _Comments(post: p),
                  ],
                ),
              ),
              if (!p.hidden)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('comment-field'),
                            controller: _comment,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 1000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: l10n.commentHint,
                              counterText: '',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton.filled(
                          key: const Key('comment-send'),
                          tooltip: l10n.commentSend,
                          iconSize: 26,
                          constraints: const BoxConstraints(
                            minWidth: 52,
                            minHeight: 52,
                          ),
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Comments extends ConsumerWidget {
  const _Comments({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final media = ref.watch(mediaRepositoryProvider);
    final comments = ref.watch(postCommentsProvider(post.id)).value ?? const [];
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(l10n.commentsEmpty),
      );
    }
    return Column(
      children: [
        for (final c in comments)
          ListTile(
            key: Key('comment-${c.id}'),
            contentPadding: EdgeInsets.zero,
            leading: InkWell(
              onTap: () => context.push(AppRoutes.rider(c.authorId)),
              child: RemoteAvatar(
                label: c.authorName,
                image: media?.imageProvider(
                  MediaBucket.avatars,
                  c.authorAvatar,
                ),
              ),
            ),
            title: Text(
              c.authorName.isEmpty ? l10n.profileHidden : c.authorName,
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.hidden ? l10n.commentHiddenNotice : c.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontStyle: c.hidden ? FontStyle.italic : null,
                  ),
                ),
                Text(
                  timeAgo(l10n, c.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              key: Key('comment-menu-${c.id}'),
              onSelected: (action) async {
                if (action == 'report') {
                  await showReportDialog(
                    context,
                    ref,
                    ReportTarget.comment,
                    c.id,
                  );
                  return;
                }
                try {
                  await ref
                      .read(communityRepositoryProvider)!
                      .deleteComment(c.id);
                  ref
                    ..invalidate(postCommentsProvider(post.id))
                    ..invalidate(feedProvider);
                } catch (error) {
                  if (context.mounted) {
                    showSnack(context, describeError(context, error));
                  }
                }
              },
              itemBuilder: (_) => [
                if (c.authorId == me || post.authorId == me)
                  PopupMenuItem(
                    key: const Key('comment-action-delete'),
                    value: 'delete',
                    child: Text(l10n.actionDelete),
                  ),
                if (c.authorId != me)
                  PopupMenuItem(
                    key: const Key('comment-action-report'),
                    value: 'report',
                    child: Text(l10n.reportAction),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
