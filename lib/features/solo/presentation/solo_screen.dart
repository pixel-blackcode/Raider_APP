import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../../convoy/data/location_service.dart';
import '../data/solo_repository.dart';
import '../domain/solo.dart';
import 'solo_labels.dart';

/// Mode solo : partir seul suivi par 1 ou 2 proches, ou gérer le trajet en cours.
class SoloScreen extends ConsumerWidget {
  const SoloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(soloLocationSharingProvider);
    final trips = ref.watch(soloTripsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.soloTitle),
        actions: [
          IconButton(
            key: const Key('solo-contacts'),
            tooltip: l10n.soloContactsTitle,
            onPressed: () => context.push(AppRoutes.soloContacts),
            icon: const Icon(Icons.people_alt_outlined),
          ),
        ],
      ),
      body: AsyncValueView(
        value: trips,
        onRetry: () => ref.refreshSolo(),
        data: (list) {
          SoloTrip? mine;
          for (final t in list) {
            if (t.mine && t.active) mine = t;
          }
          final watched = [
            for (final t in list)
              if (!t.mine) t,
          ];
          return RefreshIndicator(
            onRefresh: () async => ref.refreshSolo(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                if (mine != null)
                  _ActiveTrip(trip: mine)
                else
                  const _StartTripForm(),
                if (watched.isNotEmpty) ...[
                  SectionHeader(title: l10n.soloWatching),
                  for (final t in watched) SoloWatchedTile(trip: t),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Trajet suivi (accueil et écran Mode solo).
class SoloWatchedTile extends StatelessWidget {
  const SoloWatchedTile({super.key, required this.trip});

  final SoloTrip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RiderColors>()!;
    final now = DateTime.now().toUtc();
    final late = trip.isLate(now);
    final color = late
        ? colors.sos
        : trip.status == SoloTripStatus.arrived
        ? colors.success
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        key: Key('solo-watched-${trip.id}'),
        leading: Icon(
          late
              ? Icons.warning_amber_rounded
              : trip.status == SoloTripStatus.arrived
              ? Icons.check_circle
              : Icons.two_wheeler,
          color: color,
        ),
        title: Text(l10n.soloTravelerTitle(trip.displayName)),
        subtitle: Text(soloStatusText(l10n, trip, now)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.soloWatch(trip.id)),
      ),
    );
  }
}

class _StartTripForm extends ConsumerStatefulWidget {
  const _StartTripForm();

  @override
  ConsumerState<_StartTripForm> createState() => _StartTripFormState();
}

class _StartTripFormState extends ConsumerState<_StartTripForm> {
  final _destination = TextEditingController();
  final _watchers = <String>{};
  var _minutes = 30;
  var _share = false;
  var _busy = false;

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (!_watchers.remove(id)) {
        if (_watchers.length >= 2) {
          showSnack(context, l10n.soloMaxWatchers);
        } else {
          _watchers.add(id);
        }
      }
    });
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    if (_watchers.isEmpty) {
      showSnack(context, l10n.soloPickWatcher);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_share) {
        final access = await ref
            .read(locationServiceProvider)
            .ensurePermission();
        if (access != LocationAccess.granted && mounted) {
          showSnack(context, l10n.soloLocationDenied);
        }
      }
      await ref
          .read(soloRepositoryProvider)!
          .startTrip(
            watcherIds: _watchers.toList(),
            minutes: _minutes,
            shareLocation: _share,
            destination: _destination.text.trim().isEmpty
                ? null
                : _destination.text.trim(),
          );
      ref.refreshSolo();
      if (mounted) showSnack(context, l10n.soloStarted);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final contacts = ref.watch(soloContactsProvider);
    final choosable = [
      for (final c in contacts.value ?? const <SoloContact>[])
        if (c.canWatchMe) c,
    ];
    final arrival = DateTime.now().add(Duration(minutes: _minutes));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.shield_moon_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.soloIntro,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader(title: l10n.soloWhoWatches),
        if (contacts.isLoading && !contacts.hasValue)
          const Center(child: CircularProgressIndicator())
        else if (choosable.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.soloNoContacts),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.tonalIcon(
                    key: const Key('solo-add-contact'),
                    onPressed: () => context.push(AppRoutes.soloContacts),
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.soloAddContact),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in choosable)
                FilterChip(
                  key: Key('solo-watcher-${c.userId}'),
                  label: Text(c.displayName),
                  selected: _watchers.contains(c.userId),
                  onSelected: (_) => _toggle(c.userId),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('solo-destination'),
          controller: _destination,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.soloDestination),
        ),
        Text(l10n.soloArrivalIn, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final m in soloDurations)
              ChoiceChip(
                key: Key('solo-minutes-$m'),
                label: Text(soloDuration(m)),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.soloExpectedAt(soloTime(arrival)),
          style: theme.textTheme.bodyMedium,
        ),
        SwitchListTile(
          key: const Key('solo-share'),
          contentPadding: EdgeInsets.zero,
          value: _share,
          onChanged: (v) => setState(() => _share = v),
          title: Text(l10n.soloShareLocation),
          subtitle: Text(l10n.soloShareLocationHelp),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('solo-start'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
          onPressed: _busy || choosable.isEmpty ? null : _start,
          icon: const Icon(Icons.two_wheeler),
          label: Text(l10n.soloStart),
        ),
      ],
    );
  }
}

class _ActiveTrip extends ConsumerStatefulWidget {
  const _ActiveTrip({required this.trip});

  final SoloTrip trip;

  @override
  ConsumerState<_ActiveTrip> createState() => _ActiveTripState();
}

class _ActiveTripState extends ConsumerState<_ActiveTrip> {
  var _busy = false;

  Future<void> _run(
    Future<void> Function(SoloRepository repo) action,
    String done,
  ) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(soloRepositoryProvider)!);
      ref.refreshSolo();
      if (mounted) showSnack(context, done);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPosition() async {
    final l10n = AppLocalizations.of(context);
    final location = ref.read(locationServiceProvider);
    if (await location.ensurePermission() != LocationAccess.granted) {
      if (mounted) showSnack(context, l10n.soloLocationDenied);
      return;
    }
    final fix = await location.current();
    if (fix == null) {
      if (mounted) showSnack(context, l10n.soloNoFix);
      return;
    }
    await _run(
      (repo) =>
          repo.sendPosition(widget.trip.id, fix.lat, fix.lng, fix.accuracyM),
      l10n.soloPositionSent,
    );
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.soloCancelTitle),
        content: Text(l10n.soloCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('solo-cancel-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.soloCancel),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await _run((repo) => repo.cancel(widget.trip.id), l10n.soloCancelled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final t = widget.trip;
    final late = t.isLate(DateTime.now().toUtc());
    final names = t.watchers.map((w) => w.displayName).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: late ? colors.sos : AppColors.marine,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.destination == null
                      ? l10n.soloActiveTitle
                      : l10n.soloActiveTo(t.destination!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.soloExpectedAt(soloTime(t.expectedAt)),
                  key: const Key('solo-expected'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.soloWatchedBy(names),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (late) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.soloLateMine,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('solo-arrived'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 60),
            backgroundColor: colors.success,
            foregroundColor: Colors.white,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: _busy
              ? null
              : () => _run((repo) => repo.arrive(t.id), l10n.soloArrivedDone),
          icon: const Icon(Icons.home_outlined),
          label: Text(l10n.soloArrived),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('solo-ok'),
          onPressed: _busy
              ? null
              : () => _run(
                  (repo) => repo.imOk(t.id, extraMinutes: 15),
                  l10n.soloOkDone,
                ),
          icon: const Icon(Icons.thumb_up_alt_outlined),
          label: Text(l10n.soloImOk),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('solo-send-position'),
          onPressed: _busy ? null : _sendPosition,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.soloSendPosition),
        ),
        SwitchListTile(
          key: const Key('solo-share-toggle'),
          contentPadding: EdgeInsets.zero,
          value: t.shareLocation,
          onChanged: _busy
              ? null
              : (v) => _run(
                  (repo) => repo.setSharing(t.id, share: v),
                  v ? l10n.soloSharingOn : l10n.soloSharingOff,
                ),
          title: Text(l10n.soloShareLocation),
          subtitle: Text(
            t.shareLocation ? l10n.soloKeepOpen : l10n.soloShareLocationHelp,
          ),
        ),
        TextButton(
          key: const Key('solo-cancel'),
          onPressed: _busy ? null : _cancel,
          child: Text(l10n.soloCancel),
        ),
      ],
    );
  }
}
