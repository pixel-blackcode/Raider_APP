import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shortcut_tile.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Accueil : prochaines balades, clubs et publications communautaires.
///
/// Tant que les modules correspondants ne sont pas livrés, chaque section
/// affiche un état vide explicite (aucune donnée fictive).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.homeWelcomeTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeWelcomeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const BackendStatusCard(hideWhenReady: true),
          const SizedBox(height: AppSpacing.sm),
          InfoCard(
            icon: Icons.health_and_safety_outlined,
            message: l10n.safetyNotice,
            color: colors.warning,
          ),
          SectionHeader(title: l10n.homeShortcuts),
          Row(
            children: [
              Expanded(
                child: ShortcutTile(
                  key: const Key('shortcut-garage'),
                  icon: Icons.two_wheeler,
                  title: l10n.garageTitle,
                  subtitle: l10n.garageSubtitle,
                  onTap: () => context.push(AppRoutes.garage),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShortcutTile(
                  key: const Key('shortcut-marketplace'),
                  icon: Icons.storefront_outlined,
                  title: l10n.marketplaceTitle,
                  subtitle: l10n.marketplaceSubtitle,
                  onTap: () => context.push(AppRoutes.marketplace),
                ),
              ),
            ],
          ),
          SectionHeader(title: l10n.homeUpcomingRides),
          InfoCard(icon: Icons.route_outlined, message: l10n.homeNoRides),
          SectionHeader(title: l10n.homeClubs),
          InfoCard(icon: Icons.groups_outlined, message: l10n.homeNoClubs),
          SectionHeader(title: l10n.homeCommunity),
          InfoCard(icon: Icons.forum_outlined, message: l10n.homeNoPosts),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
