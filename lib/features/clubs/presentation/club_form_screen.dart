import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/clubs_providers.dart';
import '../domain/club.dart';
import '../domain/club_draft.dart';
import '../domain/club_permissions.dart';
import 'widgets/club_labels.dart';

/// Création (clubId == null) ou modification d'un club.
class ClubFormScreen extends ConsumerWidget {
  const ClubFormScreen({super.key, this.clubId});

  final String? clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = clubId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clubCreate)),
        body: const _ClubForm(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clubEdit)),
      body: AsyncValueView(
        value: ref.watch(clubDetailProvider(id)),
        onRetry: () => ref.invalidate(clubDetailProvider(id)),
        data: (detail) {
          final permissions = ClubPermissions(detail?.myRole);
          if (detail == null || !permissions.canEditDetails) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: l10n.errorNotAllowed,
              message: l10n.clubEditNotAllowed,
            );
          }
          return ListView(
            children: [
              _ClubImagesSection(club: detail.club),
              _ClubForm(
                club: detail.club,
                canChangeSettings: permissions.canChangeSettings,
                embedded: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClubForm extends ConsumerStatefulWidget {
  const _ClubForm({
    this.club,
    this.canChangeSettings = true,
    this.embedded = false,
  });

  final Club? club;
  final bool canChangeSettings;

  /// Intégré dans une liste parente (pas de défilement propre).
  final bool embedded;

  @override
  ConsumerState<_ClubForm> createState() => _ClubFormState();
}

class _ClubFormState extends ConsumerState<_ClubForm> {
  final _formKey = GlobalKey<FormState>();
  late final ClubDraft _initial = widget.club == null
      ? const ClubDraft(
          name: '',
          city: '',
          visibility: ClubVisibility.public,
          joinPolicy: ClubJoinPolicy.open,
        )
      : ClubDraft.fromClub(widget.club!);

  late final _name = TextEditingController(text: _initial.name);
  late final _city = TextEditingController(text: _initial.city);
  late final _description = TextEditingController(text: _initial.description);
  late final _rules = TextEditingController(text: _initial.rules);
  late ClubVisibility _visibility = _initial.visibility;
  late ClubJoinPolicy _joinPolicy = _initial.joinPolicy;
  late bool _isListed = _initial.isListed;
  bool _busy = false;

  bool get _isEditing => widget.club != null;

  @override
  void dispose() {
    for (final c in [_name, _city, _description, _rules]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setVisibility(ClubVisibility value) {
    setState(() {
      _visibility = value;
      final allowed = ClubJoinPolicy.allowedFor(value);
      if (!allowed.contains(_joinPolicy)) _joinPolicy = allowed.first;
      if (value == ClubVisibility.public) _isListed = true;
    });
  }

  ClubDraft get _draft => ClubDraft(
    name: _name.text,
    city: _city.text,
    description: _description.text,
    rules: _rules.text,
    visibility: _visibility,
    joinPolicy: _joinPolicy,
    isListed: _isListed,
  );

  Future<void> _submit() async {
    final repository = ref.read(clubsRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    final draft = _draft;
    if (draft.validate().isNotEmpty) return;

    setState(() => _busy = true);
    try {
      if (_isEditing) {
        await repository.updateClub(widget.club!.id, draft);
        ref.refreshClubs(widget.club!.id);
        if (mounted) context.pop();
      } else {
        final club = await repository.createClub(draft);
        ref.refreshClubs();
        if (mounted) context.pushReplacement(AppRoutes.club(club.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(describeError(context, error))),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsEnabled = widget.canChangeSettings && !_busy;

    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: widget.embedded,
        physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('club-field-name'),
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.clubFieldName),
            validator: (v) {
              final length = (v ?? '').trim().length;
              return length >= 3 && length <= 80
                  ? null
                  : l10n.validationClubName;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('club-field-city'),
            controller: _city,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.fieldCity),
            validator: (v) {
              final length = (v ?? '').trim().length;
              return length >= 2 && length <= 80 ? null : l10n.validationCity;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('club-field-description'),
            controller: _description,
            maxLength: 2000,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.clubFieldDescription),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _rules,
            maxLength: 5000,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.clubFieldRules),
          ),
          SectionHeader(title: l10n.clubSectionAccess),
          if (!widget.canChangeSettings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(l10n.clubSettingsOwnerOnly),
            ),
          SegmentedButton<ClubVisibility>(
            key: const Key('club-field-visibility'),
            segments: [
              for (final v in ClubVisibility.values)
                ButtonSegment(
                  value: v,
                  label: Text(v.label(l10n)),
                  icon: Icon(
                    v == ClubVisibility.public
                        ? Icons.public
                        : Icons.lock_outline,
                  ),
                ),
            ],
            selected: {_visibility},
            onSelectionChanged: settingsEnabled
                ? (s) => _setVisibility(s.first)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _visibility == ClubVisibility.public
                ? l10n.clubVisibilityPublicHelp
                : l10n.clubVisibilityPrivateHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_visibility == ClubVisibility.private)
            SwitchListTile(
              key: const Key('club-field-listed'),
              contentPadding: EdgeInsets.zero,
              value: _isListed,
              onChanged: settingsEnabled
                  ? (v) => setState(() => _isListed = v)
                  : null,
              title: Text(l10n.clubFieldListed),
              subtitle: Text(l10n.clubFieldListedHelp),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.clubFieldJoinPolicy,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RadioGroup<ClubJoinPolicy>(
            groupValue: _joinPolicy,
            onChanged: (v) {
              if (settingsEnabled && v != null) {
                setState(() => _joinPolicy = v);
              }
            },
            child: Column(
              children: [
                for (final policy in ClubJoinPolicy.allowedFor(_visibility))
                  RadioListTile<ClubJoinPolicy>(
                    key: Key('club-join-${policy.dbValue}'),
                    contentPadding: EdgeInsets.zero,
                    value: policy,
                    enabled: settingsEnabled,
                    title: Text(policy.label(l10n)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('club-submit'),
            onPressed: _busy ? null : _submit,
            child: Text(_isEditing ? l10n.actionSave : l10n.clubCreate),
          ),
        ],
      ),
    );
  }
}

/// Logo et couverture (modification uniquement : le dossier de stockage est
/// l'identifiant du club). Réservé aux owner / admin, comme côté serveur.
class _ClubImagesSection extends ConsumerStatefulWidget {
  const _ClubImagesSection({required this.club});

  final Club club;

  @override
  ConsumerState<_ClubImagesSection> createState() => _ClubImagesSectionState();
}

class _ClubImagesSectionState extends ConsumerState<_ClubImagesSection> {
  ClubImageKind? _uploading;

  Future<void> _change(ClubImageKind kind) async {
    final media = ref.read(mediaRepositoryProvider);
    final clubs = ref.read(clubsRepositoryProvider);
    if (media == null || clubs == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: kind == ClubImageKind.logo ? 512 : 1600);
      if (image == null) return;
      image.validateFor(MediaBucket.clubMedia);
      setState(() => _uploading = kind);
      final previous = kind == ClubImageKind.logo
          ? widget.club.logoPath
          : widget.club.coverPath;
      final path = await media.upload(
        MediaBucket.clubMedia,
        folder: widget.club.id,
        baseName: kind.fileBaseName,
        image: image,
      );
      await clubs.setClubImage(widget.club.id, kind, path);
      if (previous != null) {
        await media
            .remove(MediaBucket.clubMedia, [previous])
            .catchError((_) {});
      }
      ref.refreshClubs(widget.club.id);
    } catch (error) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(describeError(context, error))),
          );
      }
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(ClubImageKind kind, String label, String? path) => ListTile(
      key: Key('club-image-${kind.fileBaseName}'),
      leading: Icon(
        kind == ClubImageKind.logo ? Icons.badge_outlined : Icons.panorama,
      ),
      title: Text(label),
      subtitle: Text(path == null ? l10n.clubImageNone : l10n.clubImageSet),
      trailing: _uploading == kind
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _uploading == null ? () => _change(kind) : null,
              child: Text(l10n.clubImageChange),
            ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.clubImagesTitle),
          tile(ClubImageKind.logo, l10n.clubLogo, widget.club.logoPath),
          tile(ClubImageKind.cover, l10n.clubCover, widget.club.coverPath),
        ],
      ),
    );
  }
}
