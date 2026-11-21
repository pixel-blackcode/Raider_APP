import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/badges_repository.dart';
import '../domain/badges.dart';
import 'badge_widgets.dart';

/// Mes badges : obtenus, puis les prochains avec leur progression.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final badges = ref.watch(myBadgesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesTitle)),
      body: AsyncValueView(
        value: badges,
        onRetry: () => ref.invalidate(myBadgesProvider),
        data: (list) {
          final earned = [
            for (final b in list)
              if (b.earned) b,
          ];
          final next = [
            for (final b in list)
              if (!b.earned) b,
          ]..sort((a, b) => b.ratio.compareTo(a.ratio));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBadgesProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  l10n.badgesSummary(earned.length, list.length),
                  key: const Key('badges-summary'),
                ),
                SectionHeader(title: l10n.badgesEarned),
                if (earned.isEmpty)
                  Text(l10n.badgesNoneYet)
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = (c.maxWidth - 2 * AppSpacing.sm) / 3;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final b in earned)
                            SizedBox(
                              width: w,
                              child: Card(
                                key: Key('badge-${b.code}-${b.period ?? ''}'),
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Column(
                                    children: [
                                      BadgeTile(badge: b),
                                      if (b.description != null &&
                                          b.code != 'ride_of_month')
                                        Text(
                                          b.description!,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (next.isNotEmpty) ...[
                  SectionHeader(title: l10n.badgesNext),
                  Card(
                    child: Column(
                      children: [for (final b in next) _NextBadgeRow(badge: b)],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.badgesNoRanking,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _NextBadgeRow extends StatelessWidget {
  const _NextBadgeRow({required this.badge});

  final RiderBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = badge.code.startsWith('road_');
    return ListTile(
      key: Key('next-badge-${badge.code}'),
      leading: BadgeMedal(code: badge.code, earned: false, size: 40),
      title: Text(badge.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge.description != null) Text(badge.description!),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: badge.ratio,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
      trailing: Text(
        distance
            ? '${_num(badge.progress ?? 0)}/${_num(badge.target ?? 0)} km'
            : '${_num(badge.progress ?? 0)}/${_num(badge.target ?? 0)}',
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
