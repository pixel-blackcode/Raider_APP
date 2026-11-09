import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_validators.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEdit)),
      body: AsyncValueView(
        value: ref.watch(myProfileProvider),
        onRetry: () => ref.invalidate(myProfileProvider),
        data: (profile) => profile == null
            ? const SizedBox.shrink()
            : _EditProfileForm(profile: profile),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _displayName = TextEditingController(
    text: widget.profile.displayName,
  );
  late final _username = TextEditingController(text: widget.profile.username);
  late final _city = TextEditingController(text: widget.profile.city);
  late final _bio = TextEditingController(text: widget.profile.bio);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_displayName, _username, _city, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final repository = ref.read(profileRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await repository.updateProfile(
        widget.profile.id,
        ProfileUpdate(
          username: AuthValidators.normalizeUsername(_username.text),
          displayName: _displayName.text,
          city: _city.text,
          bio: _bio.text,
        ),
      );
      ref.invalidate(myProfileProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeError(context, error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('profile-field-display-name'),
            controller: _displayName,
            decoration: InputDecoration(labelText: l10n.fieldDisplayName),
            validator: (v) => AuthValidators.isValidDisplayName(v ?? '')
                ? null
                : l10n.validationDisplayName,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _username,
            decoration: InputDecoration(
              labelText: l10n.fieldUsername,
              helperText: l10n.fieldUsernameHelp,
              prefixText: '@',
            ),
            validator: (v) =>
                AuthValidators.isValidUsername(
                  AuthValidators.normalizeUsername(v ?? ''),
                )
                ? null
                : l10n.validationUsername,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _city,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.fieldCity),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _bio,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.fieldBio),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('profile-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}
