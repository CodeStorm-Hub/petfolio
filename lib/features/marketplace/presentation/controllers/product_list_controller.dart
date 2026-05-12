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

/// Derived provider: products filtered by category (client-side).
final filteredProductsProvider =
    Provider.family<List<Product>, ProductCategory>((ref, cat) {
  final all = ref.watch(productListProvider).valueOrNull ?? [];
  if (cat == ProductCategory.all) return all;
  return all.where((p) => p.category == cat).toList();
});

/// Subscribable products only.
final subscribableProductsProvider = Provider<List<Product>>((ref) {
  final all = ref.watch(productListProvider).valueOrNull ?? [];
  return all.where((p) => p.subscribable).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() =>
      ref.read(productRepositoryProvider).fetchProducts();
}
