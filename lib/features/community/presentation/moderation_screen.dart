import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';
import 'community_ui.dart';

/// File de modération : contenus signalés que l'utilisateur peut traiter
/// (administrateurs : tout ; modérateurs de club : leur club).
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(moderationQueueProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moderationTitle)),
      body: AsyncValueView(
        value: queue,
        onRetry: () => ref.invalidate(moderationQueueProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.verified_user_outlined,
                title: l10n.moderationEmptyTitle,
                message: l10n.moderationEmptyBody,
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [for (final i in items) _ModerationCard(item: i)],
              ),
      ),
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  const _ModerationCard({required this.item});

  final ModerationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;

    Future<void> act(ModerationAction action) async {
      try {
        await ref
            .read(communityRepositoryProvider)!
            .moderate(item.target, item.targetId, action);
        refreshCommunity(ref);
        if (context.mounted) showSnack(context, l10n.moderationDone);
      } catch (error) {
        if (context.mounted) showSnack(context, describeError(context, error));
      }
    }

    return Card(
      key: Key('mod-${item.targetId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.target.label(l10n),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.sos,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.moderationReports(item.reportCount),
                    style: TextStyle(
                      color: colors.onSos,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (item.authorName != null)
              InkWell(
                onTap: item.authorId == null
                    ? null
                    : () => context.push(AppRoutes.rider(item.authorId!)),
                child: Text(
                  l10n.moderationAuthor(item.authorName!),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            if (item.preview != null)
              Text('« ${item.preview} »', style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.reasons.map((r) => r.label(l10n)).join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            if (item.hidden)
              Text(
                l10n.moderationCurrentlyHidden,
                style: TextStyle(color: colors.warning),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (item.target != ReportTarget.user && !item.hidden)
                  FilledButton(
                    key: Key('mod-hide-${item.targetId}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.sos,
                      foregroundColor: colors.onSos,
                    ),
                    onPressed: () => act(ModerationAction.hide),
                    child: Text(l10n.moderationHide),
                  ),
                if (item.target != ReportTarget.user && item.hidden)
                  FilledButton(
                    key: Key('mod-restore-${item.targetId}'),
                    onPressed: () => act(ModerationAction.restore),
                    child: Text(l10n.moderationRestore),
                  ),
                OutlinedButton(
                  key: Key('mod-dismiss-${item.targetId}'),
                  onPressed: () => act(ModerationAction.dismiss),
                  child: Text(l10n.moderationDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
