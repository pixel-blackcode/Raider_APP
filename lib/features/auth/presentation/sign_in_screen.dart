import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.notice});

  /// Message informatif affiché au-dessus du formulaire (ex. après inscription).
  final String? notice;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.signIn(email: _email.text, password: _password.text);
      // La redirection est assurée par la garde du routeur.
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
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
      children: [
        if (!available) const BackendStatusCard(),
        if (widget.notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              widget.notice!,
              key: const Key('sign-in-notice'),
              textAlign: TextAlign.center,
            ),
          ),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('sign-in-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.fieldEmail),
                  validator: (value) => AuthValidators.isValidEmail(value ?? '')
                      ? null
                      : l10n.validationEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('sign-in-password'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.fieldPassword),
                  validator: (value) =>
                      (value ?? '').isEmpty ? l10n.validationRequired : null,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            key: const Key('sign-in-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('sign-in-submit'),
          onPressed: available && !_busy ? _submit : null,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signInAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          key: const Key('sign-in-forgot'),
          onPressed: () => context.go(AppRoutes.forgotPassword),
          child: Text(l10n.signInForgotPassword),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.signUp),
          child: Text(l10n.signInNoAccount),
        ),
      ],
    );
  }
}
