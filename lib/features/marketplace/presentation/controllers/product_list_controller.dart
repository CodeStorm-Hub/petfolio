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

final marketplaceProductsLoadingMoreProvider = Provider<bool>((ref) {
  final notifier = ref.watch(productListProvider.notifier);
  return notifier.isLoadingMore;
});

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  static const int _pageSize = 20;

  DateTime? _cursorCreatedAt;
  String?   _cursorId;
  bool      _hasMore = true;
  bool      _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<Product>> build() async {
    _cursorCreatedAt = null;
    _cursorId        = null;
    _hasMore         = true;
    _loadingMore     = false;

    final products = await ref
        .read(productRepositoryProvider)
        .fetchProducts(pageSize: _pageSize);
    if (products.length < _pageSize) _hasMore = false;
    _updateCursor(products);
    return products;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;

    _loadingMore = true;
    try {
      final more = await ref.read(productRepositoryProvider).fetchProducts(
        afterCreatedAt: _cursorCreatedAt,
        afterId: _cursorId,
        pageSize: _pageSize,
      );
      if (more.length < _pageSize) _hasMore = false;
      if (more.isNotEmpty) {
        _updateCursor(more);
        final existingIds = current.map((p) => p.id).toSet();
        final fresh = more.where((p) => !existingIds.contains(p.id)).toList();
        if (fresh.isNotEmpty) state = AsyncData([...current, ...fresh]);
      }
    } finally {
      _loadingMore = false;
    }
  }

  void _updateCursor(List<Product> page) {
    final last = page.lastOrNull;
    if (last == null) return;
    _cursorCreatedAt = last.createdAt;
    _cursorId        = last.id;
  }
}
