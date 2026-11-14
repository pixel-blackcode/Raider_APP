import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/marketplace_providers.dart';
import '../domain/marketplace.dart';
import 'marketplace_labels.dart';

/// Marketplace : annonces entre motards, sans paiement dans l'application.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(listingFilterProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _update(ListingFilter f) =>
      ref.read(listingFilterProvider.notifier).set(f);

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    final f = ref.read(listingFilterProvider);
    final city = TextEditingController(text: f.city);
    final price = TextEditingController(
      text: f.maxPrice == null ? '' : f.maxPrice!.toStringAsFixed(0),
    );
    var currency = f.currency;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.marketFilters,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                key: const Key('market-filter-city'),
                controller: city,
                decoration: InputDecoration(labelText: l10n.listingCity),
              ),
              TextField(
                key: const Key('market-filter-price'),
                controller: price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.marketMaxPrice),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<Currency?>(
                segments: [
                  ButtonSegment(
                    value: null,
                    label: Text(l10n.marketAnyCurrency),
                  ),
                  const ButtonSegment(value: Currency.usd, label: Text('USD')),
                  const ButtonSegment(value: Currency.cdf, label: Text('CDF')),
                ],
                selected: {currency},
                onSelectionChanged: (s) => setSheet(() => currency = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('market-filter-apply'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.marketApplyFilters),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok ?? false) {
      _update(
        f.copyWith(
          city: city.text.trim(),
          maxPrice: () =>
              double.tryParse(price.text.trim().replaceAll(',', '.')),
          currency: () => currency,
        ),
      );
    }
    city.dispose();
    price.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final filter = ref.watch(listingFilterProvider);
    final listings = ref.watch(listingsProvider);
    final hasExtraFilters =
        filter.city.isNotEmpty ||
        filter.maxPrice != null ||
        filter.currency != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.marketplaceTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('market-sell'),
        heroTag: null,
        onPressed: () => context.push(AppRoutes.newListing),
        icon: const Icon(Icons.sell_outlined),
        label: Text(l10n.marketSell),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('market-search'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.marketSearchHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 400),
                        () => _update(filter.copyWith(query: v)),
                      );
                    },
                    onSubmitted: (v) => _update(filter.copyWith(query: v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  key: const Key('market-filters'),
                  tooltip: l10n.marketFilters,
                  isSelected: hasExtraFilters,
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              children: [
                for (final scope in ListingScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      key: Key('market-scope-${scope.name}'),
                      label: Text(switch (scope) {
                        ListingScope.all => l10n.marketAll,
                        ListingScope.mine => l10n.marketMine,
                        ListingScope.favorites => l10n.marketFavorites,
                      }),
                      selected: filter.scope == scope,
                      onSelected: (_) => _update(filter.copyWith(scope: scope)),
                    ),
                  ),
                const VerticalDivider(),
                for (final c in ListingCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      key: Key('market-cat-${c.name}'),
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label(l10n)),
                      selected: filter.category == c,
                      onSelected: (on) => _update(
                        filter.copyWith(category: () => on ? c : null),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.marketSafety,
              key: const Key('market-safety'),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: listings,
              onRetry: () => ref.invalidate(listingsProvider),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: l10n.marketplaceEmptyTitle,
                      message: l10n.marketplaceEmptyBody,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        96,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 0.66,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          _ListingTile(listing: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingTile extends ConsumerWidget {
  const _ListingTile({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = ref.watch(mediaRepositoryProvider);
    final l = listing;
    final cover = l.mediaPaths.isEmpty
        ? null
        : media?.imageProvider(MediaBucket.listingMedia, l.mediaPaths.first);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        l.category.icon,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Card(
      key: Key('listing-${l.id}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(AppRoutes.listing(l.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // L'image prend la place restante : pas de débordement, même
            // avec une grande taille de texte.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover == null)
                    placeholder
                  else
                    Image(
                      image: cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
                  if (l.status != ListingStatus.available)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _StatusPill(status: l.status),
                    ),
                  if (l.isFavorite)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listingPrice(l10n, l),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l.city,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RiderColors>()!;
    final bg = status == ListingStatus.sold ? colors.sos : colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label(AppLocalizations.of(context)),
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Pastille de statut réutilisée sur la fiche.
class ListingStatusPill extends StatelessWidget {
  const ListingStatusPill({super.key, required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) => _StatusPill(status: status);
}
