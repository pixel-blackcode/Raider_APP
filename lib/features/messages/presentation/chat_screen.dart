import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/domain/community.dart';
import '../../community/presentation/community_ui.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/messaging.dart';

/// Une conversation. Un message n'est affiché « envoyé » qu'après réponse
/// du serveur ; un échec reste visible avec « Réessayer ».
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.initialText});

  final String conversationId;

  /// Brouillon proposé (ex. « À propos de votre annonce… »), jamais envoyé
  /// sans action du motard.
  final String? initialText;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final _text = TextEditingController(text: widget.initialText);
  int _seen = -1;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref
          .read(messagingRepositoryProvider)
          ?.markRead(widget.conversationId);
      ref.invalidate(inboxProvider);
    } catch (_) {}
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    _text.clear();
    await ref
        .read(chatOutboxProvider.notifier)
        .send(widget.conversationId, body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    ConversationSummary? summary;
    for (final c
        in ref.watch(inboxProvider).value ?? const <ConversationSummary>[]) {
      if (c.id == widget.conversationId) summary = c;
    }
    final server =
        ref.watch(conversationMessagesProvider(widget.conversationId)).value ??
        const <ChatMessage>[];
    final outbox = ref
        .watch(chatOutboxProvider)
        .values
        .where((m) => m.conversationId == widget.conversationId)
        .toList();
    final serverRefs = {for (final m in server) m.clientRef};

    // Messages du serveur + envois en cours / échoués + envoyés pas encore
    // reçus par le flux temps réel.
    final items = <_Item>[
      for (final m in server) _Item.server(m),
      for (final o in outbox)
        if (!serverRefs.contains(o.clientRef))
          o.state == OutgoingState.sent && o.message != null
              ? _Item.server(o.message!)
              : _Item.outgoing(o),
    ]..sort((a, b) => a.at.compareTo(b.at));

    if (server.length != _seen) {
      _seen = server.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    }

    final kind = summary?.kind;
    final showNames = kind != ConversationKind.direct;
    final blocked = summary?.blocked ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (summary?.title.isNotEmpty ?? false)
              ? summary!.title
              : l10n.chatTitle,
        ),
        actions: [
          if (summary != null)
            PopupMenuButton<String>(
              key: const Key('chat-menu'),
              onSelected: (a) async {
                switch (a) {
                  case 'profile':
                    await context.push(AppRoutes.rider(summary!.otherUserId!));
                  case 'ride':
                    await context.push(AppRoutes.ride(summary!.rideId!));
                  case 'leave':
                    final ok = await showConfirmDialog(
                      context,
                      title: l10n.chatLeaveTitle,
                      message: l10n.chatLeaveBody,
                      confirmLabel: l10n.chatLeave,
                    );
                    if (!ok || me == null) return;
                    try {
                      await ref
                          .read(messagingRepositoryProvider)!
                          .removeMember(widget.conversationId, me);
                      ref.invalidate(inboxProvider);
                      if (context.mounted) context.pop();
                    } catch (error) {
                      if (context.mounted) {
                        showSnack(context, describeError(context, error));
                      }
                    }
                }
              },
              itemBuilder: (_) => [
                if (summary!.kind == ConversationKind.direct &&
                    summary.otherUserId != null)
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(l10n.chatSeeProfile),
                  ),
                if (summary.kind == ConversationKind.ride)
                  PopupMenuItem(value: 'ride', child: Text(l10n.chatSeeRide)),
                if (summary.kind == ConversationKind.group)
                  PopupMenuItem(
                    key: const Key('chat-leave'),
                    value: 'leave',
                    child: Text(l10n.chatLeave),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(l10n.chatNoMessages))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[items.length - 1 - i];
                      return _Bubble(
                        item: item,
                        mine: item.isOutgoing || item.message?.senderId == me,
                        showName: showNames,
                      );
                    },
                  ),
          ),
          if (blocked)
            Container(
              key: const Key('chat-blocked'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.chatBlockedNotice, textAlign: TextAlign.center),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chat-field'),
                        controller: _text,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.chatHint,
                          counterText: '',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('chat-send'),
                      tooltip: l10n.chatSend,
                      iconSize: 26,
                      constraints: const BoxConstraints(
                        minWidth: 52,
                        minHeight: 52,
                      ),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Item {
  _Item.server(ChatMessage this.message) : outgoing = null;
  _Item.outgoing(OutgoingMessage this.outgoing) : message = null;

  final ChatMessage? message;
  final OutgoingMessage? outgoing;

  bool get isOutgoing => outgoing != null;
  DateTime get at => message?.createdAt ?? outgoing!.createdAt;
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.item,
    required this.mine,
    required this.showName,
  });

  final _Item item;
  final bool mine;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final m = item.message;
    final o = item.outgoing;
    final failed = o?.state == OutgoingState.failed;
    final bg = failed
        ? colors.sos.withValues(alpha: 0.12)
        : mine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = failed
        ? theme.colorScheme.onSurface
        : mine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    String text;
    FontStyle? style;
    if (m != null && m.deleted) {
      text = l10n.chatDeleted;
      style = FontStyle.italic;
    } else if (m != null && m.hidden) {
      text = l10n.chatHiddenNotice;
      style = FontStyle.italic;
    } else {
      text = m?.body ?? o!.body;
    }

    String time(DateTime t) {
      final l = t.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:'
          '${l.minute.toString().padLeft(2, '0')}';
    }

    Future<void> longPress() async {
      if (m == null || m.deleted) return;
      if (mine) {
        final ok = await showConfirmDialog(
          context,
          title: l10n.chatDeleteTitle,
          message: l10n.chatDeleteBody,
          confirmLabel: l10n.actionDelete,
        );
        if (!ok) return;
        try {
          await ref.read(messagingRepositoryProvider)!.deleteMessage(m.id);
        } catch (error) {
          if (context.mounted) {
            showSnack(context, describeError(context, error));
          }
        }
      } else {
        await showReportDialog(context, ref, ReportTarget.message, m.id);
      }
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: Key(m != null ? 'msg-${m.id}' : 'msg-out-${o!.clientRef}'),
        onLongPress: longPress,
        onTap: failed
            ? () => ref.read(chatOutboxProvider.notifier).retry(o!.clientRef)
            : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: failed ? Border.all(color: colors.sos, width: 1.5) : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showName && !mine && m?.senderName != null)
                Text(
                  m!.senderName!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fg,
                  fontStyle: style,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (o != null && o.state == OutgoingState.sending) ...[
                    Icon(Icons.schedule, size: 14, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      l10n.chatSending,
                      key: Key('msg-sending-${o.clientRef}'),
                      style: TextStyle(fontSize: 12, color: fg),
                    ),
                  ] else if (failed) ...[
                    Icon(Icons.error_outline, size: 14, color: colors.sos),
                    const SizedBox(width: 4),
                    Text(
                      l10n.chatFailed,
                      key: Key('msg-failed-${o!.clientRef}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.sos,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else
                    Text(
                      time(item.at),
                      style: TextStyle(
                        fontSize: 12,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
