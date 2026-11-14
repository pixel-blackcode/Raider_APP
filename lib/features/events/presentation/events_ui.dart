import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/moto_event.dart';

/// « sam. 21 nov. 2026 · 09:00 » dans le fuseau du téléphone.
String formatEventDate(BuildContext context, DateTime at) {
  final m = MaterialLocalizations.of(context);
  final local = at.toLocal();
  return '${m.formatMediumDate(local)} · '
      '${m.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final MotoEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: Key('event-${event.id}'),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.celebration_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          event.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            formatEventDate(context, event.startsAt),
            '${event.placeName}, ${event.city}',
            l10n.eventByOrganizer(event.clubName),
            if (event.attendeeCount > 0)
              l10n.eventGoingCount(event.attendeeCount),
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}
