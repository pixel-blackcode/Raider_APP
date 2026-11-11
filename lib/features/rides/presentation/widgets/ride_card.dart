import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/ride.dart';
import '../../domain/ride_time.dart';
import 'ride_labels.dart';

/// Carte d'une balade dans une liste.
class RideCard extends StatelessWidget {
  const RideCard({super.key, required this.ride, this.badge, this.onTap});

  final Ride ride;

  /// Mention complémentaire (ex. « Demande envoyée »).
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final local = RideTime.inZone(ride.startsAt, ride.timezone);
    final capacity = ride.maxParticipants == null
        ? l10n.rideParticipantCount(ride.participantCount)
        : l10n.rideParticipantCapacity(
            ride.participantCount,
            ride.maxParticipants!,
          );

    return Card(
      key: Key('ride-card-${ride.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${local.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      RideTime.formatShortDate(
                        ride.startsAt,
                        ride.timezone,
                      ).split(' ').last,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${ride.shortSchedule()} · ${ride.city}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${ride.startLabel} → ${ride.destinationLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RideStatusBadge(ride: ride),
                        Text(
                          '${ride.difficulty.label(l10n)} · $capacity',
                          style: theme.textTheme.labelMedium,
                        ),
                        if (ride.clubName != null)
                          Text(
                            ride.clubName!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (badge != null)
                          Text(
                            badge!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RideStatusBadge extends StatelessWidget {
  const RideStatusBadge({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final color = ride.statusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ride.statusLabel(AppLocalizations.of(context)),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
