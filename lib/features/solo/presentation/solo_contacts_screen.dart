import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/data/community_repository.dart';
import '../../community/domain/community.dart';
import '../../community/presentation/community_ui.dart';
import '../data/solo_repository.dart';
import '../domain/solo.dart';

/// Mes proches (qui suivent mes trajets) et les motards dont je suis le proche.
class SoloContactsScreen extends ConsumerStatefulWidget {
  const SoloContactsScreen({super.key});

  @override
  ConsumerState<SoloContactsScreen> createState() => _SoloContactsScreenState();
}

class _SoloContactsScreenState extends ConsumerState<SoloContactsScreen> {
  final _query = TextEditingController();
  List<RiderHit> _hits = const [];
  Timer? _debounce;
  var _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final hits = await ref
            .read(communityRepositoryProvider)
            ?.searchRiders(value.replaceFirst('@', ''));
        if (mounted) setState(() => _hits = hits ?? const []);
      } catch (_) {}
    });
  }

  Future<void> _run(
    Future<void> Function(SoloRepository repo) action, [
    String? done,
  ]) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(soloRepositoryProvider)!);
      ref.refreshSolo();
      if (mounted && done != null) showSnack(context, done);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request(RiderHit hit) async {
    final l10n = AppLocalizations.of(context);
    await _run(
      (repo) => repo.requestContact(hit.id),
      l10n.soloContactRequested(hit.displayName),
    );
    if (mounted) {
      setState(() {
        _hits = const [];
        _query.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contacts = ref.watch(soloContactsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.soloContactsTitle)),
      body: AsyncValueView(
        value: contacts,
        onRetry: () => ref.invalidate(soloContactsProvider),
        data: (list) {
          final mine = [
            for (final c in list)
              if (!c.incoming) c,
          ];
          final theirs = [
            for (final c in list)
              if (c.incoming) c,
          ];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(l10n.soloContactsIntro),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('solo-contact-search'),
                controller: _query,
                decoration: InputDecoration(
                  labelText: l10n.soloContactSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onQuery,
              ),
              for (final hit in _hits)
                ListTile(
                  key: Key('solo-hit-${hit.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(hit.displayName),
                  subtitle: Text('@${hit.username}'),
                  trailing: const Icon(Icons.person_add_alt),
                  onTap: _busy ? null : () => _request(hit),
                ),
              SectionHeader(title: l10n.soloMyContacts),
              if (mine.isEmpty) Text(l10n.soloMyContactsEmpty),
              for (final c in mine)
                _ContactTile(
                  contact: c,
                  subtitle: c.accepted
                      ? l10n.soloContactAccepted
                      : l10n.soloContactPending,
                  busy: _busy,
                  onRemove: () => _run((repo) => repo.removeContact(c.id)),
                ),
              if (theirs.isNotEmpty) ...[
                SectionHeader(title: l10n.soloIWatch),
                for (final c in theirs)
                  c.accepted
                      ? _ContactTile(
                          contact: c,
                          subtitle: l10n.soloIWatchAccepted,
                          busy: _busy,
                          onRemove: () =>
                              _run((repo) => repo.removeContact(c.id)),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.soloContactAsk(c.displayName)),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    FilledButton(
                                      key: Key('solo-accept-${c.id}'),
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                              (repo) => repo.respondContact(
                                                c.id,
                                                accept: true,
                                              ),
                                            ),
                                      child: Text(l10n.actionAccept),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    OutlinedButton(
                                      key: Key('solo-decline-${c.id}'),
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                              (repo) => repo.respondContact(
                                                c.id,
                                                accept: false,
                                              ),
                                            ),
                                      child: Text(l10n.actionDecline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.subtitle,
    required this.busy,
    required this.onRemove,
  });

  final SoloContact contact;
  final String subtitle;
  final bool busy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: Key('solo-contact-${contact.id}'),
        leading: CircleAvatar(
          child: Text(
            contact.displayName.isEmpty
                ? '?'
                : contact.displayName[0].toUpperCase(),
          ),
        ),
        title: Text(contact.displayName),
        subtitle: Text(subtitle),
        trailing: IconButton(
          key: Key('solo-remove-${contact.id}'),
          tooltip: l10n.soloRemoveContact,
          onPressed: busy ? null : onRemove,
          icon: const Icon(Icons.person_remove_outlined),
        ),
      ),
    );
  }
}
