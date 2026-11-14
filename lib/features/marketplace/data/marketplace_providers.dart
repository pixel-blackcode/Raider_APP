import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/marketplace.dart';
import 'marketplace_repository.dart';

class ListingFilterController extends Notifier<ListingFilter> {
  @override
  ListingFilter build() => const ListingFilter();

  void set(ListingFilter filter) => state = filter;
}

final listingFilterProvider =
    NotifierProvider<ListingFilterController, ListingFilter>(
      ListingFilterController.new,
    );

final listingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  if (repo == null || me == null) return const [];
  return repo.search(ref.watch(listingFilterProvider), me: me);
});

final listingProvider = FutureProvider.autoDispose.family<Listing?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  if (repo == null) return null;
  return repo.listing(id);
});
