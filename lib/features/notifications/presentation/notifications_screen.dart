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
import '../../../l10n/generated/app_localizations.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../community/presentation/community_ui.dart';
import '../../rides/data/rides_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

/// Centre de notifications : les demandes et invitations se traitent ici.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (unread > 0)
            TextButton(
              key: const Key('notifications-read-all'),
              onPressed: () async {
                await ref.read(notificationsRepositoryProvider)?.markRead();
                ref.invalidate(notificationsProvider);
              },
              child: Text(l10n.notificationsReadAll),
            ),
        ],
      ),
      body: AsyncValueView(
        value: list,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none,
                title: l10n.notificationsEmptyTitle,
                message: l10n.notificationsEmptyBody,
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _NotificationTile(n: items[i]),
              ),
      ),
    );
  }
}

/// Texte d'une notification selon son type.
String notificationText(AppLocalizations l10n, AppNotification n) {
  final who = n.actorName ?? l10n.profileHidden;
  final ride = n.rideTitle ?? '';
  final club = n.clubName ?? '';
  return switch (n.kind) {
    'ride_join_request' => l10n.notifRideJoinRequest(who, ride),
    'ride_joined' => l10n.notifRideJoined(who, ride),
    'ride_request_approved' => l10n.notifRideRequestApproved(ride),
    'ride_request_rejected' => l10n.notifRideRequestRejected(ride),
    'ride_removed' => l10n.notifRideRemoved(ride),
    'ride_invitation' => l10n.notifRideInvitation(who, ride),
    'ride_locked' => l10n.notifRideLocked(ride),
    'ride_started' => l10n.notifRideStarted(ride),
    'ride_finished' => l10n.notifRideFinished(ride),
    'ride_cancelled' => l10n.notifRideCancelled(ride),
    'club_join_request' => l10n.notifClubJoinRequest(who, club),
    'club_request_approved' => l10n.notifClubRequestApproved(club),
    'club_request_rejected' => l10n.notifClubRequestRejected(club),
    'club_invitation' => l10n.notifClubInvitation(who, club),
    'post_comment' => l10n.notifPostComment(who),
    'post_reaction' => l10n.notifPostReaction(who),
    _ => l10n.notificationsTitle,
  };
}

IconData _icon(String kind) => switch (kind) {
  'post_comment' => Icons.mode_comment_outlined,
  'post_reaction' => Icons.local_fire_department_outlined,
  'ride_cancelled' ||
  'ride_removed' ||
  'ride_request_rejected' ||
  'club_request_rejected' => Icons.cancel_outlined,
  'ride_started' => Icons.navigation_outlined,
  _ when kind.startsWith('club') => Icons.groups_outlined,
  _ => Icons.route_outlined,
};

class _NotificationTile extends ConsumerStatefulWidget {
  const _NotificationTile({required this.n});

  final AppNotification n;

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _busy = false;

  Future<void> _decide(bool yes) async {
    final n = widget.n;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      switch (n.kind) {
        case 'ride_join_request':
          await ref
              .read(ridesRepositoryProvider)!
              .decideRequest(n.rideId!, n.refId!, approve: yes);
          ref.refreshRides(n.rideId);
        case 'ride_invitation':
          await ref
              .read(ridesRepositoryProvider)!
              .respondToInvitation(n.refId!, accept: yes);
          ref.refreshRides(n.rideId);
        case 'club_join_request':
          await ref
              .read(clubsRepositoryProvider)!
              .decideJoinRequest(n.refId!, approve: yes);
          ref.invalidate(clubDetailProvider(n.clubId!));
        case 'club_invitation':
          await ref
              .read(clubsRepositoryProvider)!
              .respondToInvitation(n.refId!, accept: yes);
          ref.invalidate(clubDetailProvider(n.clubId!));
      }
      await ref.read(notificationsRepositoryProvider)?.markRead([n.id]);
      ref.invalidate(notificationsProvider);
      if (mounted) showSnack(context, l10n.notificationsDone);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open() {
    final n = widget.n;
    ref.read(notificationsRepositoryProvider)?.markRead([n.id]);
    ref.invalidate(notificationsProvider);
    if (n.postId != null) {
      context.push(AppRoutes.post(n.postId!));
    } else if (n.rideId != null) {
      context.push(AppRoutes.ride(n.rideId!));
    } else if (n.clubId != null) {
      context.push(AppRoutes.club(n.clubId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final n = widget.n;
    final media = ref.watch(mediaRepositoryProvider);
    final isRequest = n.kind.endsWith('join_request');
    return Material(
      color: n.unread
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        key: Key('notif-${n.id}'),
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  RemoteAvatar(
                    label: n.actorName ?? '?',
                    image: media?.imageProvider(
                      MediaBucket.avatars,
                      n.actorAvatar,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        _icon(n.kind),
                        size: 13,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificationText(l10n, n),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: n.unread ? FontWeight.w700 : null,
                      ),
                    ),
                    if (n.data['excerpt'] is String)
                      Text(
                        '« ${n.data['excerpt']} »',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      timeAgo(l10n, n.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (n.actionable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          FilledButton(
                            key: Key('notif-accept-${n.id}'),
                            onPressed: _busy ? null : () => _decide(true),
                            child: Text(
                              isRequest ? l10n.notifApprove : l10n.notifAccept,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            key: Key('notif-decline-${n.id}'),
                            onPressed: _busy ? null : () => _decide(false),
                            child: Text(
                              isRequest ? l10n.notifReject : l10n.notifDecline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (n.unread)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs, top: 6),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
