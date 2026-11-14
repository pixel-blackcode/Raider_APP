import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/clubs_providers.dart';
import '../domain/club.dart';

/// Demande de vérification d'un club : avantages et formulaire.
///
/// Règles des magasins d'applications : AUCUN prix, montant ni paiement.
/// L'équipe Rider Group examine la demande et contacte le club en dehors de
/// l'application.
class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key, required this.clubId});

  final String clubId;

  static const maxDocuments = 5;

  @override
  ConsumerState<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends ConsumerState<VerificationRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _official = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController(text: '+243');
  final _message = TextEditingController();
  final _docs = <PickedImage>[];
  final _uploaded = <PickedImage, String>{};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_official, _contact, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addDocument() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 2000);
      if (image == null) return;
      image.validateFor(MediaBucket.verificationDocs);
      setState(() => _docs.add(image));
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final media = ref.read(mediaRepositoryProvider);
      final paths = <String>[];
      for (final d in _docs) {
        paths.add(
          _uploaded[d] ??= await media!.upload(
            MediaBucket.verificationDocs,
            folder: widget.clubId,
            baseName: 'document',
            image: d,
          ),
        );
      }
      await ref
          .read(clubsRepositoryProvider)!
          .requestVerification(
            widget.clubId,
            VerificationForm(
              officialName: _official.text.trim(),
              contactName: _contact.text.trim(),
              contactPhone: _phone.text.replaceAll(RegExp(r'[\s.\-()]'), ''),
              message: _message.text.trim().isEmpty
                  ? null
                  : _message.text.trim(),
              documentPaths: paths,
            ),
          );
      ref.invalidate(clubDetailProvider(widget.clubId));
      if (!mounted) return;
      showSnack(context, l10n.clubVerificationSent);
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
    final theme = Theme.of(context);
    String? need(String? v) =>
        (v == null || v.trim().length < 2) ? l10n.validationTooShort(2) : null;

    Widget advantage(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              l10n.verificationAdvantagesTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            advantage(Icons.verified, l10n.verificationAdvantageBadge),
            advantage(
              Icons.handshake_outlined,
              l10n.verificationAdvantageTrust,
            ),
            advantage(Icons.shield_outlined, l10n.verificationAdvantageName),
            advantage(Icons.event_repeat, l10n.verificationAdvantageRenewal),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.verificationProcess, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('verification-official-name'),
              controller: _official,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: l10n.verificationOfficialName,
              ),
              validator: need,
            ),
            TextFormField(
              key: const Key('verification-contact-name'),
              controller: _contact,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: l10n.verificationContactName,
              ),
              validator: need,
            ),
            TextFormField(
              key: const Key('verification-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.verificationPhone,
                helperText: l10n.verificationPhoneHelp,
              ),
              validator: (v) =>
                  RegExp(r'^\+?[0-9]{8,15}$')
                      .hasMatch((v ?? '').replaceAll(RegExp(r'[\s.\-()]'), ''))
                  ? null
                  : l10n.verificationPhoneInvalid,
            ),
            TextFormField(
              key: const Key('verification-message'),
              controller: _message,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.clubVerificationMessage,
              ),
            ),
            Text(
              l10n.verificationDocuments(_docs.length),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              l10n.verificationDocumentsHelp,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (i, _) in _docs.indexed)
                  InputChip(
                    avatar: const Icon(Icons.description_outlined),
                    label: Text(l10n.verificationDocumentN(i + 1)),
                    onDeleted: _busy
                        ? null
                        : () => setState(() => _docs.removeAt(i)),
                  ),
                if (_docs.length < VerificationRequestScreen.maxDocuments)
                  ActionChip(
                    key: const Key('verification-add-document'),
                    avatar: const Icon(Icons.add),
                    label: Text(l10n.verificationAddDocument),
                    onPressed: _busy ? null : _addDocument,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: AppSpacing.convoyTouchTarget,
              child: FilledButton.icon(
                key: const Key('verification-submit'),
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.verified_outlined),
                label: Text(l10n.verificationSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
