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

  /// Fetch active products across all shops with cursor-style pagination.
  ///
  /// [page] is zero-based; [pageSize] defaults to 20.
  /// Callers can pass page=0 for the initial load and increment for
  /// infinite-scroll / load-more without re-fetching previous pages.
  Future<List<Product>> fetchProducts({
    int page = 0,
    int pageSize = 20,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final rows = await _client
        .from('products')
        .select('*, shops!inner(shop_name)')
        .eq('active', true)
        .order('created_at')
        .range(start, end);

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
        .order('created_at');

    return (rows as List)
        .map((r) => Product.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
