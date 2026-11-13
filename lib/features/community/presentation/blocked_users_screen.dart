import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import 'community_ui.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blocked = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsersTitle)),
      body: AsyncValueView(
        value: blocked,
        onRetry: () => ref.invalidate(blockedUsersProvider),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.block,
                title: l10n.blockedUsersEmptyTitle,
                message: l10n.blockedUsersEmptyBody,
              )
            : ListView(
                children: [
                  for (final b in list)
                    ListTile(
                      key: Key('blocked-${b.userId}'),
                      leading: const Icon(Icons.block),
                      title: Text(b.displayName),
                      subtitle: Text('@${b.username}'),
                      trailing: OutlinedButton(
                        key: Key('unblock-${b.userId}'),
                        onPressed: () async {
                          try {
                            await ref
                                .read(communityRepositoryProvider)!
                                .unblock(b.userId);
                            refreshCommunity(ref);
                          } catch (error) {
                            if (context.mounted) {
                              showSnack(context, describeError(context, error));
                            }
                          }
                        },
                        child: Text(l10n.unblockAction),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
