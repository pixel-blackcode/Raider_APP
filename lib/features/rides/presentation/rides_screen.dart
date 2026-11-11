import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/rides_providers.dart';
import '../domain/ride.dart';
import '../domain/ride_time.dart';
import 'widgets/ride_card.dart';
import 'widgets/ride_labels.dart';

class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(ridesRepositoryProvider) == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ridesTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const BackendStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            EmptyState(
              icon: Icons.route,
              title: l10n.ridesEmptyTitle,
              message: l10n.ridesOfflineBody,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.ridesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.ridesTabUpcoming),
              Tab(text: l10n.ridesTabMine),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('rides-create'),
          onPressed: () => context.push(AppRoutes.newRide()),
          icon: const Icon(Icons.add_road),
          label: Text(l10n.rideCreate),
        ),
        body: const TabBarView(children: [_UpcomingTab(), _MyRidesTab()]),
      ),
    );
  }
}

class _UpcomingTab extends ConsumerStatefulWidget {
  const _UpcomingTab();

  @override
  ConsumerState<_UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends ConsumerState<_UpcomingTab> {
  late final _controller = TextEditingController(
    text: ref.read(rideSearchProvider).query,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(rideSearchProvider.notifier).setQuery(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final search = ref.watch(rideSearchProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            key: const Key('rides-search'),
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.ridesSearchHint,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              for (final difficulty in RideDifficulty.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    key: Key('rides-filter-${difficulty.dbValue}'),
                    label: Text(difficulty.label(l10n)),
                    selected: search.difficulty == difficulty,
                    onSelected: (selected) => ref
                        .read(rideSearchProvider.notifier)
                        .setDifficulty(selected ? difficulty : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refreshRides(),
            child: AsyncValueView(
              value: ref.watch(discoverRidesProvider),
              onRetry: () => ref.invalidate(discoverRidesProvider),
              data: (rides) => rides.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          icon: Icons.route,
                          title: l10n.ridesUpcomingEmptyTitle,
                          message: l10n.ridesUpcomingEmptyBody,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        96,
                      ),
                      itemCount: rides.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => RideCard(
                        ride: rides[index],
                        onTap: () =>
                            context.push(AppRoutes.ride(rides[index].id)),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyRidesTab extends ConsumerWidget {
  const _MyRidesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invitations = ref.watch(myRideInvitationsProvider).value ?? const [];

    return RefreshIndicator(
      onRefresh: () async => ref.refreshRides(),
      child: AsyncValueView(
        value: ref.watch(myRidesProvider),
        onRetry: () => ref.invalidate(myRidesProvider),
        data: (rides) {
          final drafts = [
            for (final r in rides)
              if (r.ride.status == RideStatus.draft) r,
          ];
          final upcoming = [
            for (final r in rides)
              if (r.ride.status != RideStatus.draft &&
                  !r.ride.status.isTerminal)
                r,
          ];
          final past = [
            for (final r in rides.reversed)
              if (r.ride.status.isTerminal) r,
          ];

          Widget card(MyRide item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RideCard(
              ride: item.ride,
              badge: item.status == ParticipantStatus.pending
                  ? l10n.rideRequestPendingShort
                  : null,
              onTap: () => context.push(AppRoutes.ride(item.ride.id)),
            ),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              96,
            ),
            children: [
              for (final invitation in invitations)
                _RideInvitationCard(invitation: invitation),
              if (rides.isEmpty && invitations.isEmpty)
                EmptyState(
                  icon: Icons.two_wheeler,
                  title: l10n.ridesMineEmptyTitle,
                  message: l10n.ridesMineEmptyBody,
                ),
              if (upcoming.isNotEmpty) ...[
                SectionHeader(title: l10n.ridesSectionUpcoming),
                ...upcoming.map(card),
              ],
              if (drafts.isNotEmpty) ...[
                SectionHeader(title: l10n.ridesSectionDrafts),
                ...drafts.map(card),
              ],
              if (past.isNotEmpty) ...[
                SectionHeader(title: l10n.ridesSectionPast),
                ...past.map(card),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RideInvitationCard extends ConsumerWidget {
  const _RideInvitationCard({required this.invitation});

  final RideInvitation invitation;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(ridesRepositoryProvider)!
          .respondToInvitation(invitation.id, accept: accept);
      ref.refreshRides(invitation.rideId);
    } catch (error) {
      if (context.mounted) {
        messenger
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
    final when = invitation.startsAt == null
        ? ''
        : '${RideTime.formatShortDate(invitation.startsAt!, invitation.timezone)} · '
              '${RideTime.formatTime(invitation.startsAt!, invitation.timezone)}';
    return Card(
      key: Key('ride-invitation-${invitation.id}'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rideInvitationTitle(invitation.rideTitle),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (when.isNotEmpty) Text(when),
            if (invitation.inviterName != null)
              Text(l10n.clubInvitationFrom(invitation.inviterName!)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _respond(context, ref, accept: false),
                  child: Text(l10n.actionDecline),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: Key('ride-invitation-accept-${invitation.id}'),
                  onPressed: () => _respond(context, ref, accept: true),
                  child: Text(l10n.actionAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
