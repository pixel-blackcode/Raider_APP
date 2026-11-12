import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../rides/data/rides_providers.dart';
import '../../rides/domain/ride.dart';
import '../data/emergency.dart';
import '../data/sos_outbox.dart';
import '../data/sos_repository.dart';
import '../domain/sos.dart';
import 'sos_banner.dart';
import 'sos_labels.dart';

/// Écran SOS d'une balade en cours : déclencher une alerte, suivre sa
/// transmission, voir et prendre en charge les alertes des autres.
/// Grands boutons, peu d'étapes : on peut être en situation de stress.
class SosScreen extends ConsumerWidget {
  const SosScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(rideDetailProvider(rideId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sosTitle)),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(rideDetailProvider(rideId)),
        data: (d) {
          if (d == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: l10n.errorRideNotFound,
              message: l10n.rideNotFoundBody,
            );
          }
          final allowed =
              d.myStatus == ParticipantStatus.confirmed || d.canManage;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const _Disclaimer(),
              const SizedBox(height: AppSpacing.sm),
              const _CallButton(),
              const SizedBox(height: AppSpacing.md),
              if (d.ride.status != RideStatus.inProgress)
                EmptyState(
                  icon: Icons.flag_outlined,
                  title: l10n.convoyNotRunningTitle,
                  message: l10n.sosNotRunningBody,
                )
              else if (!allowed)
                EmptyState(
                  icon: Icons.lock_outline,
                  title: l10n.errorNotAllowed,
                  message: l10n.sosParticipantsOnly,
                )
              else
                _SosBody(detail: d),
            ],
          );
        },
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RiderColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(AppLocalizations.of(context).sosDisclaimer)),
        ],
      ),
    );
  }
}

class _CallButton extends ConsumerWidget {
  const _CallButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final number = ref.watch(emergencyNumberProvider);
    return SizedBox(
      height: AppSpacing.convoyTouchTarget,
      child: OutlinedButton.icon(
        key: const Key('sos-call'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.sos,
          side: BorderSide(color: colors.sos, width: 2),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
        onPressed: () async {
          final ok = await ref.read(externalActionsProvider).dial(number);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.sosCallFailed(number))),
              );
          }
        },
        icon: const Icon(Icons.phone_in_talk, size: 28),
        label: Text(l10n.sosCall(number)),
      ),
    );
  }
}

class _SosBody extends ConsumerWidget {
  const _SosBody({required this.detail});

  final RideDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rideId = detail.ride.id;
    final me = ref.watch(currentUserIdProvider);
    final alerts = ref.watch(rideSosAlertsProvider(rideId)).value ?? const [];
    final acks = ref.watch(rideSosAcksProvider(rideId)).value ?? const [];
    final outgoing = ref.watch(sosOutboxProvider)[rideId];
    final names = {
      for (final p in detail.participants)
        p.userId: p.displayName.isEmpty ? l10n.profileHidden : p.displayName,
    };

    // Mon alerte active : celle du serveur, sinon celle que je viens
    // d'envoyer (le flux temps réel peut avoir un léger retard).
    SosAlert? mine;
    for (final a in alerts.reversed) {
      if (a.userId == me && a.isActive) {
        mine = a;
        break;
      }
    }
    if (mine == null &&
        outgoing?.delivery == SosDelivery.sent &&
        !alerts.any((a) => a.id == outgoing!.alert!.id && !a.isActive)) {
      mine = outgoing!.alert;
    }
    final others = alerts
        .where((a) => a.userId != me && a.isActive)
        .toList()
        .reversed
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (others.isNotEmpty) ...[
          SectionHeader(title: l10n.sosIncomingTitle),
          for (final a in others)
            _IncomingAlertCard(
              alert: a,
              name: names[a.userId] ?? l10n.profileHidden,
              acks: acks.where((k) => k.alertId == a.id).toList(),
              me: me,
              canManage: detail.canManage,
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (outgoing != null && outgoing.delivery != SosDelivery.sent)
          _PendingCard(outgoing: outgoing)
        else if (mine != null)
          _MyAlertCard(
            alert: mine,
            ackNames: [
              for (final k in acks.where((k) => k.alertId == mine!.id))
                names[k.userId] ?? l10n.profileHidden,
            ],
          )
        else
          _KindPicker(rideId: rideId),
      ],
    );
  }
}

class _KindPicker extends ConsumerWidget {
  const _KindPicker({required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final theme = Theme.of(context);

    Future<void> pick(SosKind kind) async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.sosConfirmTitle(kind.label(l10n)),
        message: l10n.sosConfirmBody,
        confirmLabel: l10n.sosConfirmSend,
      );
      if (!confirmed) return;
      await ref.read(sosOutboxProvider.notifier).send(rideId, kind);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sosChooseKind, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final kind in SosKind.values) ...[
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              key: Key('sos-kind-${kind.dbValue}'),
              style: FilledButton.styleFrom(
                backgroundColor: kind == SosKind.delay
                    ? theme.colorScheme.secondary
                    : colors.sos,
                foregroundColor: kind == SosKind.delay
                    ? theme.colorScheme.onSecondary
                    : colors.onSos,
                textStyle: theme.textTheme.titleLarge,
              ),
              onPressed: () => pick(kind),
              icon: Icon(kind.icon, size: 30),
              label: Text(kind.label(l10n)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Alerte en cours d'envoi ou non transmise : jamais affichée comme envoyée.
class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.outgoing});

  final OutgoingSos outgoing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final theme = Theme.of(context);
    final failed = outgoing.delivery == SosDelivery.failed;
    return Card(
      key: Key(failed ? 'sos-status-failed' : 'sos-status-sending'),
      color: failed ? colors.sos : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  outgoing.kind.icon,
                  color: failed ? colors.onSos : colors.sos,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  outgoing.kind.label(l10n),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: failed ? colors.onSos : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!failed) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.sosSending),
            ] else ...[
              Text(
                l10n.sosFailedTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSos,
                ),
              ),
              Text(l10n.sosFailedBody, style: TextStyle(color: colors.onSos)),
              if (outgoing.error != null)
                Text(
                  describeError(context, outgoing.error!),
                  key: const Key('sos-failed-reason'),
                  style: TextStyle(color: colors.onSos),
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: AppSpacing.convoyTouchTarget,
                child: FilledButton.icon(
                  key: const Key('sos-retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onSos,
                    foregroundColor: colors.sos,
                  ),
                  onPressed: () => ref
                      .read(sosOutboxProvider.notifier)
                      .retry(outgoing.rideId),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.sosRetry),
                ),
              ),
              TextButton(
                key: const Key('sos-abandon'),
                style: TextButton.styleFrom(foregroundColor: colors.onSos),
                onPressed: () =>
                    ref.read(sosOutboxProvider.notifier).clear(outgoing.rideId),
                child: Text(l10n.sosAbandon),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyAlertCard extends ConsumerStatefulWidget {
  const _MyAlertCard({required this.alert, required this.ackNames});

  final SosAlert alert;
  final List<String> ackNames;

  @override
  ConsumerState<_MyAlertCard> createState() => _MyAlertCardState();
}

class _MyAlertCardState extends ConsumerState<_MyAlertCard> {
  bool _busy = false;

  Future<void> _close(SosStatus status) async {
    setState(() => _busy = true);
    try {
      await ref.read(sosRepositoryProvider)!.close(widget.alert.id, status);
      ref.read(sosOutboxProvider.notifier).clear(widget.alert.rideId);
      ref.invalidate(rideSosAlertsProvider(widget.alert.rideId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
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
    final colors = Theme.of(context).extension<RiderColors>()!;
    final theme = Theme.of(context);
    final a = widget.alert;
    final position = switch (a.positionSource) {
      'device' => l10n.sosPositionDevice,
      'convoy' => l10n.sosPositionConvoy,
      _ => l10n.sosPositionNone,
    };
    return Card(
      key: const Key('sos-status-sent'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: colors.success, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.sosSentTitle(sosTime(a.createdAt)),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${a.kind.label(l10n)} · $position'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.ackNames.isEmpty
                  ? l10n.sosNoAckYet
                  : l10n.sosAckedBy(widget.ackNames.join(', ')),
              key: const Key('sos-ack-summary'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('sos-cancel'),
                    onPressed: _busy ? null : () => _close(SosStatus.cancelled),
                    child: Text(l10n.sosCancelMine),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('sos-resolved'),
                    onPressed: _busy ? null : () => _close(SosStatus.resolved),
                    child: Text(l10n.sosResolveMine),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingAlertCard extends ConsumerStatefulWidget {
  const _IncomingAlertCard({
    required this.alert,
    required this.name,
    required this.acks,
    required this.me,
    required this.canManage,
  });

  final SosAlert alert;
  final String name;
  final List<SosAck> acks;
  final String? me;
  final bool canManage;

  @override
  ConsumerState<_IncomingAlertCard> createState() => _IncomingAlertCardState();
}

class _IncomingAlertCardState extends ConsumerState<_IncomingAlertCard> {
  bool _busy = false;
  bool _ackedLocally = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
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
    final colors = Theme.of(context).extension<RiderColors>()!;
    final theme = Theme.of(context);
    final a = widget.alert;
    final acked =
        _ackedLocally || widget.acks.any((k) => k.userId == widget.me);
    return Card(
      key: Key('sos-incoming-${a.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.sos, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(a.kind.icon, color: colors.sos, size: 30),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.sosIncomingFrom(a.kind.label(l10n), widget.name),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            Text(l10n.sosSince(sosTime(a.createdAt))),
            if (a.message != null) Text('« ${a.message} »'),
            if (widget.acks.isNotEmpty)
              Text(l10n.sosAckedBy('${widget.acks.length}')),
            const SizedBox(height: AppSpacing.sm),
            if (a.hasPosition)
              OutlinedButton.icon(
                key: Key('sos-map-${a.id}'),
                onPressed: () =>
                    ref.read(externalActionsProvider).openMap(a.lat!, a.lng!),
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.sosOpenMap),
              )
            else
              Text(l10n.sosPositionNone),
            const SizedBox(height: AppSpacing.sm),
            if (acked)
              Row(
                key: Key('sos-acked-${a.id}'),
                children: [
                  Icon(Icons.done_all, color: colors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.sosAcked),
                ],
              )
            else
              SizedBox(
                height: AppSpacing.convoyTouchTarget,
                child: FilledButton.icon(
                  key: Key('sos-ack-${a.id}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.sos,
                    foregroundColor: colors.onSos,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await ref
                              .read(sosRepositoryProvider)!
                              .acknowledge(a.id);
                          ref.read(dismissedSosProvider.notifier).dismiss(a.id);
                          if (mounted) setState(() => _ackedLocally = true);
                        }),
                  icon: const Icon(Icons.pan_tool_alt),
                  label: Text(l10n.sosAck),
                ),
              ),
            if (widget.canManage)
              TextButton(
                key: Key('sos-resolve-${a.id}'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await ref
                            .read(sosRepositoryProvider)!
                            .close(a.id, SosStatus.resolved);
                        ref.invalidate(rideSosAlertsProvider(a.rideId));
                      }),
                child: Text(l10n.sosResolveByManager),
              ),
          ],
        ),
      ),
    );
  }
}
