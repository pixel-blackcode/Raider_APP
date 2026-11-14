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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationAdminTitle)),
      body: AsyncValueView(
        value: queue,
        onRetry: () => ref.invalidate(verificationQueueProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.verified_user_outlined,
                title: l10n.verificationAdminEmptyTitle,
                message: l10n.verificationAdminEmptyBody,
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [for (final i in items) _RequestCard(item: i)],
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
                  m == 12
                      ? l10n.verificationOneYear
                      : l10n.verificationMonths(m),
                ),
              ),
          ],
        ),
      );
      if (months == null) return;
      final now = DateTime.now();
      until = DateTime(now.year, now.month + months, now.day, 23, 59);
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
