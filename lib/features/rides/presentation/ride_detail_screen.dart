import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/geo/point_picker.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../convoy/data/convoy_repository.dart';
import '../../convoy/domain/convoy.dart';
import '../../convoy/presentation/convoy_screen.dart';
import '../../messages/data/messaging_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../sos/data/emergency.dart';
import '../data/rides_providers.dart';
import '../data/rides_repository.dart';
import '../domain/ride.dart';
import '../domain/ride_state_machine.dart';
import '../domain/ride_time.dart';
import 'widgets/ride_card.dart';
import 'widgets/ride_labels.dart';

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(rideDetailProvider(rideId));
    final value = detail.value;
    final canEdit =
        value != null &&
        value.canManage &&
        RideStateMachine.isEditable(value.ride.status);
    final canDeleteDraft =
        value != null &&
        value.isOrganizer &&
        value.ride.status == RideStatus.draft;

    return Scaffold(
      appBar: AppBar(
        title: Text(value?.ride.title ?? l10n.ridesTitle),
        actions: [
          if (canEdit)
            IconButton(
              key: const Key('ride-edit'),
              tooltip: l10n.rideEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editRide(rideId)),
            ),
          if (canDeleteDraft)
            PopupMenuButton<String>(
              key: const Key('ride-menu'),
              onSelected: (_) => _deleteDraft(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.rideDeleteDraft),
                ),
              ],
            ),
        ],
      ),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(rideDetailProvider(rideId)),
        data: (detail) => detail == null
            ? EmptyState(
                icon: Icons.search_off,
                title: l10n.errorRideNotFound,
                message: l10n.rideNotFoundBody,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.refreshRides(rideId),
                child: _RideDetailBody(detail: detail),
              ),
      ),
    );
  }

  Future<void> _deleteDraft(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.rideDeleteDraft,
      message: l10n.rideDeleteDraftConfirm,
      confirmLabel: l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runRideAction(
      context,
      ref,
      (repo) => repo.deleteDraft(rideId),
    );
    if (ok && context.mounted) context.go(AppRoutes.rides);
  }
}

/// Exécute une action sur une balade, affiche l'erreur éventuelle et
/// rafraîchit les vues. Retourne `true` en cas de succès.
Future<bool> runRideAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(RidesRepository repository) action, {
  String? rideId,
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(ridesRepositoryProvider);
  try {
    if (repository == null) {
      throw const AppException(AppException.backendUnavailable);
    }
    await action(repository);
    ref.refreshRides(rideId);
    if (successMessage != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(context, error))));
    }
    return false;
  }
}

class _RideDetailBody extends ConsumerWidget {
  const _RideDetailBody({required this.detail});

  final RideDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ride = detail.ride;

    Widget infoRow(IconData icon, String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, key: key)),
        ],
      ),
    );

    final capacity = ride.maxParticipants == null
        ? l10n.rideParticipantCount(ride.participantCount)
        : l10n.rideParticipantCapacity(
            ride.participantCount,
            ride.maxParticipants!,
          );

    final cover = ref
        .watch(mediaRepositoryProvider)
        ?.imageProvider(MediaBucket.rideMedia, ride.coverPath);
    final distance = ride.distanceMeters;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (cover != null) ...[
          GestureDetector(
            key: const Key('ride-cover'),
            onTap: () => openPhotoViewer(context, images: [cover]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image(
                  image: cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          ride.title,
          key: const Key('ride-detail-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RideStatusBadge(key: const Key('ride-status'), ride: ride),
            Chip(
              avatar: Icon(ride.visibility.icon, size: 18),
              label: Text(
                ride.visibility == RideVisibility.club && ride.openToNonMembers
                    ? '${ride.visibility.label(l10n)} · ${l10n.rideOpenToAll}'
                    : ride.visibility.label(l10n),
              ),
            ),
            Chip(label: Text(ride.joinPolicy.label(l10n))),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        infoRow(
          Icons.event,
          '${RideTime.formatDate(ride.startsAt, ride.timezone)} · '
          '${RideTime.formatTime(ride.startsAt, ride.timezone)} '
          '(${timezoneLabel(l10n, ride.timezone)})',
          key: const Key('ride-detail-schedule'),
        ),
        infoRow(
          Icons.route,
          '${ride.startLabel} → ${ride.destinationLabel} · ${ride.city}',
        ),
        if (distance != null)
          infoRow(
            Icons.straighten,
            l10n.rideDistance(formatDistance(distance)),
            key: const Key('ride-detail-distance'),
          ),
        if (ride.startLat != null || ride.destinationLat != null)
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (ride.startLat != null && ride.startLng != null)
                OutlinedButton.icon(
                  key: const Key('ride-open-start-map'),
                  onPressed: () => ref
                      .read(externalActionsProvider)
                      .openMap(ride.startLat!, ride.startLng!),
                  icon: const Icon(Icons.trip_origin, size: 18),
                  label: Text(l10n.rideSeeStart),
                ),
              if (ride.destinationLat != null && ride.destinationLng != null)
                OutlinedButton.icon(
                  key: const Key('ride-open-destination-map'),
                  onPressed: () => ref
                      .read(externalActionsProvider)
                      .openMap(ride.destinationLat!, ride.destinationLng!),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(l10n.rideSeeDestination),
                ),
            ],
          ),
        if (ride.clubName != null)
          infoRow(Icons.groups_outlined, l10n.rideClubLabel(ride.clubName!)),
        infoRow(
          Icons.person_outline,
          l10n.rideOrganizerLabel(
            ride.organizerId == null
                ? l10n.rideOrganizerDeleted
                : ride.organizerName ?? l10n.profileHidden,
          ),
        ),
        infoRow(Icons.terrain, ride.difficulty.label(l10n)),
        infoRow(
          Icons.two_wheeler,
          ride.bikeTypes.map((t) => t.label(l10n)).join(', '),
        ),
        infoRow(Icons.people_outline, capacity),
        if (ride.status == RideStatus.cancelled)
          InfoCard(
            icon: Icons.cancel_outlined,
            color: theme.extension<RiderColors>()!.sos,
            title: l10n.rideStatusCancelled,
            message: ride.cancellationReason ?? l10n.rideCancelledNoReason,
          ),
        if (ride.status == RideStatus.inProgress &&
            (detail.myStatus == ParticipantStatus.confirmed ||
                detail.canManage)) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.convoyTouchTarget,
            child: FilledButton.icon(
              key: const Key('ride-open-convoy'),
              onPressed: () => context.push(AppRoutes.convoy(ride.id)),
              icon: const Icon(Icons.navigation, size: 28),
              label: Text(l10n.convoyOpen, style: theme.textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.convoyTouchTarget,
            child: FilledButton.icon(
              key: const Key('ride-open-sos'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.extension<RiderColors>()!.sos,
                foregroundColor: theme.extension<RiderColors>()!.onSos,
              ),
              onPressed: () => context.push(AppRoutes.sos(ride.id)),
              icon: const Icon(Icons.sos, size: 28),
              label: Text(l10n.sosTitle, style: theme.textTheme.titleLarge),
            ),
          ),
        ],
        if (ride.status != RideStatus.draft &&
            (detail.myStatus == ParticipantStatus.confirmed ||
                detail.canManage)) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('ride-open-chat'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              try {
                final id = await ref
                    .read(messagingRepositoryProvider)!
                    .openRide(ride.id);
                if (context.mounted) await context.push(AppRoutes.chat(id));
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(describeError(context, error))),
                    );
                }
              }
            },
            icon: const Icon(Icons.forum_outlined),
            label: Text(l10n.rideOpenChat),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _ParticipationSection(detail: detail),
        if (ride.description.isNotEmpty) ...[
          SectionHeader(title: l10n.clubFieldDescription),
          Text(ride.description),
        ],
        if (ride.itinerary.isNotEmpty) ...[
          SectionHeader(title: l10n.rideFieldItinerary),
          Text(ride.itinerary),
        ],
        if (ride.conditions.isNotEmpty) ...[
          SectionHeader(title: l10n.rideFieldConditions),
          Text(ride.conditions),
        ],
        if (detail.canManage) _ManagerSection(detail: detail),
        SectionHeader(title: l10n.rideParticipantsTitle),
        if (detail.participants.isEmpty)
          InfoCard(
            icon: Icons.lock_outline,
            message: l10n.rideParticipantsHidden,
          )
        else
          for (final participant in detail.participants)
            _ParticipantTile(detail: detail, participant: participant),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ParticipationSection extends ConsumerWidget {
  const _ParticipationSection({required this.detail});

  final RideDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ride = detail.ride;
    final status = detail.myStatus;

    if (ride.status == RideStatus.draft) {
      return InfoCard(icon: Icons.edit_note, message: l10n.rideDraftNotice);
    }
    if (detail.isOrganizer) {
      return InfoCard(
        key: const Key('ride-you-organize'),
        icon: Icons.star_outline,
        message: l10n.rideYouOrganize,
      );
    }
    if (status == ParticipantStatus.removed) {
      return InfoCard(
        key: const Key('ride-removed'),
        icon: Icons.block,
        message: l10n.rideRemovedNotice,
      );
    }
    if (ride.status.isTerminal) {
      return const SizedBox.shrink();
    }
    if (status == ParticipantStatus.confirmed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoCard(
            key: const Key('ride-you-participate'),
            icon: Icons.check_circle_outline,
            color: Theme.of(context).extension<RiderColors>()!.success,
            message: l10n.rideYouParticipate,
          ),
          TextButton.icon(
            key: const Key('ride-leave'),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: l10n.rideLeave,
                message: l10n.rideLeaveConfirm(ride.title),
                confirmLabel: l10n.rideLeave,
              );
              if (confirmed && context.mounted) {
                await runRideAction(
                  context,
                  ref,
                  (repo) => repo.leave(ride.id),
                  rideId: ride.id,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.rideLeave),
          ),
        ],
      );
    }
    if (status == ParticipantStatus.pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoCard(
            key: const Key('ride-request-pending'),
            icon: Icons.hourglass_top,
            message: l10n.rideRequestPending,
          ),
          TextButton(
            onPressed: () => runRideAction(
              context,
              ref,
              (repo) => repo.cancelRequest(ride.id),
              rideId: ride.id,
            ),
            child: Text(l10n.clubRequestCancel),
          ),
        ],
      );
    }
    if (!ride.acceptsParticipants) {
      return InfoCard(
        key: const Key('ride-joins-closed'),
        icon: Icons.lock_outline,
        message: l10n.rideJoinsClosedNotice,
      );
    }
    if (ride.isFull) {
      return InfoCard(
        key: const Key('ride-full'),
        icon: Icons.event_busy,
        message: l10n.errorRideFull,
      );
    }
    switch (ride.joinPolicy) {
      case RideJoinPolicy.open:
        return FilledButton.icon(
          key: const Key('ride-join'),
          onPressed: () => runRideAction(
            context,
            ref,
            (repo) => repo.join(ride.id),
            rideId: ride.id,
            successMessage: l10n.rideJoined,
          ),
          icon: const Icon(Icons.how_to_reg),
          label: Text(l10n.rideJoin),
        );
      case RideJoinPolicy.approval:
        return FilledButton.icon(
          key: const Key('ride-request'),
          onPressed: () async {
            final message = await showTextPrompt(
              context,
              title: l10n.rideRequestJoin,
              label: l10n.clubRequestMessage,
              confirmLabel: l10n.clubRequestSend,
            );
            if (message == null || !context.mounted) return;
            await runRideAction(
              context,
              ref,
              (repo) =>
                  repo.join(ride.id, message: message.isEmpty ? null : message),
              rideId: ride.id,
              successMessage: l10n.clubRequestSent,
            );
          },
          icon: const Icon(Icons.how_to_reg_outlined),
          label: Text(l10n.rideRequestJoin),
        );
      case RideJoinPolicy.inviteOnly:
        return InfoCard(
          key: const Key('ride-invite-only'),
          icon: Icons.mail_lock_outlined,
          message: l10n.rideInviteOnlyNotice,
        );
    }
  }
}

class _ManagerSection extends ConsumerWidget {
  const _ManagerSection({required this.detail});

  final RideDetail detail;

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    RideAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ride = detail.ride;
    String? reason;
    if (action == RideAction.cancel) {
      reason = await showTextPrompt(
        context,
        title: l10n.rideActionCancel,
        label: l10n.rideCancelReason,
        confirmLabel: l10n.rideActionCancel,
      );
      if (reason == null) return;
    } else if (action == RideAction.finish || action == RideAction.start) {
      final confirmed = await showConfirmDialog(
        context,
        title: action.label(l10n),
        message: action == RideAction.start
            ? l10n.rideStartConfirm
            : l10n.rideFinishConfirm,
        confirmLabel: action.label(l10n),
      );
      if (!confirmed) return;
    }
    if (!context.mounted) return;
    await runRideAction(
      context,
      ref,
      (repo) => repo.setStatus(
        ride.id,
        action,
        reason: reason == null || reason.isEmpty ? null : reason,
      ),
      rideId: ride.id,
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final username = await showTextPrompt(
      context,
      title: l10n.rideInvite,
      label: l10n.fieldUsername,
      confirmLabel: l10n.clubInviteSend,
      maxLength: 30,
      prefix: '@',
    );
    if (username == null || username.isEmpty || !context.mounted) return;
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          ?.findByUsername(username);
      if (profile == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.errorUserNotFound)));
        return;
      }
      if (!context.mounted) return;
      await runRideAction(
        context,
        ref,
        (repo) => repo.invite(detail.ride.id, profile.id),
        rideId: detail.ride.id,
        successMessage: l10n.clubInviteSent(profile.displayName),
      );
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
    final ride = detail.ride;
    final actions = RideStateMachine.availableActions(ride.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.rideManageTitle),
        if (actions.isEmpty)
          InfoCard(icon: Icons.flag, message: l10n.rideNoMoreActions)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in actions)
                if (action == RideAction.cancel)
                  OutlinedButton.icon(
                    key: Key('ride-action-${action.name}'),
                    onPressed: () => _apply(context, ref, action),
                    icon: Icon(action.icon),
                    label: Text(action.label(l10n)),
                  )
                else
                  FilledButton.tonalIcon(
                    key: Key('ride-action-${action.name}'),
                    onPressed: () => _apply(context, ref, action),
                    icon: Icon(action.icon),
                    label: Text(action.label(l10n)),
                  ),
            ],
          ),
        if (ride.status == RideStatus.locked ||
            (ride.status == RideStatus.inProgress && ride.joinsLocked))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.rideLockedHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!ride.status.isTerminal && ride.status != RideStatus.draft) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('ride-invite'),
            onPressed: () => _invite(context, ref),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l10n.rideInvite),
          ),
        ],
        if (detail.pendingRequests.isNotEmpty) ...[
          SectionHeader(title: l10n.rideRequestsTitle),
          for (final request in detail.pendingRequests)
            Card(
              key: Key('ride-request-${request.userId}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(
                  request.displayName.isEmpty
                      ? l10n.profileHidden
                      : request.displayName,
                ),
                subtitle: Text(
                  [
                    if (request.username.isNotEmpty) '@${request.username}',
                    if (request.message != null) '« ${request.message} »',
                  ].join('\n'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.actionDecline,
                      icon: const Icon(Icons.close),
                      onPressed: () => runRideAction(
                        context,
                        ref,
                        (repo) => repo.decideRequest(
                          ride.id,
                          request.userId,
                          approve: false,
                        ),
                        rideId: ride.id,
                      ),
                    ),
                    IconButton(
                      key: Key('ride-request-approve-${request.userId}'),
                      tooltip: l10n.actionAccept,
                      icon: const Icon(Icons.check),
                      onPressed: () => runRideAction(
                        context,
                        ref,
                        (repo) => repo.decideRequest(
                          ride.id,
                          request.userId,
                          approve: true,
                        ),
                        rideId: ride.id,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  const _ParticipantTile({required this.detail, required this.participant});

  final RideDetail detail;
  final RideParticipant participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    final isOrganizer = participant.userId == detail.ride.organizerId;
    final hidden = participant.displayName.isEmpty;
    final roles =
        ref.watch(convoyRolesProvider(detail.ride.id)).value ?? const {};
    ConvoyRole? convoyRole;
    for (final e in roles.entries) {
      if (e.value == participant.userId) convoyRole = e.key;
    }
    final canAssign = detail.canManage && !detail.ride.status.isTerminal;
    final canRemove =
        detail.canManage &&
        !isOrganizer &&
        participant.userId != me &&
        !detail.ride.status.isTerminal;

    return ListTile(
      key: Key('ride-participant-${participant.userId}'),
      contentPadding: EdgeInsets.zero,
      leading: RemoteAvatar(
        label: participant.displayName,
        image: ref
            .watch(mediaRepositoryProvider)
            ?.imageProvider(MediaBucket.avatars, participant.avatarPath),
      ),
      title: Text(hidden ? l10n.profileHidden : participant.displayName),
      subtitle: Text(
        [
          if (!hidden) '@${participant.username}',
          if (isOrganizer) l10n.rideOrganizerRole,
          if (convoyRole == ConvoyRole.leader) l10n.convoyRoleLeader,
          if (convoyRole == ConvoyRole.sweeper) l10n.convoyRoleSweeper,
        ].join(' · '),
      ),
      trailing: !canRemove && !canAssign
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canAssign)
                  PopupMenuButton<String>(
                    key: Key('ride-convoy-role-${participant.userId}'),
                    tooltip: l10n.convoyAssignRole,
                    // Bouton libellé (une icône seule passait inaperçue).
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.convoyRoleButton,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) async {
                      final repo = ref.read(convoyRepositoryProvider);
                      if (repo == null) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        if (value == 'clear') {
                          await repo.setRole(detail.ride.id, convoyRole!, null);
                        } else {
                          await repo.setRole(
                            detail.ride.id,
                            ConvoyRole.tryParse(value)!,
                            participant.userId,
                          );
                        }
                        ref.invalidate(convoyRolesProvider(detail.ride.id));
                      } catch (error) {
                        if (context.mounted) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(describeError(context, error)),
                              ),
                            );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'leader',
                        child: Text(l10n.convoyMakeLeader),
                      ),
                      PopupMenuItem(
                        value: 'sweeper',
                        child: Text(l10n.convoyMakeSweeper),
                      ),
                      if (convoyRole != null)
                        PopupMenuItem(
                          value: 'clear',
                          child: Text(l10n.convoyClearRole),
                        ),
                    ],
                  ),
                if (canRemove)
                  IconButton(
                    key: Key('ride-remove-${participant.userId}'),
                    tooltip: l10n.rideRemoveParticipant,
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: l10n.rideRemoveParticipant,
                        message: l10n.rideRemoveConfirm(
                          hidden ? l10n.profileHidden : participant.displayName,
                        ),
                        confirmLabel: l10n.rideRemoveParticipant,
                      );
                      if (confirmed && context.mounted) {
                        await runRideAction(
                          context,
                          ref,
                          (repo) => repo.removeParticipant(
                            detail.ride.id,
                            participant.userId,
                          ),
                          rideId: detail.ride.id,
                        );
                      }
                    },
                  ),
              ],
            ),
    );
  }
}
