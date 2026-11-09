import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../clubs/presentation/widgets/club_card.dart';

/// Aperçu des clubs découvrables sur l'accueil (3 au plus).
class HomeClubsSection extends ConsumerWidget {
  const HomeClubsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final empty = InfoCard(
      icon: Icons.groups_outlined,
      message: l10n.homeNoClubs,
    );
    if (ref.watch(clubsRepositoryProvider) == null) return empty;

    return switch (ref.watch(discoverClubsProvider)) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        children: [
          for (final club in value.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ClubCard(
                club: club,
                onTap: () => context.push(AppRoutes.club(club.id)),
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
