import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    PrivacySettings settings,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    final repository = ref.read(profileRepositoryProvider);
    if (userId == null || repository == null) return;
    try {
      await repository.savePrivacySettings(userId, settings);
      ref.invalidate(privacySettingsProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(describeError(context, error))),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: AsyncValueView(
        value: ref.watch(privacySettingsProvider),
        onRetry: () => ref.invalidate(privacySettingsProvider),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SwitchListTile(
              key: const Key('privacy-discoverable'),
              contentPadding: EdgeInsets.zero,
              value: settings.discoverable,
              title: Text(l10n.privacyDiscoverable),
              subtitle: Text(l10n.privacyDiscoverableHelp),
              onChanged: (value) =>
                  _save(context, ref, settings.copyWith(discoverable: value)),
            ),
            SwitchListTile(
              key: const Key('privacy-invitations'),
              contentPadding: EdgeInsets.zero,
              value: settings.allowClubInvitations,
              title: Text(l10n.privacyInvitations),
              subtitle: Text(l10n.privacyInvitationsHelp),
              onChanged: (value) => _save(
                context,
                ref,
                settings.copyWith(allowClubInvitations: value),
              ),
            ),
            SwitchListTile(
              key: const Key('privacy-ride-invitations'),
              contentPadding: EdgeInsets.zero,
              value: settings.allowRideInvitations,
              title: Text(l10n.privacyRideInvitations),
              subtitle: Text(l10n.privacyRideInvitationsHelp),
              onChanged: (value) => _save(
                context,
                ref,
                settings.copyWith(allowRideInvitations: value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              icon: Icons.lock_outline,
              message: l10n.privacyEmailNotice,
            ),
          ],
        ),
      ),
    );
  }
}
