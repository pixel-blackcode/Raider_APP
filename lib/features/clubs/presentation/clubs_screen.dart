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
import '../../../l10n/generated/app_localizations.dart';
import '../data/clubs_providers.dart';
import '../domain/club.dart';
import 'widgets/club_card.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(clubsRepositoryProvider) != null;

    if (!available) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clubsTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const BackendStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            EmptyState(
              icon: Icons.groups,
              title: l10n.clubsEmptyTitle,
              message: l10n.clubsOfflineBody,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.clubsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.clubsTabMine),
              Tab(text: l10n.clubsTabDiscover),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('clubs-create'),
          onPressed: () => context.push(AppRoutes.newClub),
          icon: const Icon(Icons.add),
          label: Text(l10n.clubCreate),
        ),
        body: const TabBarView(children: [_MyClubsTab(), _DiscoverTab()]),
      ),
    );
  }
}

class _MyClubsTab extends ConsumerWidget {
  const _MyClubsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invitations = ref.watch(myClubInvitationsProvider).value ?? const [];

    return RefreshIndicator(
      onRefresh: () async => ref.refreshClubs(),
      child: AsyncValueView(
        value: ref.watch(myClubsProvider),
        onRetry: ref.refreshClubs,
        data: (memberships) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            96,
          ),
          children: [
            for (final invitation in invitations)
              _InvitationCard(invitation: invitation),
            if (memberships.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: EmptyState(
                  icon: Icons.groups,
                  title: l10n.clubsMineEmptyTitle,
                  message: l10n.clubsMineEmptyBody,
                ),
              ),
            for (final membership in memberships)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ClubCard(
                  club: membership.club,
                  role: membership.role,
                  onTap: () => context.push(AppRoutes.club(membership.club.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({required this.invitation});

  final ClubInvitation invitation;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    try {
      await ref
          .read(clubsRepositoryProvider)!
          .respondToInvitation(invitation.id, accept: accept);
      ref.refreshClubs(invitation.clubId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
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
    return Card(
      key: Key('invitation-${invitation.id}'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clubInvitationTitle(invitation.clubName),
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
                  key: Key('invitation-accept-${invitation.id}'),
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

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  late final _controller = TextEditingController(
    text: ref.read(clubSearchQueryProvider),
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
      () => ref.read(clubSearchQueryProvider.notifier).set(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            key: const Key('clubs-search'),
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.clubsSearchHint,
            ),
          ),
        ),
        Expanded(
          child: AsyncValueView(
            value: ref.watch(discoverClubsProvider),
            onRetry: () => ref.invalidate(discoverClubsProvider),
            data: (clubs) => clubs.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: l10n.clubsDiscoverEmptyTitle,
                    message: l10n.clubsDiscoverEmptyBody,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: clubs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => ClubCard(
                      club: clubs[index],
                      onTap: () =>
                          context.push(AppRoutes.club(clubs[index].id)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
