import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/info_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../clubs/domain/club.dart';
import '../../rides/data/rides_providers.dart';
import '../../rides/domain/ride.dart';

/// Suppression définitive du compte.
///
/// Les clubs dont l'utilisateur est propriétaire et qui comptent d'autres
/// membres doivent d'abord être transférés (règle appliquée par le serveur,
/// rappelée ici). Les clubs sans autre membre sont supprimés.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const confirmationWord = 'SUPPRIMER';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _confirmation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      _confirmation.text.trim().toUpperCase() ==
      DeleteAccountScreen.confirmationWord;

  Future<void> _delete() async {
    final auth = ref.read(authRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    if (auth == null || userId == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      // Les fichiers ne peuvent être supprimés qu'avant le compte.
      await ref
          .read(mediaRepositoryProvider)
          ?.removeFolder(MediaBucket.avatars, userId);
      await auth.deleteAccount();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
      router.go(AppRoutes.signIn);
    } catch (error) {
      if (mounted) {
        messenger
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: AsyncValueView(
        value: ref.watch(myClubsProvider),
        onRetry: () => ref.invalidate(myClubsProvider),
        data: (memberships) {
          final blocking = [
            for (final m in memberships)
              if (m.role == ClubRole.owner && m.club.memberCount > 1) m.club,
          ];
          final userId = ref.watch(currentUserIdProvider);
          final blockingRides = [
            for (final r
                in ref.watch(myRidesProvider).value ?? const <MyRide>[])
              if (r.ride.organizerId == userId &&
                  const {
                    RideStatus.published,
                    RideStatus.locked,
                    RideStatus.inProgress,
                  }.contains(r.ride.status) &&
                  r.ride.participantCount > 1)
                r.ride,
          ];
          final soloClubs = [
            for (final m in memberships)
              if (m.role == ClubRole.owner && m.club.memberCount <= 1) m.club,
          ];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(l10n.deleteAccountIntro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              InfoCard(
                icon: Icons.warning_amber_outlined,
                color: theme.colorScheme.error,
                message: l10n.deleteAccountConsequences,
              ),
              if (soloClubs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoCard(
                  icon: Icons.groups_outlined,
                  message: l10n.deleteAccountSoloClubs(
                    soloClubs.map((c) => c.name).join(', '),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (blocking.isNotEmpty || blockingRides.isNotEmpty) ...[
                if (blocking.isNotEmpty)
                  InfoCard(
                    key: const Key('delete-account-blocked'),
                    icon: Icons.block,
                    title: l10n.deleteAccountBlockedTitle,
                    message: l10n.deleteAccountBlockedBody(
                      blocking.map((c) => c.name).join(', '),
                    ),
                  ),
                if (blockingRides.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InfoCard(
                    key: const Key('delete-account-blocked-rides'),
                    icon: Icons.route,
                    title: l10n.deleteAccountBlockedRidesTitle,
                    message: l10n.deleteAccountBlockedRidesBody(
                      blockingRides.map((r) => r.title).join(', '),
                    ),
                  ),
                ],
              ] else ...[
                TextField(
                  key: const Key('delete-account-confirm'),
                  controller: _confirmation,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.deleteAccountTypeToConfirm(
                      DeleteAccountScreen.confirmationWord,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('delete-account-submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: _confirmed && !_busy ? _delete : null,
                  child: Text(l10n.deleteAccountAction),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
