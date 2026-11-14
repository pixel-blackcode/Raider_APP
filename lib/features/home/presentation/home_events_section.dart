import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../events/data/events_repository.dart';
import '../../events/presentation/events_ui.dart';

/// Prochains événements moto sur l'accueil (masqué s'il n'y en a aucun).
class HomeEventsSection extends ConsumerWidget {
  const HomeEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(upcomingEventsProvider(null)).value ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.eventsTitle,
          trailing: TextButton(
            key: const Key('home-events-all'),
            onPressed: () => context.push(AppRoutes.events),
            child: Text(l10n.homeSeeAll),
          ),
        ),
        for (final e in events.take(3))
          EventCard(event: e, onTap: () => context.push(AppRoutes.event(e.id))),
      ],
    );
  }
}
