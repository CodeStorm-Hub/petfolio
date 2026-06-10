import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>(
  (_) => ProductRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class ProductRepository {
  const ProductRepository(this._client);

  final SupabaseClient _client;

  static const int _defaultPageSize = 20;

  /// Fetch active products with keyset (cursor) pagination.
  ///
  /// Pass [afterCreatedAt] + [afterId] from the last item of the previous page
  /// to get the next page. Omit both for the initial load.
  Future<List<Product>> fetchProducts({
    DateTime? afterCreatedAt,
    String? afterId,
    int pageSize = _defaultPageSize,
  }) async {
    var filterQuery = _client
        .from('products')
        .select('*, shops!inner(shop_name)')
        .eq('active', true)
        .gt('stock_quantity', 0);

    if (afterCreatedAt != null && afterId != null) {
      final ts = afterCreatedAt.toUtc().toIso8601String();
      filterQuery = filterQuery
          .or('created_at.lt.$ts,and(created_at.eq.$ts,id.lt.$afterId)');
    }

    final rows = await filterQuery
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(pageSize);

    return (rows as List)
        .map((r) => Product.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetch active products for one shop — used by storefront screen.
  Future<List<Product>> fetchProductsByShop(String shopId) async {
    final rows = await _client
        .from('products')
        .select('*, shops!inner(shop_name)')
        .eq('shop_id', shopId)
        .eq('active', true)
        .gt('stock_quantity', 0)
        .order('created_at');

    return (rows as List)
        .map((r) => Product.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
