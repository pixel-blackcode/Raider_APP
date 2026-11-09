import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../domain/auth_session.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _displayName,
      _username,
      _email,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await repository.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
        username: AuthValidators.normalizeUsername(_username.text),
      );
      if (!mounted) return;
      if (outcome == SignUpOutcome.confirmationRequired) {
        context.go(
          Uri(
            path: AppRoutes.signIn,
            queryParameters: {'notice': l10n.signUpCheckEmail},
          ).toString(),
        );
      }
      // Sinon la session est ouverte et la garde du routeur redirige.
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(authRepositoryProvider) != null;

    return AuthFormScaffold(
      title: l10n.signUpTitle,
      subtitle: l10n.signUpSubtitle,
      children: [
        if (!available) const BackendStatusCard(),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('sign-up-display-name'),
                  controller: _displayName,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(labelText: l10n.fieldDisplayName),
                  validator: (value) =>
                      AuthValidators.isValidDisplayName(value ?? '')
                      ? null
                      : l10n.validationDisplayName,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('sign-up-username'),
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  decoration: InputDecoration(
                    labelText: l10n.fieldUsername,
                    helperText: l10n.fieldUsernameHelp,
                    prefixText: '@',
                  ),
                  validator: (value) =>
                      AuthValidators.isValidUsername(
                        AuthValidators.normalizeUsername(value ?? ''),
                      )
                      ? null
                      : l10n.validationUsername,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('sign-up-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.fieldEmail),
                  validator: (value) => AuthValidators.isValidEmail(value ?? '')
                      ? null
                      : l10n.validationEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('sign-up-password'),
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.fieldPassword,
                    helperText: l10n.fieldPasswordHelp,
                  ),
                  validator: (value) =>
                      AuthValidators.isValidPassword(value ?? '')
                      ? null
                      : l10n.validationPassword,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('sign-up-confirm'),
                  controller: _confirm,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.fieldPasswordConfirm,
                  ),
                  validator: (value) => value == _password.text
                      ? null
                      : l10n.validationPasswordMismatch,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            key: const Key('sign-up-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('sign-up-submit'),
          onPressed: available && !_busy ? _submit : null,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signUpAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text(l10n.signUpHaveAccount),
        ),
      ],
    );
  }
}
