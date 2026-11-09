import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
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
      await repository.sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthFormScaffold(
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      children: [
        if (_sent)
          InfoCard(
            key: const Key('forgot-password-sent'),
            icon: Icons.mark_email_read_outlined,
            message: l10n.forgotPasswordSent,
          )
        else ...[
          Form(
            key: _formKey,
            child: TextFormField(
              key: const Key('forgot-password-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.fieldEmail),
              validator: (value) => AuthValidators.isValidEmail(value ?? '')
                  ? null
                  : l10n.validationEmail,
              onFieldSubmitted: (_) => _submit(),
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
            key: const Key('forgot-password-submit'),
            onPressed: _busy ? null : _submit,
            child: Text(l10n.forgotPasswordAction),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text(l10n.backToSignIn),
        ),
      ],
    );
  }
}
