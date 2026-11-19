import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../clubs/data/verification_admin_repository.dart';
import '../../clubs/presentation/widgets/verified_badge.dart';
import '../../community/presentation/community_ui.dart';
import '../../marketplace/data/marketplace_repository.dart';
import '../../marketplace/domain/marketplace.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../messages/data/messaging_repository.dart';
import '../../sos/data/emergency.dart';
import '../data/shops_repository.dart';

/// Annonces disponibles d'un vendeur (vitrine de sa boutique).
final sellerListingsProvider = FutureProvider.autoDispose
    .family<List<Listing>, String>((ref, sellerId) async {
      final repo = ref.watch(marketplaceRepositoryProvider);
      final me = ref.watch(currentUserIdProvider);
      if (repo == null || me == null) return const [];
      return repo.search(ListingFilter(sellerId: sellerId), me: me);
    });

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final media = ref.watch(mediaRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: AsyncValueView(
        value: ref.watch(shopDetailProvider(shopId)),
        onRetry: () => ref.refreshShops(),
        data: (shop) {
          if (shop == null) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              title: l10n.shopNotFound,
              message: '',
            );
          }
          final listings =
              ref.watch(sellerListingsProvider(shop.ownerId)).value ??
              const <Listing>[];
          final mine = shop.ownerId == me;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        RemoteAvatar(
                          label: shop.name,
                          radius: 36,
                          image: media?.imageProvider(
                            MediaBucket.shopMedia,
                            shop.logoPath,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      shop.name,
                                      key: const Key('shop-name'),
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const VerifiedBadge(compact: true),
                                ],
                              ),
                              Text(
                                [
                                  shop.city,
                                  if (shop.area != null) shop.area!,
                                ].join(' · '),
                              ),
                              InkWell(
                                onTap: () =>
                                    context.push(AppRoutes.rider(shop.ownerId)),
                                child: Text(
                                  l10n.shopOwner(shop.ownerName),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (ref.watch(amIPlatformAdminProvider).value ?? false) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _SuspendButton(
                        shopId: shop.id,
                        suspended: shop.suspended,
                      ),
                    ],
                    if (!shop.active) ...[
                      const SizedBox(height: AppSpacing.sm),
                      InfoCard(
                        icon: Icons.visibility_off_outlined,
                        message: shop.suspended
                            ? l10n.shopSuspendedNotice
                            : l10n.shopInactive,
                      ),
                    ],
                    if (shop.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(shop.description),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (mine)
                      OutlinedButton.icon(
                        key: const Key('shop-edit'),
                        onPressed: () => context.push(AppRoutes.myShop),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.shopEdit),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (shop.phone != null)
                            FilledButton.icon(
                              key: const Key('shop-whatsapp'),
                              onPressed: () => ref
                                  .read(externalActionsProvider)
                                  .openWhatsApp(shop.phone!),
                              icon: const Icon(Icons.chat_outlined),
                              label: Text(l10n.shopWhatsApp),
                            ),
                          OutlinedButton.icon(
                            key: const Key('shop-message'),
                            onPressed: () async {
                              try {
                                final id = await ref
                                    .read(messagingRepositoryProvider)!
                                    .openDirect(shop.ownerId);
                                if (context.mounted) {
                                  await context.push(AppRoutes.chat(id));
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  showSnack(
                                    context,
                                    describeError(context, error),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(l10n.shopMessage),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.shopListingCount(listings.length),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(l10n.marketSafety, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, i) =>
                      ListingTile(listing: listings[i]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          );
        },
      ),
    );
  }
}

/// Outil de l'équipe : suspendre (avec raison) ou rétablir une boutique.
class _SuspendButton extends ConsumerWidget {
  const _SuspendButton({required this.shopId, required this.suspended});

  final String shopId;
  final bool suspended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      key: const Key('shop-suspend'),
      style: OutlinedButton.styleFrom(
        foregroundColor: suspended
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
      ),
      onPressed: () async {
        String? note;
        if (!suspended) {
          note = await showTextPrompt(
            context,
            title: l10n.shopSuspend,
            label: l10n.shopSuspendReason,
            confirmLabel: l10n.shopSuspend,
            maxLength: 1000,
          );
          if (note == null) return;
        }
        try {
          await ref
              .read(shopsRepositoryProvider)!
              .setSuspended(
                shopId,
                suspended: !suspended,
                note: (note ?? '').isEmpty ? null : note,
              );
          ref.refreshShops();
          if (context.mounted) {
            showSnack(
              context,
              suspended ? l10n.shopRestored : l10n.shopSuspendedDone,
            );
          }
        } catch (error) {
          if (context.mounted) {
            showSnack(context, describeError(context, error));
          }
        }
      },
      icon: Icon(suspended ? Icons.play_circle_outline : Icons.block),
      label: Text(suspended ? l10n.shopRestore : l10n.shopSuspend),
    );
  }
}
