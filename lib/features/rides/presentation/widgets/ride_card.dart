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

    final scheme = theme.colorScheme;
    final muted = ride.status.isTerminal;
    return Card(
      key: Key('ride-card-${ride.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloc date plein : lisible d'un coup d'œil, même au soleil.
              Container(
                width: 68,
                color: muted ? scheme.onSurfaceVariant : scheme.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      RideTime.formatShortDate(
                        ride.startsAt,
                        ride.timezone,
                      ).split(' ').first.replaceAll('.', '').toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${local.day}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: scheme.onPrimary,
                        fontSize: 34,
                      ),
                    ),
                    Text(
                      RideTime.formatShortDate(
                        ride.startsAt,
                        ride.timezone,
                      ).split(' ').last.replaceAll('.', '').toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ride.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: scheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          RideStatusBadge(ride: ride),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${RideTime.formatTime(ride.startsAt, ride.timezone)} · ${ride.city}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ride.startLabel} → ${ride.destinationLabel}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _Meta(
                            icon: Icons.terrain,
                            text: ride.difficulty.label(l10n),
                          ),
                          _Meta(
                            icon: Icons.people_alt_outlined,
                            text: capacity,
                          ),
                          if (ride.clubName != null)
                            _Meta(
                              icon: Icons.groups,
                              text: ride.clubName!,
                              accent: true,
                            ),
                          if (badge != null)
                            _Meta(
                              icon: Icons.hourglass_top,
                              text: badge!,
                              accent: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.accent = false});

  final IconData icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.labelLarge?.copyWith(color: color)),
      ],
    );
  }
}

class RideStatusBadge extends StatelessWidget {
  const RideStatusBadge({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final color = ride.statusColor(context);
    // Pastille pleine : statut lisible d'un coup d'œil.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ride.statusLabel(AppLocalizations.of(context)),
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 11,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
