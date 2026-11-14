import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/events_repository.dart';
import 'events_ui.dart';

/// Tous les événements moto à venir.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(upcomingEventsProvider(null));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventsTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.refreshEvents(),
        child: AsyncValueView(
          value: events,
          onRetry: () => ref.refreshEvents(),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.celebration_outlined,
                      title: l10n.eventsEmptyTitle,
                      message: l10n.eventsEmptyBody,
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final e in items)
                      EventCard(
                        event: e,
                        onTap: () => context.push(AppRoutes.event(e.id)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
