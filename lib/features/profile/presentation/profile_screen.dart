import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(currentUserIdProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: !signedIn
          ? EmptyState(
              icon: Icons.person_outline,
              title: l10n.profileSignedOutTitle,
              message: l10n.profileSignedOutBody,
            )
          : AsyncValueView(
              value: ref.watch(myProfileProvider),
              onRetry: () => ref.invalidate(myProfileProvider),
              data: (profile) {
                if (profile == null) {
                  return EmptyState(
                    icon: Icons.person_off_outlined,
                    title: l10n.profileMissingTitle,
                    message: l10n.profileMissingBody,
                  );
                }
                final theme = Theme.of(context);
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          profile.displayName.characters.first.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.displayName,
                      key: const Key('profile-display-name'),
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '@${profile.username}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile.city != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text(profile.city!),
                        ],
                      ),
                    ],
                    if (profile.bio != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(profile.bio!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      key: const Key('profile-edit'),
                      onPressed: () => context.push(AppRoutes.editProfile),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.profileEdit),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      key: const Key('profile-sign-out'),
                      onPressed: () => _signOut(context, ref),
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.signOutAction),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider)?.signOut();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(describeError(context, error))));
      }
    }
  }
}
