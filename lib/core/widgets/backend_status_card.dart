import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../backend/backend_providers.dart';
import '../backend/backend_status.dart';
import '../theme/app_colors.dart';
import 'info_card.dart';

/// Affiche honnêtement l'état du backend.
///
/// Avec [hideWhenReady], la carte disparaît lorsque le client est initialisé
/// (utilisé sur l'écran d'accueil).
class BackendStatusCard extends ConsumerWidget {
  const BackendStatusCard({super.key, this.hideWhenReady = false});

  final bool hideWhenReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final status = ref.watch(backendStatusProvider);

    return switch (status) {
      BackendReady() when hideWhenReady => const SizedBox.shrink(),
      BackendReady() => InfoCard(
        key: const Key('backend-status-ready'),
        icon: Icons.cloud_done_outlined,
        title: l10n.backendReadyTitle,
        message: l10n.backendReadyBody,
        color: colors.success,
      ),
      BackendNotConfigured() => InfoCard(
        key: const Key('backend-status-not-configured'),
        icon: Icons.cloud_off_outlined,
        title: l10n.backendNotConfiguredTitle,
        message: l10n.backendNotConfiguredBody,
        color: colors.warning,
      ),
      BackendFailed() => InfoCard(
        key: const Key('backend-status-failed'),
        icon: Icons.error_outline,
        title: l10n.backendFailedTitle,
        message: l10n.backendFailedBody,
        color: colors.sos,
      ),
    };
  }
}
