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

  /// Fetch all active products.  Throws [PostgrestException] on failure.
  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('active', true)
        .order('created_at');

    return (rows as List).map((r) => Product.fromJson(r as Map<String, dynamic>)).toList();
  }
}
