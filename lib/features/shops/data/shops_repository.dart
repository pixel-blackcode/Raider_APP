import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/shop.dart';

abstract interface class ShopsRepository {
  Future<List<Shop>> search({String query = ''});

  Future<Shop?> shop(String id);

  Future<Shop?> shopOf(String ownerId);

  /// Crée ou modifie la boutique de l'utilisateur (motard vérifié).
  Future<String> saveMine(ShopDraft draft);

  /// Enregistre (ou retire) le logo ; retourne l'ancien chemin.
  Future<String?> setMyLogo(String? path);

  Future<void> deleteMine();
}

class SupabaseShopsRepository implements ShopsRepository {
  SupabaseShopsRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<List<Shop>> _list(Map<String, dynamic> params) async {
    final data = await _client.rpc<Object?>('list_shops', params: params);
    return [
      for (final r in (data as List?) ?? const [])
        Shop.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<Shop>> search({String query = ''}) => _guard(
    () => _list({'p_query': query.trim().isEmpty ? null : query.trim()}),
  );

  @override
  Future<Shop?> shop(String id) => _guard(() async {
    final rows = await _list({'p_shop_id': id});
    return rows.isEmpty ? null : rows.first;
  });

  @override
  Future<Shop?> shopOf(String ownerId) => _guard(() async {
    final rows = await _list({'p_owner_id': ownerId});
    return rows.isEmpty ? null : rows.first;
  });

  @override
  Future<String> saveMine(ShopDraft d) => _guard(
    () => _client.rpc<String>(
      'save_my_shop',
      params: {
        'p_name': d.name.trim(),
        'p_city': d.city.trim(),
        'p_description': d.description.trim(),
        'p_area': (d.area ?? '').trim().isEmpty ? null : d.area!.trim(),
        'p_phone': (d.phone ?? '').trim().isEmpty ? null : d.phone!.trim(),
      },
    ),
  );

  @override
  Future<String?> setMyLogo(String? path) => _guard(
    () => _client.rpc<String?>('set_my_shop_logo', params: {'p_path': path}),
  );

  @override
  Future<void> deleteMine() =>
      _guard(() => _client.rpc<void>('delete_my_shop'));
}

final shopsRepositoryProvider = Provider<ShopsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseShopsRepository(client);
});

final shopSearchProvider = FutureProvider.autoDispose
    .family<List<Shop>, String>((ref, query) async {
      final repo = ref.watch(shopsRepositoryProvider);
      if (repo == null) return const [];
      return repo.search(query: query);
    });

final shopDetailProvider = FutureProvider.autoDispose.family<Shop?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(shopsRepositoryProvider);
  if (repo == null) return null;
  return repo.shop(id);
});

/// Boutique d'un motard (null s'il n'en a pas ou si elle n'est pas visible).
final shopOfProvider = FutureProvider.autoDispose.family<Shop?, String>((
  ref,
  ownerId,
) async {
  final repo = ref.watch(shopsRepositoryProvider);
  if (repo == null) return null;
  return repo.shopOf(ownerId);
});

final myShopProvider = FutureProvider.autoDispose<Shop?>((ref) async {
  final me = ref.watch(currentUserIdProvider);
  final repo = ref.watch(shopsRepositoryProvider);
  if (me == null || repo == null) return null;
  return repo.shopOf(me);
});

extension RefreshShops on WidgetRef {
  void refreshShops() {
    invalidate(shopSearchProvider);
    invalidate(shopDetailProvider);
    invalidate(shopOfProvider);
    invalidate(myShopProvider);
  }
}
