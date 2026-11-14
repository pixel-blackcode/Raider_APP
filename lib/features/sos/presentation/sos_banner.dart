import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/sound/alert_sound.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/sos_repository.dart';
import '../domain/sos.dart';
import 'sos_labels.dart';

/// Alertes récentes visibles (temps réel), pour la personne connectée.
final recentSosProvider = StreamProvider<List<SosAlert>>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  if (repo == null || me == null) return Stream.value(const []);
  return repo.watchRecentAlerts();
});

/// Alertes masquées sur cet appareil (accusé de réception ou « Masquer »).
class DismissedSos extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void dismiss(String id) => state = {...state, id};
}

final dismissedSosProvider = NotifierProvider<DismissedSos, Set<String>>(
  DismissedSos.new,
);

/// Alertes des AUTRES, actives et non masquées : à signaler partout.
final incomingSosProvider = Provider<List<SosAlert>>((ref) {
  final me = ref.watch(currentUserIdProvider);
  final dismissed = ref.watch(dismissedSosProvider);
  final alerts = ref.watch(recentSosProvider).value ?? const [];
  return alerts
      .where((a) => a.isActive && a.userId != me && !dismissed.contains(a.id))
      .toList()
      .reversed
      .toList();
});

/// Bandeau rouge affiché au-dessus de toute l'application quand une
/// alerte arrive (application ouverte uniquement, D-38) : son et vibration.
class SosAlertsOverlay extends ConsumerStatefulWidget {
  const SosAlertsOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SosAlertsOverlay> createState() => _SosAlertsOverlayState();
}

class _SosAlertsOverlayState extends ConsumerState<SosAlertsOverlay> {
  final _signaled = <String>{};

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingSosProvider, (_, next) {
      final fresh = next.where((a) => !_signaled.contains(a.id)).toList();
      if (fresh.isEmpty) return;
      _signaled.addAll(fresh.map((a) => a.id));
      // Le SOS sonne toujours, même si les sons sont désactivés.
      ref.read(alertSoundProvider).alert();
      HapticFeedback.heavyImpact();
    });
    final incoming = ref.watch(incomingSosProvider);
    if (incoming.isEmpty) return widget.child;

    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final latest = incoming.first;
    return Column(
      children: [
        Material(
          key: const Key('sos-banner'),
          color: colors.sos,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(Icons.sos, color: colors.onSos, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sosBanner(latest.kind.label(l10n)),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSos),
                        ),
                        if (incoming.length > 1)
                          Text(
                            l10n.sosBannerMore(incoming.length - 1),
                            style: TextStyle(color: colors.onSos),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('sos-banner-open'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSos,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => ref
                        .read(routerProvider)
                        .push(AppRoutes.sos(latest.rideId)),
                    child: Text(l10n.sosBannerView),
                  ),
                  TextButton(
                    key: const Key('sos-banner-dismiss'),
                    style: TextButton.styleFrom(foregroundColor: colors.onSos),
                    onPressed: () => ref
                        .read(dismissedSosProvider.notifier)
                        .dismiss(latest.id),
                    child: Text(l10n.sosBannerDismiss),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
