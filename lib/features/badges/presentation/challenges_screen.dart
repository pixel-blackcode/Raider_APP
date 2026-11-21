import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/badges_repository.dart';
import '../domain/badges.dart';

/// Défis proposés par l'équipe, avec ma progression.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(challengesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengesTitle)),
      body: AsyncValueView(
        value: list,
        onRetry: () => ref.invalidate(challengesProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.track_changes,
                title: l10n.challengesEmptyTitle,
                message: l10n.challengesEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(challengesProvider),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final c in items) _ChallengeCard(challenge: c),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.challengesHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final c = challenge;
    final days = c.daysLeft(DateTime.now());
    final ended = days < 0;
    final dark = !c.completed && !ended;
    final fg = dark ? Colors.white : theme.colorScheme.onSurface;
    final status = c.completed
        ? l10n.challengeDone
        : ended
        ? l10n.challengeEnded
        : l10n.challengeRunning;
    final unit = c.isDistance ? ' km' : '';
    return Card(
      key: Key('challenge-${c.id}'),
      color: dark ? AppColors.marine : null,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (c.completed)
                  Icon(Icons.check_circle, size: 18, color: colors.success),
                if (c.completed) const SizedBox(width: AppSpacing.xs),
                Text(
                  status.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: c.completed
                        ? colors.success
                        : dark
                        ? AppColors.gold
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (!ended)
                  Text(
                    l10n.challengeDaysLeft(days),
                    style: TextStyle(color: fg.withValues(alpha: 0.8)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              c.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (c.description.isNotEmpty)
              Text(
                c.description,
                style: TextStyle(color: fg.withValues(alpha: 0.85)),
              ),
            if (!c.completed) ...[
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: c.ratio,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: AppColors.brand,
                backgroundColor: dark
                    ? Colors.white24
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_num(c.progress)} / ${c.target}$unit',
                key: Key('challenge-progress-${c.id}'),
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
