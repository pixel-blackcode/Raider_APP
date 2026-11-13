import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/messaging_providers.dart';
import '../domain/messaging.dart';

/// Boîte de réception : conversations privées, de groupe et de balade.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('messages-new'),
        heroTag: null,
        onPressed: () => context.push(AppRoutes.newConversation),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.messagesNew),
      ),
      body: AsyncValueView(
        value: inbox,
        onRetry: () => ref.invalidate(inboxProvider),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.chat_bubble_outline,
                title: l10n.messagesEmptyTitle,
                message: l10n.messagesEmptyBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _ConversationTile(c: list[i]),
              ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.c});

  final ConversationSummary c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = ref.watch(mediaRepositoryProvider);
    final unread = c.unreadCount > 0;
    final leading = switch (c.kind) {
      ConversationKind.direct => RemoteAvatar(
        label: c.title,
        radius: 24,
        image: media?.imageProvider(MediaBucket.avatars, c.otherAvatar),
      ),
      ConversationKind.group => CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: const Icon(Icons.groups),
      ),
      ConversationKind.ride => CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: const Icon(Icons.route),
      ),
    };
    return ListTile(
      key: Key('conv-${c.id}'),
      minVerticalPadding: AppSpacing.sm,
      leading: leading,
      title: Text(
        c.title.isEmpty ? l10n.profileHidden : c.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        c.lastMessage ?? l10n.chatNoMessages,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w700 : null,
          color: unread ? theme.colorScheme.onSurface : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastMessageAt != null)
            Text(
              timeAgo(l10n, c.lastMessageAt!),
              style: theme.textTheme.bodySmall,
            ),
          if (unread)
            Badge(
              key: Key('conv-unread-${c.id}'),
              label: Text('${c.unreadCount}'),
            ),
        ],
      ),
      onTap: () => context.push(AppRoutes.chat(c.id)),
    );
  }
}
