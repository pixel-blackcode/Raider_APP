import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';

extension ReactionKindUi on ReactionKind {
  IconData get icon => switch (this) {
    ReactionKind.like => Icons.thumb_up_alt_rounded,
    ReactionKind.fire => Icons.local_fire_department_rounded,
    ReactionKind.respect => Icons.sports_motorsports_rounded,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ReactionKind.like => l10n.reactionLike,
    ReactionKind.fire => l10n.reactionFire,
    ReactionKind.respect => l10n.reactionRespect,
  };
}

extension ReportReasonUi on ReportReason {
  String label(AppLocalizations l10n) => switch (this) {
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.harassment => l10n.reportReasonHarassment,
    ReportReason.hate => l10n.reportReasonHate,
    ReportReason.violence => l10n.reportReasonViolence,
    ReportReason.nudity => l10n.reportReasonNudity,
    ReportReason.scam => l10n.reportReasonScam,
    ReportReason.other => l10n.reportReasonOther,
  };
}

extension ReportTargetUi on ReportTarget {
  String label(AppLocalizations l10n) => switch (this) {
    ReportTarget.post => l10n.reportTargetPost,
    ReportTarget.comment => l10n.reportTargetComment,
    ReportTarget.message => l10n.reportTargetMessage,
    ReportTarget.user => l10n.reportTargetUser,
    ReportTarget.listing => l10n.reportTargetListing,
  };
}

/// « à l'instant », « il y a 5 min », « il y a 3 h », puis la date.
String timeAgo(AppLocalizations l10n, DateTime t, {DateTime? now}) {
  final diff = (now ?? DateTime.now().toUtc()).difference(t);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  final l = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Signaler un contenu ou un motard. Retourne true si envoyé.
Future<bool> showReportDialog(
  BuildContext context,
  WidgetRef ref,
  ReportTarget target,
  String targetId,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<(ReportReason, String)>(
    context: context,
    builder: (_) => _ReportDialog(target: target),
  );
  if (result == null || !context.mounted) return false;
  try {
    await ref
        .read(communityRepositoryProvider)!
        .report(
          target,
          targetId,
          result.$1,
          details: result.$2.isEmpty ? null : result.$2,
        );
    if (context.mounted) showSnack(context, l10n.reportSent);
    return true;
  } catch (error) {
    if (context.mounted) showSnack(context, describeError(context, error));
    return false;
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.target});

  final ReportTarget target;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportTitle(widget.target.label(l10n))),
      content: SingleChildScrollView(
        child: RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in ReportReason.values)
                RadioListTile<ReportReason>(
                  key: Key('report-reason-${r.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: r,
                  title: Text(r.label(l10n)),
                ),
              TextField(
                key: const Key('report-details'),
                controller: _details,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.reportDetails),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('report-send'),
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(context, (_reason!, _details.text.trim())),
          child: Text(l10n.reportSend),
        ),
      ],
    );
  }
}

/// Bloquer un motard après confirmation. Retourne true si bloqué.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String name,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.blockTitle(name),
    message: l10n.blockBody,
    confirmLabel: l10n.blockConfirm,
  );
  if (!ok || !context.mounted) return false;
  try {
    await ref.read(communityRepositoryProvider)!.block(userId);
    refreshCommunity(ref);
    if (context.mounted) showSnack(context, l10n.blockDone(name));
    return true;
  } catch (error) {
    if (context.mounted) showSnack(context, describeError(context, error));
    return false;
  }
}
