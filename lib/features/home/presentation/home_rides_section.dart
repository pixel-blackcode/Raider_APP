import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../rides/data/rides_providers.dart';
import '../../rides/presentation/widgets/ride_card.dart';

/// Prochaines balades sur l'accueil (3 au plus).
class HomeRidesSection extends ConsumerWidget {
  const HomeRidesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final empty = InfoCard(
      icon: Icons.route_outlined,
      message: l10n.homeNoRides,
    );
    if (ref.watch(ridesRepositoryProvider) == null) return empty;

    return switch (ref.watch(discoverRidesProvider)) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        children: [
          for (final ride in value.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RideCard(
                ride: ride,
                onTap: () => context.push(AppRoutes.ride(ride.id)),
              ),
            ),
        ],
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      _ => empty,
    };
  }
}
