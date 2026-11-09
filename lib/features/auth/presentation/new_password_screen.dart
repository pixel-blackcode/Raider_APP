import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

/// Saisie d'un nouveau mot de passe : après un lien de réinitialisation, ou
/// depuis le profil.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.updatePassword(_password.text);
      ref.read(passwordRecoveryProvider).value = false;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.newPasswordSaved)));
      if (mounted) context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inRecovery = ref.watch(passwordRecoveryProvider).value;
    return AuthFormScaffold(
      title: l10n.newPasswordTitle,
      subtitle: l10n.newPasswordSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('new-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.fieldNewPassword,
                  helperText: l10n.fieldPasswordHelp,
                ),
                validator: (v) => AuthValidators.isValidPassword(v ?? '')
                    ? null
                    : l10n.validationPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('new-password-confirm'),
                controller: _confirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.fieldPasswordConfirm,
                ),
                validator: (v) => v == _password.text
                    ? null
                    : l10n.validationPasswordMismatch,
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('new-password-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.actionSave),
        ),
        if (!inRecovery) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.profile),
            child: Text(l10n.actionCancel),
          ),
        ],
      ],
    );
  }
}
