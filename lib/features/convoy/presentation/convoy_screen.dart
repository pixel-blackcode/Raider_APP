import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../rides/data/rides_providers.dart';
import '../../rides/domain/ride.dart';
import '../data/convoy_repository.dart';
import '../data/location_service.dart';
import '../domain/convoy.dart';
import 'convoy_map.dart';

final convoyPositionsProvider = StreamProvider.autoDispose
    .family<List<RiderPosition>, String>((ref, rideId) {
      final repo = ref.watch(convoyRepositoryProvider);
      if (repo == null) return Stream.value(const []);
      return repo.watchPositions(rideId);
    });

final convoyRolesProvider = FutureProvider.autoDispose
    .family<Map<ConvoyRole, String>, String>((ref, rideId) async {
      final repo = ref.watch(convoyRepositoryProvider);
      if (repo == null) return const {};
      return repo.roles(rideId);
    });

/// État de l'envoi de MA position.
enum ShareState { off, starting, on, failing }

/// Mode Convoi : carte, participants, partage volontaire de la position.
/// Interface volontairement réduite (grands boutons, peu d'actions) : on ne
/// manipule pas le téléphone en roulant.
class ConvoyScreen extends ConsumerStatefulWidget {
  const ConvoyScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<ConvoyScreen> createState() => _ConvoyScreenState();
}

class _ConvoyScreenState extends ConsumerState<ConvoyScreen> {
  ShareState _share = ShareState.off;
  StreamSubscription<RiderPosition>? _sub;
  DateTime? _lastSent;
  DateTime? _lastAttempt;
  String? _shareError;
  Timer? _tick;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    // Rafraîchit l'ancienneté des positions affichées.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
    _restoreSharing();
  }

  Future<void> _restoreSharing() async {
    final repo = ref.read(convoyRepositoryProvider);
    final uid = ref.read(currentUserIdProvider);
    if (repo == null || uid == null) return;
    try {
      if (await repo.isSharing(widget.rideId, uid) && mounted) {
        await _startPublishing();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    // Quitter l'écran arrête l'envoi (pas de suivi permanent promis).
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_share == ShareState.off) {
      await _enable();
    } else {
      await _disable();
    }
  }

  Future<void> _enable() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _share = ShareState.starting;
      _shareError = null;
    });
    final access = await ref.read(locationServiceProvider).ensurePermission();
    if (!mounted) return;
    if (access != LocationAccess.granted) {
      setState(() {
        _share = ShareState.off;
        _shareError = switch (access) {
          LocationAccess.serviceDisabled => l10n.convoyLocationOff,
          LocationAccess.deniedForever => l10n.convoyLocationDeniedForever,
          _ => l10n.convoyLocationDenied,
        };
      });
      return;
    }
    try {
      await ref
          .read(convoyRepositoryProvider)!
          .setSharing(widget.rideId, enabled: true);
      await _startPublishing();
    } catch (error) {
      if (mounted) {
        setState(() {
          _share = ShareState.off;
          _shareError = describeError(context, error);
        });
      }
    }
  }

  Future<void> _startPublishing() async {
    unawaited(_sub?.cancel());
    setState(() => _share = ShareState.on);
    _sub = ref.read(locationServiceProvider).positions().listen(_onPosition);
  }

  Future<void> _onPosition(RiderPosition p) async {
    final now = DateTime.now();
    final last = _lastAttempt;
    if (last != null &&
        now.difference(last) <
            PublishCadence.intervalFor(speedMps: p.speedMps)) {
      return;
    }
    _lastAttempt = now;
    try {
      await ref.read(convoyRepositoryProvider)!.publish(widget.rideId, p);
      if (mounted) {
        setState(() {
          _lastSent = DateTime.now().toUtc();
          _share = ShareState.on;
          _shareError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      final code = AppException.from(error).code;
      if (code == 'too_frequent') return;
      setState(() {
        // La balade est terminée ou l'accès retiré : on arrête vraiment.
        if (code == 'ride_not_in_progress' ||
            code == 'not_participant' ||
            code == 'sharing_disabled') {
          _sub?.cancel();
          _share = ShareState.off;
        } else {
          _share = ShareState.failing;
        }
        _shareError = describeError(context, error);
      });
    }
  }

  Future<void> _disable() async {
    // Ne pas attendre la fermeture du flux GPS : l'arrêt doit être immédiat.
    unawaited(_sub?.cancel());
    _sub = null;
    setState(() => _share = ShareState.off);
    try {
      await ref
          .read(convoyRepositoryProvider)
          ?.setSharing(widget.rideId, enabled: false);
    } catch (error) {
      if (mounted) setState(() => _shareError = describeError(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(rideDetailProvider(widget.rideId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.convoyTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              key: const Key('convoy-sos'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .extension<RiderColors>()!
                    .sos,
                foregroundColor: Theme.of(context)
                    .extension<RiderColors>()!
                    .onSos,
              ),
              onPressed: () => context.push(AppRoutes.sos(widget.rideId)),
              icon: const Icon(Icons.sos),
              label: Text(l10n.sosOpen),
            ),
          ),
        ],
      ),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(rideDetailProvider(widget.rideId)),
        data: (d) {
          if (d == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: l10n.errorRideNotFound,
              message: l10n.rideNotFoundBody,
            );
          }
          if (d.ride.status != RideStatus.inProgress) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: l10n.convoyNotRunningTitle,
              message: l10n.convoyNotRunningBody,
            );
          }
          if (d.myStatus != ParticipantStatus.confirmed && !d.canManage) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: l10n.errorNotAllowed,
              message: l10n.convoyParticipantsOnly,
            );
          }
          return _buildConvoy(context, d);
        },
      ),
    );
  }

  Widget _buildConvoy(BuildContext context, RideDetail d) {
    final l10n = AppLocalizations.of(context);
    final positions =
        ref.watch(convoyPositionsProvider(widget.rideId)).value ?? const [];
    final roles =
        ref.watch(convoyRolesProvider(widget.rideId)).value ?? const {};
    final me = ref.watch(currentUserIdProvider);
    final members = buildConvoy(
      participants: {
        for (final p in d.participants)
          p.userId: p.userId == me
              ? l10n.convoyYou
              : (p.displayName.isEmpty ? l10n.profileHidden : p.displayName),
      },
      positions: positions,
      roles: roles,
      now: _now,
    );
    final mapBuilder = ref.watch(convoyMapBuilderProvider);

    return Column(
      children: [
        _SafetyBanner(text: l10n.convoySafety),
        Expanded(flex: 3, child: mapBuilder(members, me)),
        _ShareBar(
          state: _share,
          lastSent: _lastSent,
          error: _shareError,
          onToggle: _toggle,
        ),
        Expanded(
          flex: 2,
          child: _MemberList(members: members, now: _now),
        ),
      ],
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RiderColors>()!;
    return Container(
      width: double.infinity,
      color: colors.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.state,
    required this.lastSent,
    required this.error,
    required this.onToggle,
  });

  final ShareState state;
  final DateTime? lastSent;
  final String? error;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final on = state == ShareState.on || state == ShareState.failing;
    final status = switch (state) {
      ShareState.off => l10n.convoySharingOff,
      ShareState.starting => l10n.convoySharingStarting,
      ShareState.on =>
        lastSent == null
            ? l10n.convoyWaitingFix
            : l10n.convoyLastSent(_hhmm(lastSent!)),
      ShareState.failing => l10n.convoyNotSent,
    };
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: AppSpacing.convoyTouchTarget,
              child: FilledButton.icon(
                key: const Key('convoy-share-toggle'),
                style: FilledButton.styleFrom(
                  backgroundColor: on ? colors.sos : theme.colorScheme.primary,
                  foregroundColor: on
                      ? colors.onSos
                      : theme.colorScheme.onPrimary,
                  textStyle: theme.textTheme.titleLarge,
                ),
                onPressed: state == ShareState.starting ? null : onToggle,
                icon: Icon(
                  on ? Icons.location_off : Icons.my_location,
                  size: 28,
                ),
                label: Text(
                  on ? l10n.convoyStopSharing : l10n.convoyStartSharing,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              status,
              key: const Key('convoy-share-status'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: state == ShareState.failing ? colors.sos : null,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (error != null)
              Text(
                error!,
                key: const Key('convoy-share-error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.sos, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

String _hhmm(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members, required this.now});

  final List<ConvoyMember> members;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final m = members[i];
        final role = switch (m.role) {
          ConvoyRole.leader => l10n.convoyRoleLeader,
          ConvoyRole.sweeper => l10n.convoyRoleSweeper,
          null => null,
        };
        String detail;
        Color? detailColor;
        if (!m.isSharing) {
          detail = l10n.convoyNotSharing;
        } else if (m.alert == ConvoyAlert.staleSignal) {
          detail = l10n.convoyStale(
            now.difference(m.position!.recordedAt).inMinutes,
          );
          detailColor = colors.stale;
        } else if (m.alert == ConvoyAlert.possiblySeparated) {
          detail = l10n.convoySeparated(
            (m.distanceToLeaderM! / 1000).toStringAsFixed(1),
          );
          detailColor = colors.warning;
        } else {
          detail = m.freshness == Freshness.live
              ? l10n.convoyLive
              : l10n.convoyAging;
          detailColor = m.freshness == Freshness.live ? colors.success : null;
        }
        return ListTile(
          key: Key('convoy-member-${m.userId}'),
          leading: Icon(
            m.role == ConvoyRole.leader
                ? Icons.flag
                : m.role == ConvoyRole.sweeper
                ? Icons.shield_outlined
                : Icons.two_wheeler,
            color: m.role == null ? null : theme.colorScheme.primary,
          ),
          title: Text(
            role == null ? m.name : '${m.name} · $role',
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            detail,
            style: TextStyle(color: detailColor, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
