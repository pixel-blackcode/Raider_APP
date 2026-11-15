import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../clubs/presentation/widgets/verified_badge.dart';
import '../data/shops_repository.dart';
import '../domain/shop.dart';

/// Boutiques des motards vérifiés, avec recherche tolérante.
class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shops = ref.watch(shopSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shopsTitle),
        actions: [
          TextButton.icon(
            key: const Key('shops-mine'),
            onPressed: () => context.push(AppRoutes.myShop),
            icon: const Icon(Icons.store_mall_directory_outlined),
            label: Text(l10n.shopMine),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              key: const Key('shops-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.shopsSearch,
              ),
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: shops,
              onRetry: () => ref.refreshShops(),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: l10n.shopsEmptyTitle,
                      message: l10n.shopsEmptyBody,
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      children: [for (final s in items) ShopTile(shop: s)],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopTile extends ConsumerWidget {
  const ShopTile({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final media = ref.watch(mediaRepositoryProvider);
    return Card(
      key: Key('shop-${shop.id}'),
      child: ListTile(
        onTap: () => context.push(AppRoutes.shop(shop.id)),
        leading: RemoteAvatar(
          label: shop.name,
          image: media?.imageProvider(MediaBucket.shopMedia, shop.logoPath),
        ),
        title: Row(
          children: [
            Flexible(child: Text(shop.name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppSpacing.xs),
            const VerifiedBadge(compact: true),
          ],
        ),
        subtitle: Text(
          [
            [shop.city, if (shop.area != null) shop.area!].join(' · '),
            l10n.shopListingCount(shop.listingCount),
          ].join('\n'),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
