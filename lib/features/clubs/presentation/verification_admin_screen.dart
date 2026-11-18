import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../../settings/data/feedback_repository.dart';
import '../../sos/data/emergency.dart';
import '../data/clubs_providers.dart';
import '../data/verification_admin_repository.dart';
import '../domain/club.dart';

/// Onglet réservé à l'équipe Rider Group : examen des demandes.
class VerificationAdminScreen extends ConsumerWidget {
  const VerificationAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(verificationQueueProvider);
    final riders = ref.watch(riderVerificationQueueProvider);
    final empty = EmptyState(
      icon: Icons.verified_user_outlined,
      title: l10n.verificationAdminEmptyTitle,
      message: l10n.verificationAdminEmptyBody,
    );
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.verificationAdminTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.verificationTabClubs),
              Tab(
                key: const Key('verification-tab-riders'),
                text: l10n.verificationTabRiders,
              ),
              Tab(
                key: const Key('verification-tab-deletions'),
                text: l10n.deletionTab,
              ),
              Tab(
                key: const Key('verification-tab-feedback'),
                text: l10n.feedbackTab,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AsyncValueView(
              value: queue,
              onRetry: () => ref.invalidate(verificationQueueProvider),
              data: (items) => items.isEmpty
                  ? empty
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [for (final i in items) _RequestCard(item: i)],
                    ),
            ),
            AsyncValueView(
              value: riders,
              onRetry: () => ref.invalidate(riderVerificationQueueProvider),
              data: (items) => items.isEmpty
                  ? empty
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        for (final i in items) _RiderRequestCard(item: i),
                      ],
                    ),
            ),
            const _DeletionTab(),
            const _FeedbackTab(),
          ],
        ),
      ),
    );
  }
}

/// Durée de validité choisie par l'équipe (null : annulé).
Future<DateTime?> _pickValidity(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final months = await showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.verificationDuration),
      children: [
        for (final m in const [1, 6, 12])
          SimpleDialogOption(
            key: Key('verification-duration-$m'),
            onPressed: () => Navigator.pop(context, m),
            child: Text(
              m == 12 ? l10n.verificationOneYear : l10n.verificationMonths(m),
            ),
          ),
      ],
    ),
  );
  if (months == null) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month + months, now.day, 23, 59);
}

class _RiderRequestCard extends ConsumerStatefulWidget {
  const _RiderRequestCard({required this.item});

  final RiderVerificationQueueItem item;

  @override
  ConsumerState<_RiderRequestCard> createState() => _RiderRequestCardState();
}

class _RiderRequestCardState extends ConsumerState<_RiderRequestCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final l10n = AppLocalizations.of(context);
    DateTime? until;
    if (approve) {
      until = await _pickValidity(context);
      if (until == null) return;
    }
    if (!mounted) return;
    final note = await showTextPrompt(
      context,
      title: approve ? l10n.verificationApprove : l10n.verificationReject,
      label: l10n.verificationNote,
      confirmLabel: approve
          ? l10n.verificationApprove
          : l10n.verificationReject,
      maxLength: 1000,
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(verificationAdminRepositoryProvider)!
          .reviewRider(
            widget.item.requestId,
            approve: approve,
            note: note.isEmpty ? null : note,
            validUntil: until,
          );
      ref.invalidate(riderVerificationQueueProvider);
      if (mounted) showSnack(context, l10n.moderationDone);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final i = widget.item;
    final media = ref.watch(mediaRepositoryProvider);
    final docs = [
      for (final p in i.documentPaths)
        media?.imageProvider(MediaBucket.verificationDocs, p),
    ];
    return Card(
      key: Key('rider-verification-request-${i.requestId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.rider(i.userId)),
              child: Text(
                '${i.displayName} · @${i.username}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(l10n.verificationRealNameValue(i.realName)),
            if (i.message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('« ${i.message} »'),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(externalActionsProvider)
                  .openWhatsApp(i.contactPhone),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l10n.verificationContactWhatsApp(i.contactPhone)),
            ),
            if (docs.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (var d = 0; d < docs.length; d++)
                    ActionChip(
                      avatar: const Icon(Icons.description_outlined),
                      label: Text(l10n.verificationDocumentN(d + 1)),
                      onPressed: () => openPhotoViewer(
                        context,
                        images: docs,
                        initialIndex: d,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: Key('rider-verification-approve-${i.requestId}'),
                    onPressed: _busy ? null : () => _decide(true),
                    child: Text(l10n.verificationApprove),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    key: Key('rider-verification-reject-${i.requestId}'),
                    onPressed: _busy ? null : () => _decide(false),
                    child: Text(l10n.verificationReject),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.item});

  final VerificationQueueItem item;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final l10n = AppLocalizations.of(context);
    DateTime? until;
    if (approve) {
      until = await _pickValidity(context);
      if (until == null) return;
    }
    if (!mounted) return;
    final note = await showTextPrompt(
      context,
      title: approve ? l10n.verificationApprove : l10n.verificationReject,
      label: l10n.verificationNote,
      confirmLabel: approve
          ? l10n.verificationApprove
          : l10n.verificationReject,
      maxLength: 1000,
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(verificationAdminRepositoryProvider)!
          .review(
            widget.item.requestId,
            approve: approve,
            note: note.isEmpty ? null : note,
            validUntil: until,
          );
      ref
        ..invalidate(verificationQueueProvider)
        ..invalidate(clubDetailProvider(widget.item.clubId));
      if (mounted) showSnack(context, l10n.moderationDone);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final i = widget.item;
    final media = ref.watch(mediaRepositoryProvider);
    final docs = [
      for (final p in i.documentPaths)
        media?.imageProvider(MediaBucket.verificationDocs, p),
    ];
    return Card(
      key: Key('verification-request-${i.requestId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.club(i.clubId)),
              child: Text(
                '${i.clubName} · ${i.clubCity}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(l10n.verificationOfficialNameValue(i.officialName)),
            Text(l10n.verificationContactValue(i.contactName)),
            if (i.requesterName != null)
              Text(
                l10n.verificationRequester(i.requesterName!),
                style: theme.textTheme.bodySmall,
              ),
            if (i.message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('« ${i.message} »'),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: Key('verification-whatsapp-${i.requestId}'),
              onPressed: () => ref
                  .read(externalActionsProvider)
                  .openWhatsApp(i.contactPhone),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l10n.verificationContactWhatsApp(i.contactPhone)),
            ),
            if (docs.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (var d = 0; d < docs.length; d++)
                    ActionChip(
                      avatar: const Icon(Icons.description_outlined),
                      label: Text(l10n.verificationDocumentN(d + 1)),
                      onPressed: () => openPhotoViewer(
                        context,
                        images: docs,
                        initialIndex: d,
                      ),
                    ),
                ],
              ),
            if (i.status == VerificationStatus.pending) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: Key('verification-approve-${i.requestId}'),
                      onPressed: _busy ? null : () => _decide(true),
                      child: Text(l10n.verificationApprove),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      key: Key('verification-reject-${i.requestId}'),
                      onPressed: _busy ? null : () => _decide(false),
                      child: Text(l10n.verificationReject),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackTab extends ConsumerWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AsyncValueView(
      value: ref.watch(feedbackQueueProvider),
      onRetry: () => ref.invalidate(feedbackQueueProvider),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.inbox_outlined,
              title: l10n.feedbackEmpty,
              message: '',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final f in items)
                  Card(
                    key: Key('feedback-${f.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                f.kind == FeedbackKind.problem
                                    ? Icons.bug_report_outlined
                                    : Icons.lightbulb_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  f.kind == FeedbackKind.problem
                                      ? l10n.feedbackProblem
                                      : l10n.feedbackSuggestion,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(f.message),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [
                              if (f.displayName.isNotEmpty)
                                '${f.displayName} (@${f.username})',
                              if (f.appVersion != null) f.appVersion!,
                              if (f.platform != null) f.platform!,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              if (f.userId != null)
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.rider(f.userId!)),
                                  child: Text(l10n.chatSeeProfile),
                                ),
                              const Spacer(),
                              FilledButton.tonal(
                                key: Key('feedback-done-${f.id}'),
                                onPressed: () async {
                                  await ref
                                      .read(feedbackRepositoryProvider)
                                      ?.markHandled(f.id);
                                  ref.invalidate(feedbackQueueProvider);
                                },
                                child: Text(l10n.feedbackHandled),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DeletionTab extends ConsumerWidget {
  const _DeletionTab();

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    DeletionQueueItem d,
    bool approve,
  ) async {
    final l10n = AppLocalizations.of(context);
    final note = await showTextPrompt(
      context,
      title: approve ? l10n.deletionApprove : l10n.deletionReject,
      label: l10n.verificationNote,
      confirmLabel: approve ? l10n.deletionApprove : l10n.deletionReject,
      maxLength: 1000,
    );
    if (note == null || !context.mounted) return;
    try {
      await ref
          .read(verificationAdminRepositoryProvider)!
          .reviewDeletion(
            d.requestId,
            approve: approve,
            note: note.isEmpty ? null : note,
          );
      ref.invalidate(clubDeletionQueueProvider);
      if (context.mounted) showSnack(context, l10n.moderationDone);
    } catch (error) {
      if (context.mounted) showSnack(context, describeError(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final m = MaterialLocalizations.of(context);
    return AsyncValueView(
      value: ref.watch(clubDeletionQueueProvider),
      onRetry: () => ref.invalidate(clubDeletionQueueProvider),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.delete_outline,
              title: l10n.deletionEmpty,
              message: '',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final d in items)
                  Card(
                    key: Key('deletion-${d.requestId}'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            onTap: d.clubId == null
                                ? null
                                : () => context.push(AppRoutes.club(d.clubId!)),
                            child: Text(
                              '${d.clubName} · ${d.clubCity}',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            [
                              if (d.isRegroupement) l10n.groupKindRegroupement,
                              l10n.clubMemberCount(d.memberCount),
                              if (d.requesterName != null)
                                l10n.verificationRequester(d.requesterName!),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(l10n.deletionReasonLabel),
                          Text(
                            '« ${d.reason} »',
                            key: Key('deletion-reason-${d.requestId}'),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.deletionAutoOn(
                              m.formatMediumDate(d.dueAt.toLocal()),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: Key('deletion-reject-${d.requestId}'),
                                  onPressed: () =>
                                      _decide(context, ref, d, false),
                                  child: Text(l10n.deletionReject),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: FilledButton(
                                  key: Key('deletion-approve-${d.requestId}'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                                  onPressed: () =>
                                      _decide(context, ref, d, true),
                                  child: Text(l10n.deletionApprove),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
