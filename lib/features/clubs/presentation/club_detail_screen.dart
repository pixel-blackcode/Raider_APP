import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../rides/data/rides_providers.dart';
import '../../rides/presentation/widgets/ride_card.dart';
import '../data/clubs_providers.dart';
import '../data/clubs_repository.dart';
import '../domain/club.dart';
import '../domain/club_permissions.dart';
import 'widgets/club_card.dart';
import 'widgets/club_labels.dart';
import 'widgets/verified_badge.dart';

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(clubDetailProvider(clubId));
    final value = detail.value;
    final permissions = ClubPermissions(value?.myRole);

    return Scaffold(
      appBar: AppBar(
        title: Text(value?.club.name ?? l10n.clubsTitle),
        actions: [
          if (value != null && permissions.canEditDetails)
            IconButton(
              key: const Key('club-edit'),
              tooltip: l10n.clubEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editClub(clubId)),
            ),
          if (value != null && permissions.canDeleteClub)
            PopupMenuButton<String>(
              onSelected: (_) => _confirmDelete(context, ref, value.club),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'delete', child: Text(l10n.clubDelete)),
              ],
            ),
        ],
      ),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(clubDetailProvider(clubId)),
        data: (detail) => detail == null
            ? EmptyState(
                icon: Icons.search_off,
                title: l10n.errorClubNotFound,
                message: l10n.clubNotFoundBody,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.refreshClubs(clubId),
                child: _ClubDetailBody(detail: detail),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Club club,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clubDelete,
      message: l10n.clubDeleteConfirm(club.name),
      confirmLabel: l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runClubAction(
      context,
      ref,
      (repo) => repo.deleteClub(club.id),
    );
    if (ok && context.mounted) {
      ref.refreshClubs();
      context.go(AppRoutes.clubs);
    }
  }
}

/// Exécute une action sur les clubs, affiche l'erreur éventuelle et
/// rafraîchit les vues. Retourne `true` si l'action a réussi.
Future<bool> runClubAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(ClubsRepository repository) action, {
  String? clubId,
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(clubsRepositoryProvider);
  try {
    if (repository == null) {
      throw const AppException(AppException.backendUnavailable);
    }
    await action(repository);
    ref.refreshClubs(clubId);
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

class _ClubDetailBody extends ConsumerWidget {
  const _ClubDetailBody({required this.detail});

  final ClubDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final club = detail.club;
    final permissions = ClubPermissions(detail.myRole);

    final cover = ref
        .watch(mediaRepositoryProvider)
        ?.imageProvider(MediaBucket.clubMedia, club.coverPath);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (cover != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image(
                key: const Key('club-cover'),
                image: cover,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            ClubAvatar(club: club, radius: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    key: const Key('club-detail-name'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (club.isVerified) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const VerifiedBadge(key: Key('club-verified-badge')),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${club.city} · ${l10n.clubMemberCount(club.memberCount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Chip(
              avatar: Icon(
                club.isPrivate ? Icons.lock_outline : Icons.public,
                size: 18,
              ),
              label: Text(club.visibility.label(l10n)),
            ),
            Chip(label: Text(club.joinPolicy.label(l10n))),
            if (detail.myRole != null)
              Chip(
                key: const Key('club-my-role'),
                avatar: const Icon(Icons.badge_outlined, size: 18),
                label: Text(detail.myRole!.label(l10n)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MembershipActions(detail: detail),
        if (club.description.isNotEmpty) ...[
          SectionHeader(title: l10n.clubFieldDescription),
          Text(club.description),
        ],
        if (club.rules.isNotEmpty) ...[
          SectionHeader(title: l10n.clubFieldRules),
          Text(club.rules),
        ],
        _ClubRidesSection(detail: detail),
        if (permissions.canReviewRequests) _AdminSection(detail: detail),
        SectionHeader(title: l10n.clubMembersTitle),
        if (detail.members.isEmpty)
          InfoCard(
            icon: Icons.lock_outline,
            message: club.isPrivate
                ? l10n.clubMembersPrivate
                : l10n.clubMembersEmpty,
          )
        else
          for (final member in detail.members)
            _MemberTile(club: club, member: member, permissions: permissions),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MembershipActions extends ConsumerWidget {
  const _MembershipActions({required this.detail});

  final ClubDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final club = detail.club;
    final permissions = ClubPermissions(detail.myRole);

    if (club.isSuspended) {
      return InfoCard(icon: Icons.block, message: l10n.errorClubSuspended);
    }

    if (permissions.isMember) {
      if (!permissions.canLeave) return const SizedBox.shrink();
      return OutlinedButton.icon(
        key: const Key('club-leave'),
        onPressed: () async {
          final confirmed = await showConfirmDialog(
            context,
            title: l10n.clubLeave,
            message: l10n.clubLeaveConfirm(club.name),
            confirmLabel: l10n.clubLeave,
          );
          if (confirmed && context.mounted) {
            await runClubAction(
              context,
              ref,
              (repo) => repo.leaveClub(club.id),
              clubId: club.id,
            );
          }
        },
        icon: const Icon(Icons.logout),
        label: Text(l10n.clubLeave),
      );
    }

    final pending = detail.myPendingRequest;
    if (pending != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoCard(
            key: const Key('club-request-pending'),
            icon: Icons.hourglass_top,
            message: l10n.clubRequestPending,
          ),
          TextButton(
            onPressed: () => runClubAction(
              context,
              ref,
              (repo) => repo.cancelJoinRequest(pending.id),
              clubId: club.id,
            ),
            child: Text(l10n.clubRequestCancel),
          ),
        ],
      );
    }

    switch (club.joinPolicy) {
      case ClubJoinPolicy.open:
        return FilledButton.icon(
          key: const Key('club-join'),
          onPressed: () => runClubAction(
            context,
            ref,
            (repo) => repo.joinClub(club.id),
            clubId: club.id,
            successMessage: l10n.clubJoined,
          ),
          icon: const Icon(Icons.group_add),
          label: Text(l10n.clubJoin),
        );
      case ClubJoinPolicy.approval:
        return FilledButton.icon(
          key: const Key('club-request'),
          onPressed: () async {
            final message = await showTextPrompt(
              context,
              title: l10n.clubRequestJoin,
              label: l10n.clubRequestMessage,
              confirmLabel: l10n.clubRequestSend,
            );
            if (message == null || !context.mounted) return;
            await runClubAction(
              context,
              ref,
              (repo) => repo.joinClub(
                club.id,
                message: message.isEmpty ? null : message,
              ),
              clubId: club.id,
              successMessage: l10n.clubRequestSent,
            );
          },
          icon: const Icon(Icons.how_to_reg_outlined),
          label: Text(l10n.clubRequestJoin),
        );
      case ClubJoinPolicy.inviteOnly:
        return InfoCard(
          key: const Key('club-invite-only'),
          icon: Icons.mail_lock_outlined,
          message: l10n.clubInviteOnlyNotice,
        );
    }
  }
}

class _AdminSection extends ConsumerWidget {
  const _AdminSection({required this.detail});

  final ClubDetail detail;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final username = await showTextPrompt(
      context,
      title: l10n.clubInvite,
      label: l10n.fieldUsername,
      confirmLabel: l10n.clubInviteSend,
      maxLength: 30,
      prefix: '@',
    );
    if (username == null || username.isEmpty || !context.mounted) return;
    final profiles = ref.read(profileRepositoryProvider);
    try {
      final profile = await profiles?.findByUsername(username);
      if (profile == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.errorUserNotFound)));
        return;
      }
      if (!context.mounted) return;
      await runClubAction(
        context,
        ref,
        (repo) => repo.invite(detail.club.id, profile.id),
        clubId: detail.club.id,
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
    final club = detail.club;
    final permissions = ClubPermissions(detail.myRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.clubAdminTitle),
        OutlinedButton.icon(
          key: const Key('club-invite'),
          onPressed: () => _invite(context, ref),
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.clubInvite),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (detail.pendingRequests.isEmpty)
          InfoCard(icon: Icons.inbox_outlined, message: l10n.clubRequestsNone)
        else
          for (final request in detail.pendingRequests)
            Card(
              key: Key('club-request-${request.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(request.displayName),
                subtitle: Text(
                  [
                    '@${request.username}',
                    if (request.message != null) '« ${request.message} »',
                  ].join('\n'),
                ),
                isThreeLine: request.message != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.actionDecline,
                      icon: const Icon(Icons.close),
                      onPressed: () => runClubAction(
                        context,
                        ref,
                        (repo) =>
                            repo.decideJoinRequest(request.id, approve: false),
                        clubId: club.id,
                      ),
                    ),
                    IconButton(
                      key: Key('club-request-approve-${request.id}'),
                      tooltip: l10n.actionAccept,
                      icon: const Icon(Icons.check),
                      onPressed: () => runClubAction(
                        context,
                        ref,
                        (repo) =>
                            repo.decideJoinRequest(request.id, approve: true),
                        clubId: club.id,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (permissions.canRequestVerification && !club.isVerified)
          _VerificationTile(detail: detail),
      ],
    );
  }
}

class _VerificationTile extends ConsumerWidget {
  const _VerificationTile({required this.detail});

  final ClubDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final request = detail.verificationRequest;

    if (request?.status == VerificationStatus.pending) {
      return InfoCard(
        key: const Key('club-verification-pending'),
        icon: Icons.hourglass_top,
        message: l10n.clubVerificationPending,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request?.status == VerificationStatus.rejected)
          InfoCard(
            icon: Icons.info_outline,
            message: [
              l10n.clubVerificationRejected,
              if (request?.reviewNote != null) request!.reviewNote!,
            ].join('\n'),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('club-request-verification'),
          onPressed: () async {
            final message = await showTextPrompt(
              context,
              title: l10n.clubVerificationRequest,
              label: l10n.clubVerificationMessage,
              confirmLabel: l10n.clubRequestSend,
              maxLength: 1000,
            );
            if (message == null || !context.mounted) return;
            await runClubAction(
              context,
              ref,
              (repo) => repo.requestVerification(
                detail.club.id,
                message: message.isEmpty ? null : message,
              ),
              clubId: detail.club.id,
              successMessage: l10n.clubVerificationSent,
            );
          },
          icon: const Icon(Icons.verified_outlined),
          label: Text(l10n.clubVerificationRequest),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.clubVerificationHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.club,
    required this.member,
    required this.permissions,
  });

  final Club club;
  final ClubMember member;
  final ClubPermissions permissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMe = ref.watch(currentUserIdProvider) == member.userId;
    final roles = isMe
        ? const <ClubRole>[]
        : permissions.assignableRoles(member);
    final canRemove = !isMe && permissions.canRemove(member);
    final canTransfer = !isMe && permissions.role == ClubRole.owner;
    final hasActions = roles.isNotEmpty || canRemove || canTransfer;

    final hidden = member.displayName.isEmpty;
    return ListTile(
      key: Key('club-member-${member.userId}'),
      contentPadding: EdgeInsets.zero,
      leading: RemoteAvatar(
        label: member.displayName,
        image: ref
            .watch(mediaRepositoryProvider)
            ?.imageProvider(MediaBucket.avatars, member.avatarPath),
      ),
      title: Text(hidden ? l10n.profileHidden : member.displayName),
      subtitle: Text(
        hidden
            ? member.role.label(l10n)
            : '@${member.username} · ${member.role.label(l10n)}',
      ),
      trailing: !hasActions
          ? null
          : PopupMenuButton<String>(
              key: Key('club-member-menu-${member.userId}'),
              onSelected: (action) =>
                  _onAction(context, ref, action, roles: roles),
              itemBuilder: (_) => [
                for (final role in roles)
                  PopupMenuItem(
                    value: 'role:${role.dbValue}',
                    child: Text(l10n.clubSetRole(role.label(l10n))),
                  ),
                if (canTransfer)
                  PopupMenuItem(
                    value: 'transfer',
                    child: Text(l10n.clubTransferOwnership),
                  ),
                if (canRemove)
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(l10n.clubRemoveMember),
                  ),
              ],
            ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action, {
    required List<ClubRole> roles,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (action.startsWith('role:')) {
      final role = ClubRole.parse(action.substring(5));
      await runClubAction(
        context,
        ref,
        (repo) => repo.setMemberRole(club.id, member.userId, role),
        clubId: club.id,
      );
    } else if (action == 'remove') {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.clubRemoveMember,
        message: l10n.clubRemoveConfirm(member.displayName),
        confirmLabel: l10n.clubRemoveMember,
      );
      if (confirmed && context.mounted) {
        await runClubAction(
          context,
          ref,
          (repo) => repo.removeMember(club.id, member.userId),
          clubId: club.id,
        );
      }
    } else if (action == 'transfer') {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.clubTransferOwnership,
        message: l10n.clubTransferConfirm(member.displayName),
        confirmLabel: l10n.clubTransferOwnership,
      );
      if (confirmed && context.mounted) {
        await runClubAction(
          context,
          ref,
          (repo) => repo.transferOwnership(club.id, member.userId),
          clubId: club.id,
        );
      }
    }
  }
}

/// Balades à venir du club, et création réservée aux owner / admin.
class _ClubRidesSection extends ConsumerWidget {
  const _ClubRidesSection({required this.detail});

  final ClubDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final permissions = ClubPermissions(detail.myRole);
    final rides =
        ref.watch(clubRidesProvider(detail.club.id)).value ?? const [];
    if (rides.isEmpty && !permissions.canEditDetails) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.clubRidesTitle),
        if (rides.isEmpty)
          InfoCard(icon: Icons.route_outlined, message: l10n.clubRidesEmpty)
        else
          for (final ride in rides)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RideCard(
                ride: ride,
                onTap: () => context.push(AppRoutes.ride(ride.id)),
              ),
            ),
        if (permissions.canEditDetails)
          OutlinedButton.icon(
            key: const Key('club-organize-ride'),
            onPressed: () =>
                context.push(AppRoutes.newRide(clubId: detail.club.id)),
            icon: const Icon(Icons.add_road),
            label: Text(l10n.clubOrganizeRide),
          ),
      ],
    );
  }
}
