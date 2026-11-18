import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/feedback_repository.dart';

/// « Signaler un problème ou une suggestion » : message privé à l'équipe.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  FeedbackKind _kind = FeedbackKind.problem;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(feedbackRepositoryProvider)!
          .send(
            _kind,
            _message.text,
            appVersion: AppConfig.buildId,
            platform: defaultTargetPlatform.name,
          );
      if (!mounted) return;
      showSnack(context, l10n.feedbackSent);
      context.pop();
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(l10n.feedbackIntro),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<FeedbackKind>(
              key: const Key('feedback-kind'),
              segments: [
                ButtonSegment(
                  value: FeedbackKind.problem,
                  icon: const Icon(Icons.bug_report_outlined),
                  label: Text(l10n.feedbackProblem),
                ),
                ButtonSegment(
                  value: FeedbackKind.suggestion,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(l10n.feedbackSuggestion),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('feedback-message'),
              controller: _message,
              maxLength: 2000,
              minLines: 5,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: _kind == FeedbackKind.problem
                    ? l10n.feedbackProblemHint
                    : l10n.feedbackSuggestionHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v ?? '').trim().length < 5
                  ? l10n.validationTooShort(5)
                  : null,
            ),
            Text(
              l10n.feedbackVersionNote(AppConfig.buildId),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('feedback-send'),
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.send),
              label: Text(l10n.feedbackSend),
            ),
          ],
        ),
      ),
    );
  }
}
