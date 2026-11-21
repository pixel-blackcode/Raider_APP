import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/solo_repository.dart';
import 'solo_labels.dart';
import 'solo_screen.dart';

/// Accueil : mon trajet solo en cours et les trajets que je suis.
class SoloHomeBanner extends ConsumerWidget {
  const SoloHomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(soloLocationSharingProvider);
    final trips = ref.watch(soloTripsProvider).value ?? const [];
    final now = DateTime.now().toUtc();
    final mine = ref.watch(myActiveSoloTripProvider);
    final watched = [
      for (final t in trips)
        if (!t.mine && t.active) t,
    ];
    if (mine == null && watched.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<RiderColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mine != null)
            Material(
              color: mine.isLate(now) ? colors.sos : AppColors.marine,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: const Key('solo-home-mine'),
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push(AppRoutes.solo),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_moon_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          mine.isLate(now)
                              ? l10n.soloHomeMineLate
                              : l10n.soloHomeMine(soloTime(mine.expectedAt)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        l10n.soloArrived,
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final t in watched) SoloWatchedTile(trip: t),
        ],
      ),
    );
  }
}
