import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/badges_repository.dart';
import '../domain/badges.dart';

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « 2026-10 » → « octobre 2026 ».
String monthLabel(String period) {
  final parts = period.split('-');
  final m = int.tryParse(parts.length == 2 ? parts[1] : '') ?? 0;
  if (m < 1 || m > 12) return period;
  return '${_months[m - 1]} ${parts[0]}';
}

/// Titre affiché : un défi réussi porte aussi son mois.
String badgeTitle(RiderBadge b) => b.code == 'challenge' && b.period != null
    ? '${b.title} · ${monthLabel(b.period!)}'
    : b.title;

({IconData icon, Color bg, Color fg}) _style(String code) => switch (code) {
  'first_ride' || 'loyal' || 'pillar' => (
    icon: Icons.two_wheeler,
    bg: const Color(0xFFFFE8D9),
    fg: const Color(0xFFC2410C),
  ),
  'organizer' || 'convoy_leader' => (
    icon: Icons.flag_outlined,
    bg: const Color(0xFFE3E8F4),
    fg: AppColors.marine,
  ),
  'road_100' || 'road_500' || 'road_1000' => (
    icon: Icons.route,
    bg: const Color(0xFFE0F2F1),
    fg: const Color(0xFF00695C),
  ),
  'safe_home' || 'guardian' => (
    icon: Icons.shield_outlined,
    bg: const Color(0xFFDFF3E4),
    fg: const Color(0xFF1E6B34),
  ),
  'mechanic' => (
    icon: Icons.build_outlined,
    bg: const Color(0xFFFFF3D6),
    fg: const Color(0xFF8A5A00),
  ),
  'ride_of_month' => (
    icon: Icons.emoji_events,
    bg: const Color(0xFFFCA311),
    fg: AppColors.marine,
  ),
  'challenge' => (
    icon: Icons.track_changes,
    bg: AppColors.brand,
    fg: Colors.white,
  ),
  'in_club' || 'events' => (
    icon: Icons.groups_outlined,
    bg: const Color(0xFFE3E8F4),
    fg: AppColors.marine,
  ),
  _ => (
    icon: Icons.star_outline,
    bg: const Color(0xFFFFE8D9),
    fg: const Color(0xFFC2410C),
  ),
};

/// Médaille ronde d'un badge (grise et cadenas s'il n'est pas obtenu).
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.code,
    this.earned = true,
    this.size = 52,
  });

  final String code;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = _style(code);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? s.bg : const Color(0xFFECEEF2),
      ),
      child: Icon(
        earned ? s.icon : Icons.lock_outline,
        size: size * 0.5,
        color: earned ? s.fg : const Color(0xFF6B7080),
      ),
    );
  }
}

/// Badge obtenu : médaille + titre (profil, grille).
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, this.size = 52});

  final RiderBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BadgeMedal(code: badge.code, size: size),
        const SizedBox(height: AppSpacing.xs),
        Text(
          badgeTitle(badge),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Badges obtenus d'un motard (profil public) ; rien s'il n'en a pas.
class RiderBadgesSection extends ConsumerWidget {
  const RiderBadgesSection({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final earned = [
      for (final b
          in ref.watch(riderBadgesProvider(userId)).value ??
              const <RiderBadge>[])
        if (b.earned) b,
    ];
    if (earned.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('rider-badges'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.badgesCount(earned.length)),
        _BadgeGrid(badges: earned),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<RiderBadge> badges;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = (c.maxWidth / 96).floor().clamp(3, 6);
        final w = (c.maxWidth - (perRow - 1) * AppSpacing.sm) / perRow;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          children: [
            for (final b in badges)
              SizedBox(
                width: w,
                child: BadgeTile(badge: b),
              ),
          ],
        );
      },
    );
  }
}

/// Mon profil : mes derniers badges, accès aux badges et aux défis.
class MyBadgesCard extends ConsumerWidget {
  const MyBadgesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final badges = ref.watch(myBadgesProvider).value ?? const <RiderBadge>[];
    final challenges = ref.watch(challengesProvider).value ?? const [];
    final earned = [
      for (final b in badges)
        if (b.earned) b,
    ];
    final today = DateTime.now();
    final running = challenges
        .where((c) => !c.completed && c.daysLeft(today) >= 0)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.badgesTitle,
          trailing: TextButton(
            key: const Key('profile-badges-all'),
            onPressed: () => context.push(AppRoutes.badges),
            child: Text(l10n.homeSeeAll),
          ),
        ),
        if (earned.isEmpty)
          Text(l10n.badgesNoneYet)
        else
          _BadgeGrid(badges: earned.take(4).toList()),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListTile(
            key: const Key('profile-challenges'),
            leading: const CircleAvatar(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              child: Icon(Icons.track_changes),
            ),
            title: Text(l10n.challengesTitle),
            subtitle: Text(
              running == 0
                  ? l10n.challengesNoneRunning
                  : l10n.challengesRunning(running),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.challenges),
          ),
        ),
      ],
    );
  }
}

/// Bandeau d'un compte suspendu (raison et date de fin).
class SuspensionBanner extends ConsumerWidget {
  const SuspensionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(mySuspensionProvider).value;
    if (s == null) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<RiderColors>()!;
    final until = s.until?.toLocal();
    return Card(
      key: const Key('suspension-banner'),
      color: colors.sos,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              until == null
                  ? l10n.suspensionForever
                  : l10n.suspensionUntil(
                      '${until.day.toString().padLeft(2, '0')}/'
                      '${until.month.toString().padLeft(2, '0')}/${until.year}',
                    ),
              style: TextStyle(
                color: colors.onSos,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.suspensionReason(s.reason),
              style: TextStyle(color: colors.onSos),
            ),
            Text(l10n.suspensionHelp, style: TextStyle(color: colors.onSos)),
          ],
        ),
      ),
    );
  }
}
