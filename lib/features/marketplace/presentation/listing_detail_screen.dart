import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/domain/community.dart';
import '../../community/presentation/community_ui.dart';
import '../../messages/data/messaging_repository.dart';
import '../data/marketplace_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace.dart';
import 'marketplace_labels.dart';
import 'marketplace_screen.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listing = ref.watch(listingProvider(listingId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listingTitle)),
      body: AsyncValueView(
        value: listing,
        onRetry: () => ref.invalidate(listingProvider(listingId)),
        data: (l) => l == null
            ? EmptyState(
                icon: Icons.visibility_off_outlined,
                title: l10n.listingNotFoundTitle,
                message: l10n.listingNotFoundBody,
              )
            : _ListingBody(listing: l),
      ),
    );
  }
}

class _ListingBody extends ConsumerStatefulWidget {
  const _ListingBody({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_ListingBody> createState() => _ListingBodyState();
}

class _ListingBodyState extends ConsumerState<_ListingBody> {
  int _photo = 0;
  bool _busy = false;

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

  void _refresh() {
    ref
      ..invalidate(listingProvider(widget.listing.id))
      ..invalidate(listingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final media = ref.watch(mediaRepositoryProvider);
    final me = ref.watch(currentUserIdProvider);
    final l = widget.listing;
    final mine = l.sellerId == me;
    final repo = ref.read(marketplaceRepositoryProvider);
    final images = [
      for (final p in l.mediaPaths)
        media?.imageProvider(MediaBucket.listingMedia, p),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: images.isEmpty
              ? ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(l.category.icon, size: 72),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      key: const Key('listing-photos'),
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _photo = i),
                      itemBuilder: (context, i) => GestureDetector(
                        key: Key('listing-photo-$i'),
                        onTap: () => openPhotoViewer(
                          context,
                          images: images,
                          initialIndex: i,
                        ),
                        child: images[i] == null
                            ? const Icon(Icons.image_outlined)
                            : Image(
                                image: images[i]!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              '${_photo + 1} / ${images.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (l.hidden)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: colors.warning.withValues(alpha: 0.15),
                  child: Text(l10n.listingHiddenNotice),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listingPrice(l10n, l),
                      key: const Key('listing-price'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (l.status != ListingStatus.available)
                    ListingStatusPill(status: l.status),
                  if (!mine)
                    IconButton(
                      key: const Key('listing-favorite'),
                      tooltip: l10n.marketFavorites,
                      isSelected: l.isFavorite,
                      selectedIcon: Icon(
                        Icons.favorite,
                        color: theme.colorScheme.primary,
                      ),
                      icon: const Icon(Icons.favorite_border),
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await repo!.setFavorite(
                                l.id,
                                favorite: !l.isFavorite,
                              );
                              _refresh();
                            }),
                    ),
                ],
              ),
              Text(l.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  Chip(
                    avatar: Icon(l.category.icon, size: 18),
                    label: Text(l.category.label(l10n)),
                  ),
                  Chip(label: Text(l.condition.label(l10n))),
                  Chip(
                    avatar: const Icon(Icons.place_outlined, size: 18),
                    label: Text(
                      l.area == null ? l.city : '${l.area}, ${l.city}',
                    ),
                  ),
                ],
              ),
              Text(
                l10n.listingPublished(timeAgo(l10n, l.createdAt)),
                style: theme.textTheme.bodySmall,
              ),
              if (l.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l.description, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: AppSpacing.md),
              ListTile(
                key: const Key('listing-seller'),
                contentPadding: EdgeInsets.zero,
                leading: RemoteAvatar(
                  label: l.sellerName,
                  image: media?.imageProvider(
                    MediaBucket.avatars,
                    l.sellerAvatar,
                  ),
                ),
                title: Text(
                  l.sellerName.isEmpty ? l10n.profileHidden : l.sellerName,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(l10n.listingSeller),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.rider(l.sellerId)),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!mine) ...[
                SizedBox(
                  height: AppSpacing.convoyTouchTarget,
                  child: FilledButton.icon(
                    key: const Key('listing-contact'),
                    onPressed: _busy || l.status == ListingStatus.sold
                        ? null
                        : () => _run(() async {
                            final id = await ref
                                .read(messagingRepositoryProvider)!
                                .openDirect(l.sellerId);
                            if (context.mounted) {
                              await context.push(
                                AppRoutes.chat(
                                  id,
                                  text: l10n.listingContactDraft(l.title),
                                ),
                              );
                            }
                          }),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.listingContact),
                  ),
                ),
                TextButton.icon(
                  key: const Key('listing-report'),
                  onPressed: () => showReportDialog(
                    context,
                    ref,
                    ReportTarget.listing,
                    l.id,
                  ),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n.reportAction),
                ),
                Text(l10n.marketSafety, style: theme.textTheme.bodySmall),
              ] else ...[
                Text(
                  l10n.listingStatusTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<ListingStatus>(
                  key: const Key('listing-status'),
                  segments: [
                    for (final s in ListingStatus.values)
                      ButtonSegment(value: s, label: Text(s.label(l10n))),
                  ],
                  selected: {l.status},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => _run(() async {
                          await repo!.setStatus(l.id, s.first);
                          _refresh();
                        }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('listing-edit'),
                        onPressed: () =>
                            context.push(AppRoutes.editListing(l.id)),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.actionEdit),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('listing-delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: _busy
                            ? null
                            : () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: l10n.listingDeleteTitle,
                                  message: l10n.listingDeleteBody,
                                  confirmLabel: l10n.actionDelete,
                                );
                                if (!ok) return;
                                await _run(() async {
                                  final paths = await repo!.delete(l.id);
                                  try {
                                    await ref
                                        .read(mediaRepositoryProvider)
                                        ?.remove(
                                          MediaBucket.listingMedia,
                                          paths,
                                        );
                                  } catch (_) {}
                                  ref.invalidate(listingsProvider);
                                  if (context.mounted) {
                                    showSnack(context, l10n.listingDeleted);
                                    context.pop();
                                  }
                                });
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.actionDelete),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
