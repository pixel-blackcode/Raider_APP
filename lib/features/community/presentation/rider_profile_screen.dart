import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../messages/data/messaging_repository.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';
import 'community_ui.dart';
import 'post_feed.dart';

/// Profil public d'un motard : identité, publications, message, blocage.
class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(riderProfileProvider(userId));
    final me = ref.watch(currentUserIdProvider);
    final media = ref.watch(mediaRepositoryProvider);
    final blocked =
        ref.watch(blockedUsersProvider).value?.any((b) => b.userId == userId) ??
        false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.riderProfileTitle)),
      body: AsyncValueView(
        value: profile,
        onRetry: () => ref.invalidate(riderProfileProvider(userId)),
        data: (p) {
          if (p == null) {
            return EmptyState(
              icon: Icons.visibility_off_outlined,
              title: l10n.riderNotVisibleTitle,
              message: l10n.riderNotVisibleBody,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  RemoteAvatar(
                    label: p.displayName,
                    radius: 40,
                    image: media?.imageProvider(
                      MediaBucket.avatars,
                      p.avatarPath,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          key: const Key('rider-name'),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text('@${p.username}'),
                        if (p.city != null && p.city!.isNotEmpty)
                          Text(p.city!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (p.bio != null && p.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(p.bio!, style: theme.textTheme.bodyLarge),
              ],
              if (userId != me) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('rider-message'),
                        onPressed: blocked
                            ? null
                            : () async {
                                try {
                                  final id = await ref
                                      .read(messagingRepositoryProvider)!
                                      .openDirect(userId);
                                  if (context.mounted) {
                                    await context.push(AppRoutes.chat(id));
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    showSnack(
                                      context,
                                      describeError(context, error),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.riderSendMessage),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      key: const Key('rider-block'),
                      onPressed: () async {
                        if (blocked) {
                          await ref
                              .read(communityRepositoryProvider)!
                              .unblock(userId);
                          refreshCommunity(ref);
                        } else {
                          await confirmBlock(
                            context,
                            ref,
                            userId,
                            p.displayName,
                          );
                        }
                      },
                      child: Text(
                        blocked ? l10n.unblockAction : l10n.blockShort,
                      ),
                    ),
                    IconButton(
                      key: const Key('rider-report'),
                      tooltip: l10n.reportAction,
                      onPressed: () => showReportDialog(
                        context,
                        ref,
                        ReportTarget.user,
                        userId,
                      ),
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
                ),
              ],
              if (blocked)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(l10n.riderBlockedNotice),
                ),
              SectionHeader(title: l10n.riderPostsTitle),
              PostFeed(
                query: (clubId: null, authorId: userId),
                emptyMessage: l10n.riderNoPosts,
              ),
            ],
          );
        },
      ),
    );
  }
}
