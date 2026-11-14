import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/marketplace.dart';

abstract interface class MarketplaceRepository {
  Future<List<Listing>> search(ListingFilter filter, {required String me});

  Future<Listing?> listing(String id);

  /// Création idempotente (même `clientRef` : pas de doublon).
  Future<String> create(
    ListingDraft draft, {
    required String clientRef,
    List<String> mediaPaths = const [],
  });

  /// Retourne les chemins des photos retirées (à effacer).
  Future<List<String>> update(
    String id,
    ListingDraft draft, {
    List<String> mediaPaths = const [],
  });

  Future<void> setStatus(String id, ListingStatus status);

  /// Retourne les chemins des photos à effacer.
  Future<List<String>> delete(String id);

  Future<void> setFavorite(String id, {required bool favorite});
}

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  SupabaseMarketplaceRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  List<Listing> _rows(Object? data) => [
    for (final r in (data as List?) ?? const [])
      Listing.fromJson(r as Map<String, dynamic>),
  ];

  Map<String, dynamic> _draft(ListingDraft d) => {
    'p_category': d.category.name,
    'p_title': d.title,
    'p_condition': d.condition.dbValue,
    'p_city': d.city,
    'p_description': d.description,
    'p_price': d.price,
    'p_currency': d.currency.code,
    'p_area': d.area,
  };

  List<String> _paths(Object? data) => [
    for (final p in (data as List?) ?? const []) p as String,
  ];

  @override
  Future<List<Listing>> search(ListingFilter f, {required String me}) =>
      _guard(() async {
        final data = await _client.rpc<Object?>(
          'search_listings',
          params: {
            'p_query': f.query.trim().isEmpty ? null : f.query.trim(),
            'p_category': f.category?.name,
            'p_city': f.city.trim().isEmpty ? null : f.city.trim(),
            'p_max_price': f.maxPrice,
            'p_currency': f.currency?.code,
            'p_include_sold': f.scope == ListingScope.mine,
            'p_favorites_only': f.scope == ListingScope.favorites,
            'p_seller_id': f.scope == ListingScope.mine ? me : null,
            'p_limit': 50,
          },
        );
        return _rows(data);
      });

  @override
  Future<Listing?> listing(String id) => _guard(() async {
    final rows = _rows(
      await _client.rpc<Object?>(
        'search_listings',
        params: {'p_listing_id': id, 'p_limit': 1},
      ),
    );
    return rows.isEmpty ? null : rows.first;
  });

  @override
  Future<String> create(
    ListingDraft draft, {
    required String clientRef,
    List<String> mediaPaths = const [],
  }) => _guard(
    () => _client.rpc<String>(
      'create_listing',
      params: {
        'p_client_ref': clientRef,
        ..._draft(draft),
        'p_media_paths': mediaPaths,
      },
    ),
  );

  @override
  Future<List<String>> update(
    String id,
    ListingDraft draft, {
    List<String> mediaPaths = const [],
  }) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'update_listing',
      params: {
        'p_listing_id': id,
        ..._draft(draft),
        'p_media_paths': mediaPaths,
      },
    );
    return _paths(data);
  });

  @override
  Future<void> setStatus(String id, ListingStatus status) => _guard(
    () => _client.rpc<void>(
      'set_listing_status',
      params: {'p_listing_id': id, 'p_status': status.name},
    ),
  );

  @override
  Future<List<String>> delete(String id) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'delete_listing',
      params: {'p_listing_id': id},
    );
    return _paths(data);
  });

  @override
  Future<void> setFavorite(String id, {required bool favorite}) => _guard(
    () => _client.rpc<void>(
      'set_listing_favorite',
      params: {'p_listing_id': id, 'p_favorite': favorite},
    ),
  );
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseMarketplaceRepository(client);
});
