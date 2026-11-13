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
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/data/community_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

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
              data: (profile) => profile == null
                  ? EmptyState(
                      icon: Icons.person_off_outlined,
                      title: l10n.profileMissingTitle,
                      message: l10n.profileMissingBody,
                    )
                  : _ProfileBody(profile: profile),
            ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _uploading = false;

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(describeError(context, error))));
  }

  Future<void> _changePhoto() async {
    final media = ref.read(mediaRepositoryProvider);
    final profiles = ref.read(profileRepositoryProvider);
    if (media == null || profiles == null) return;
    try {
      final image = await ref.read(photoPickerProvider).pick(maxDimension: 512);
      if (image == null) return;
      image.validateFor(MediaBucket.avatars);
      setState(() => _uploading = true);
      final previous = widget.profile.avatarPath;
      final path = await media.upload(
        MediaBucket.avatars,
        folder: widget.profile.id,
        baseName: 'avatar',
        image: image,
      );
      await profiles.setAvatarPath(widget.profile.id, path);
      if (previous != null) {
        // Échec non bloquant : l'ancien fichier n'est plus référencé.
        await media.remove(MediaBucket.avatars, [previous]).catchError((_) {});
      }
      ref.invalidate(myProfileProvider);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final media = ref.read(mediaRepositoryProvider);
    final profiles = ref.read(profileRepositoryProvider);
    final path = widget.profile.avatarPath;
    if (media == null || profiles == null || path == null) return;
    try {
      await profiles.setAvatarPath(widget.profile.id, null);
      await media.remove(MediaBucket.avatars, [path]).catchError((_) {});
      ref.invalidate(myProfileProvider);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider)?.signOut();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = widget.profile;
    final media = ref.watch(mediaRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: Stack(
            children: [
              RemoteAvatar(
                key: const Key('profile-avatar'),
                label: profile.displayName,
                image: media?.imageProvider(
                  MediaBucket.avatars,
                  profile.avatarPath,
                ),
                radius: 48,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _uploading
                    ? const SizedBox.square(
                        dimension: 36,
                        child: CircularProgressIndicator(),
                      )
                    : PopupMenuButton<String>(
                        key: const Key('profile-photo-menu'),
                        tooltip: l10n.profilePhotoChange,
                        onSelected: (value) =>
                            value == 'change' ? _changePhoto() : _removePhoto(),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'change',
                            child: Text(l10n.profilePhotoChange),
                          ),
                          if (profile.avatarPath != null)
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(l10n.profilePhotoRemove),
                            ),
                        ],
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
              ),
            ],
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
        SectionHeader(title: l10n.profileAccountSection),
        ListTile(
          key: const Key('profile-privacy'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.shield_outlined),
          title: Text(l10n.privacyTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.privacySettings),
        ),
        ListTile(
          key: const Key('profile-blocked'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.block),
          title: Text(l10n.blockedUsersTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.blockedUsers),
        ),
        Consumer(
          builder: (context, ref, _) =>
              (ref.watch(amIModeratorProvider).value ?? false)
              ? ListTile(
                  key: const Key('profile-moderation'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l10n.moderationTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.moderation),
                )
              : const SizedBox.shrink(),
        ),
        ListTile(
          key: const Key('profile-change-password'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.password_outlined),
          title: Text(l10n.profileChangePassword),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.newPassword),
        ),
        ListTile(
          key: const Key('profile-sign-out'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout),
          title: Text(l10n.signOutAction),
          onTap: _signOut,
        ),
        ListTile(
          key: const Key('profile-delete-account'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.delete_forever_outlined,
            color: theme.colorScheme.error,
          ),
          title: Text(
            l10n.deleteAccountTitle,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          onTap: () => context.push(AppRoutes.deleteAccount),
        ),
      ],
    );
  }
}
