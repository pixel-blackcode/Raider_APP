import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/sound/alert_sound.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../messages/data/messaging_providers.dart';
import '../data/notifications_repository.dart';

/// Cloche avec pastille du nombre de notifications non lues.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return IconButton(
      key: const Key('notifications-bell'),
      tooltip: AppLocalizations.of(context).notificationsTitle,
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        key: const Key('notifications-badge'),
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          unread > 0 ? Icons.notifications_active : Icons.notifications_none,
        ),
      ),
    );
  }
}

/// Joue un son quand une notification ou un message arrive (application
/// ouverte, sons activés dans les Paramètres).
class NotificationSoundListener extends ConsumerStatefulWidget {
  const NotificationSoundListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationSoundListener> createState() =>
      _NotificationSoundListenerState();
}

class _NotificationSoundListenerState
    extends ConsumerState<NotificationSoundListener> {
  void _ring(int? previous, int next) {
    if (previous == null || next <= previous) return;
    if (!ref.read(soundsEnabledProvider)) return;
    ref.read(alertSoundProvider).notification();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(unreadNotificationsProvider, _ring)
      ..listen(unreadTotalProvider, _ring);
    return widget.child;
  }
}
