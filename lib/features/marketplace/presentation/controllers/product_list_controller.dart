import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

/// Current search query typed in the marketplace search bar.
final marketplaceSearchQueryProvider =
    NotifierProvider<MarketplaceSearchNotifier, String>(
  MarketplaceSearchNotifier.new,
);

class MarketplaceSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

/// Derived provider: products filtered by category AND search query.
final filteredProductsProvider =
    Provider.family<List<Product>, ProductCategory>((ref, cat) {
  final all = ref.watch(productListProvider).value ?? [];
  final query =
      ref.watch(marketplaceSearchQueryProvider).trim().toLowerCase();

  final byCat = cat == ProductCategory.all
      ? all
      : all.where((p) => p.category == cat).toList();

  if (query.isEmpty) return byCat;
  return byCat.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.brand.toLowerCase().contains(query) ||
        p.variant.toLowerCase().contains(query) ||
        p.shopName.toLowerCase().contains(query);
  }).toList();
});

/// Subscribable products, also filtered by the active search query.
final subscribableProductsProvider = Provider<List<Product>>((ref) {
  final all = ref.watch(productListProvider).value ?? [];
  final query =
      ref.watch(marketplaceSearchQueryProvider).trim().toLowerCase();
  final subs = all.where((p) => p.subscribable);
  if (query.isEmpty) return subs.toList();
  return subs.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.brand.toLowerCase().contains(query) ||
        p.variant.toLowerCase().contains(query) ||
        p.shopName.toLowerCase().contains(query);
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() =>
      ref.read(productRepositoryProvider).fetchProducts();
}
