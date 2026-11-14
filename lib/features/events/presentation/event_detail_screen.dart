import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../clubs/presentation/widgets/verified_badge.dart';
import '../../community/presentation/community_ui.dart';
import '../data/events_repository.dart';
import '../domain/moto_event.dart';
import 'events_ui.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _busy = false;

  EventsRepository get _repo => ref.read(eventsRepositoryProvider)!;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.refreshEvents(widget.eventId);
      if (mounted && done != null) showSnack(context, done);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeCover(MotoEvent e) async {
    final image = await ref.read(photoPickerProvider).pick(maxDimension: 1600);
    if (image == null) return;
    await _run(() async {
      final media = ref.read(mediaRepositoryProvider)!;
      final path = await media.upload(
        MediaBucket.eventMedia,
        folder: e.id,
        baseName: 'cover',
        image: image,
      );
      final old = await _repo.setCover(e.id, path);
      if (old != null && old != path) {
        await media.remove(MediaBucket.eventMedia, [old]);
      }
    });
  }

  Future<void> _invite(MotoEvent e) async {
    final l10n = AppLocalizations.of(context);
    final query = await showTextPrompt(
      context,
      title: l10n.eventInviteCoOrganizer,
      label: l10n.eventInviteSearch,
      confirmLabel: l10n.actionSearch,
      maxLength: 80,
    );
    if (query == null || query.trim().length < 2 || !mounted) return;
    try {
      final found = await ref
          .read(clubsRepositoryProvider)!
          .discoverClubs(query: query);
      final taken = {e.clubId, for (final o in e.coOrganizers) o.clubId};
      final candidates = [
        for (final c in found)
          if (c.isVerified && !taken.contains(c.id)) c,
      ];
      if (!mounted) return;
      if (candidates.isEmpty) {
        showSnack(context, l10n.eventInviteNoVerified);
        return;
      }
      final clubId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(l10n.eventInviteCoOrganizer),
          children: [
            for (final c in candidates)
              SimpleDialogOption(
                key: Key('event-invite-${c.id}'),
                onPressed: () => Navigator.pop(context, c.id),
                child: Text('${c.name} · ${c.city}'),
              ),
          ],
        ),
      );
      if (clubId == null) return;
      await _run(
        () => _repo.inviteCoOrganizer(e.id, clubId),
        done: l10n.eventInviteSent,
      );
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = ref.watch(eventDetailProvider(widget.eventId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventTitle),
        actions: [
          if (value.value?.canManage == true && !value.value!.isCancelled)
            PopupMenuButton<String>(
              key: const Key('event-menu'),
              onSelected: (v) async {
                final e = value.value!;
                switch (v) {
                  case 'edit':
                    await context.push(AppRoutes.editEvent(e.id));
                  case 'cover':
                    await _changeCover(e);
                  case 'invite':
                    await _invite(e);
                  case 'cancel':
                    final ok = await showConfirmDialog(
                      context,
                      title: l10n.eventCancelTitle,
                      message: l10n.eventCancelBody,
                      confirmLabel: l10n.eventCancel,
                    );
                    if (ok) await _run(() => _repo.cancel(e.id));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                PopupMenuItem(value: 'cover', child: Text(l10n.eventCover)),
                PopupMenuItem(
                  key: const Key('event-menu-invite'),
                  value: 'invite',
                  child: Text(l10n.eventInviteCoOrganizer),
                ),
                PopupMenuItem(
                  key: const Key('event-menu-cancel'),
                  value: 'cancel',
                  child: Text(l10n.eventCancel),
                ),
              ],
            ),
        ],
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.refreshEvents(widget.eventId),
        data: (e) {
          if (e == null) {
            return EmptyState(
              icon: Icons.event_busy,
              title: l10n.eventNotFound,
              message: '',
            );
          }
          final cover = ref
              .watch(mediaRepositoryProvider)
              ?.imageProvider(MediaBucket.eventMedia, e.coverPath);
          final accepted = [
            for (final o in e.coOrganizers)
              if (o.status == 'accepted') o,
          ];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (cover != null) ...[
                GestureDetector(
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
              if (e.isCancelled)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      l10n.eventCancelled,
                      key: const Key('event-cancelled'),
                    ),
                  ),
                ),
              Text(e.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(formatEventDate(context, e.startsAt)),
                subtitle: e.endsAt == null
                    ? null
                    : Text(
                        l10n.eventUntil(formatEventDate(context, e.endsAt!)),
                      ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(e.placeName),
                subtitle: Text(e.city),
              ),
              ListTile(
                key: const Key('event-organizer'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_outlined),
                title: Row(
                  children: [
                    Flexible(child: Text(e.clubName)),
                    const SizedBox(width: AppSpacing.xs),
                    const VerifiedBadge(compact: true),
                  ],
                ),
                subtitle: Text(l10n.eventOrganizer),
                onTap: () => context.push(AppRoutes.club(e.clubId)),
              ),
              for (final o in accepted)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(o.name),
                  subtitle: Text(l10n.eventCoOrganizer),
                  onTap: () => context.push(AppRoutes.club(o.clubId)),
                ),
              if (e.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(e.description),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l10n.eventGoingCount(e.attendeeCount)),
              const SizedBox(height: AppSpacing.sm),
              if (!e.isCancelled)
                SizedBox(
                  height: AppSpacing.convoyTouchTarget,
                  child: e.iAmGoing
                      ? OutlinedButton.icon(
                          key: const Key('event-not-going'),
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => _repo.setGoing(e.id, going: false),
                                ),
                          icon: const Icon(Icons.check),
                          label: Text(l10n.eventIAmGoing),
                        )
                      : FilledButton.icon(
                          key: const Key('event-going'),
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => _repo.setGoing(e.id, going: true),
                                ),
                          icon: const Icon(Icons.celebration_outlined),
                          label: Text(l10n.eventGoing),
                        ),
                ),
              if (e.canManage &&
                  e.coOrganizers.any((o) => o.status != 'accepted')) ...[
                SectionHeader(title: l10n.eventInvitations),
                for (final o in e.coOrganizers)
                  if (o.status != 'accepted')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(o.name),
                      subtitle: Text(
                        o.status == 'pending'
                            ? l10n.eventInvitationPending
                            : l10n.eventInvitationDeclined,
                      ),
                      trailing: IconButton(
                        tooltip: l10n.actionDelete,
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _repo.removeCoOrganizer(e.id, o.clubId),
                              ),
                        icon: const Icon(Icons.close),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}
