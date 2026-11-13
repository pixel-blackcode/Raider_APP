import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';

/// Nouvelle conversation privée (par pseudonyme) ou de groupe.
class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  bool _group = false;
  final _username = TextEditingController();
  final _title = TextEditingController();
  final _members = <Profile>[];
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<Profile?> _find() async {
    final l10n = AppLocalizations.of(context);
    final name = _username.text.trim().replaceFirst('@', '');
    if (name.isEmpty) return null;
    final found = await ref
        .read(profileRepositoryProvider)!
        .findByUsername(name);
    if (found == null && mounted) showSnack(context, l10n.newConvUserNotFound);
    return found;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDirect() => _run(() async {
    final p = await _find();
    if (p == null) return;
    final id = await ref.read(messagingRepositoryProvider)!.openDirect(p.id);
    ref.invalidate(inboxProvider);
    if (mounted) context.pushReplacement(AppRoutes.chat(id));
  });

  Future<void> _addMember() => _run(() async {
    final p = await _find();
    if (p == null || _members.any((m) => m.id == p.id)) return;
    setState(() {
      _members.add(p);
      _username.clear();
    });
  });

  Future<void> _createGroup() => _run(() async {
    if (_title.text.trim().isEmpty || _members.isEmpty) {
      throw const AppException('invalid_input');
    }
    final id = await ref.read(messagingRepositoryProvider)!.createGroup(
      _title.text.trim(),
      [for (final m in _members) m.id],
    );
    ref.invalidate(inboxProvider);
    if (mounted) context.pushReplacement(AppRoutes.chat(id));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesNew)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.person_outline),
                label: Text(l10n.newConvDirect),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.groups_outlined),
                label: Text(
                  l10n.newConvGroup,
                  key: const Key('new-conv-group-tab'),
                ),
              ),
            ],
            selected: {_group},
            onSelectionChanged: (s) => setState(() => _group = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_group) ...[
            TextField(
              key: const Key('new-group-title'),
              controller: _title,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.newConvGroupTitle),
            ),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final m in _members)
                  InputChip(
                    label: Text(m.displayName),
                    onDeleted: () => setState(() => _members.remove(m)),
                  ),
              ],
            ),
          ],
          TextField(
            key: const Key('new-conv-username'),
            controller: _username,
            decoration: InputDecoration(
              labelText: l10n.newConvUsername,
              prefixText: '@',
            ),
            onSubmitted: (_) => _group ? _addMember() : _openDirect(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_group) ...[
            OutlinedButton.icon(
              key: const Key('new-group-add'),
              onPressed: _busy ? null : _addMember,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.newConvAddMember),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const Key('new-group-create'),
              onPressed: _busy ? null : _createGroup,
              child: Text(l10n.newConvCreateGroup),
            ),
          ] else
            FilledButton(
              key: const Key('new-conv-open'),
              onPressed: _busy ? null : _openDirect,
              child: Text(l10n.newConvOpen),
            ),
        ],
      ),
    );
  }
}
