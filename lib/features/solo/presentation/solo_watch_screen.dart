import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../../sos/data/emergency.dart';
import '../data/solo_repository.dart';
import '../domain/solo.dart';
import 'solo_labels.dart';

/// Vue d'un proche : où en est le motard qui rentre seul.
class SoloWatchScreen extends ConsumerStatefulWidget {
  const SoloWatchScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<SoloWatchScreen> createState() => _SoloWatchScreenState();
}

class _SoloWatchScreenState extends ConsumerState<SoloWatchScreen> {
  Timer? _timer;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Actualisation régulière tant que l'écran est ouvert.
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(soloTripsProvider),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _ask({required bool position}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(soloRepositoryProvider)!
          .askNews(widget.tripId, position: position);
      if (mounted) showSnack(context, l10n.soloAskSent);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(soloTripsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.soloTitle)),
      body: AsyncValueView(
        value: trips,
        onRetry: () => ref.invalidate(soloTripsProvider),
        data: (list) {
          SoloTrip? trip;
          for (final t in list) {
            if (t.id == widget.tripId) trip = t;
          }
          if (trip == null) {
            return EmptyState(
              icon: Icons.route_outlined,
              title: l10n.soloTripNotFound,
              message: l10n.soloTripNotFoundBody,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(soloTripsProvider),
            child: _body(context, trip),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, SoloTrip t) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final now = DateTime.now().toUtc();
    final late = t.isLate(now);
    final bg = late
        ? colors.sos
        : t.status == SoloTripStatus.arrived
        ? colors.success
        : AppColors.marine;
    final emergency = ref.watch(emergencyNumberProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.destination == null
                      ? l10n.soloTravelerTitle(t.displayName)
                      : l10n.soloTravelerTo(t.displayName, t.destination!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  soloStatusText(l10n, t, now),
                  key: const Key('solo-watch-status'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.soloStartedAt(soloTime(t.startedAt)),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (t.lastOkAt != null)
                  Text(
                    l10n.soloLastNews(timeAgo(l10n, t.lastOkAt!, now: now)),
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(
              t.hasPosition
                  ? l10n.soloLastPosition(
                      timeAgo(l10n, t.lastPositionAt ?? now, now: now),
                    )
                  : l10n.soloNoPosition,
            ),
            subtitle: t.active && t.shareLocation
                ? Text(l10n.soloSharingLive)
                : null,
            trailing: t.hasPosition
                ? FilledButton.tonal(
                    key: const Key('solo-open-map'),
                    onPressed: () => ref
                        .read(externalActionsProvider)
                        .openMap(t.lastLat!, t.lastLng!),
                    child: Text(l10n.soloOpenMap),
                  )
                : null,
          ),
        ),
        if (t.active) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('solo-ask-news'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
            onPressed: _busy ? null : () => _ask(position: false),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.soloAskNews),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('solo-ask-position'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
            onPressed: _busy ? null : () => _ask(position: true),
            icon: const Icon(Icons.my_location),
            label: Text(l10n.soloAskPosition),
          ),
          if (late) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.soloLateHelp, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('solo-call-emergency'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                foregroundColor: colors.sos,
              ),
              onPressed: () =>
                  ref.read(externalActionsProvider).dial(emergency),
              icon: const Icon(Icons.call),
              label: Text(l10n.soloCallEmergency(emergency)),
            ),
          ],
        ],
      ],
    );
  }
}
