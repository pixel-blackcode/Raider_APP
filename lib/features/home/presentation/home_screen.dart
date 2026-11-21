import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shortcut_tile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/data/community_providers.dart';
import '../../community/presentation/post_feed.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../profile/data/profile_repository.dart';
import '../../solo/presentation/solo_home_banner.dart';
import 'home_clubs_section.dart';
import 'home_events_section.dart';
import 'home_rides_section.dart';

/// Accueil : prochaines balades, clubs et publications communautaires.
///
/// Chaque section affiche un état vide explicite quand il n'y a rien à
/// montrer (aucune donnée fictive).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final media = ref.watch(mediaRepositoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home-new-post'),
        heroTag: null,
        onPressed: () => context.push(AppRoutes.newPost()),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.postPublish),
      ),
      // En-tête façon application (catalogue 07-E / H2) : avatar, salutation,
      // cloche et réglages dans des pastilles rondes.
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            RemoteAvatar(
              label: profile?.displayName ?? 'R',
              radius: 22,
              image: media?.imageProvider(
                MediaBucket.avatars,
                profile?.avatarPath,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile == null
                        ? l10n.appTitle
                        : l10n.homeHello(profile.displayName),
                    key: const Key('home-greeting'),
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.homeTagline,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const _RoundAction(child: NotificationBell()),
          _RoundAction(
            child: IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      // Défilement stable : les sections du haut restent montées (blocs fixes)
      // et seules les publications sont construites à la demande ; sinon les
      // sections rechargées hors écran changeaient de hauteur et la page
      // « sautait » en descendant.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeroCard(),
                  const SizedBox(height: AppSpacing.md),
                  const BackendStatusCard(hideWhenReady: true),
                  const SoloHomeBanner(),
                  SectionHeader(title: l10n.homeShortcuts),
                  ShortcutTile(
                    key: const Key('shortcut-solo'),
                    icon: Icons.shield_moon_outlined,
                    title: l10n.soloTitle,
                    subtitle: l10n.soloSubtitle,
                    onTap: () => context.push(AppRoutes.solo),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                  SectionHeader(
                    title: l10n.homeUpcomingRides,
                    trailing: TextButton(
                      onPressed: () => context.go(AppRoutes.rides),
                      child: Text(l10n.homeSeeAll),
                    ),
                  ),
                  const HomeRidesSection(),
                  const HomeEventsSection(),
                  SectionHeader(
                    title: l10n.homeClubs,
                    trailing: TextButton(
                      onPressed: () => context.go(AppRoutes.clubs),
                      child: Text(l10n.homeSeeAll),
                    ),
                  ),
                  const HomeClubsSection(),
                  SectionHeader(title: l10n.homeCommunity),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: PostSliverFeed(query: homeFeed),
          ),
          // Espace pour le bouton « Publier ».
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs),
    child: Material(
      color: Theme.of(context).cardTheme.color,
      shape: const CircleBorder(),
      elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 1,
      shadowColor: AppColors.marine.withValues(alpha: 0.12),
      child: child,
    ),
  );
}

/// Bannière d'accueil marine (catalogue 07-E « carte vedette ») : message,
/// rappel de sécurité et accès direct aux balades.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-hero'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.marine, Color(0xFF1F3366)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Halo orange et moto en filigrane, à droite.
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.55),
                    AppColors.brand.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 12,
            top: 18,
            child: Icon(Icons.two_wheeler, size: 72, color: Color(0x33FFFFFF)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeWelcomeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.homeWelcomeBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD5DAE6),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.safetyNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFFE2B3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('home-hero-rides'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.go(AppRoutes.rides),
                  icon: const Icon(Icons.route),
                  label: Text(l10n.homeHeroCta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
