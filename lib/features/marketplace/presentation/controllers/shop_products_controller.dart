import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'refreshable_list_notifier.dart';

/// Public-facing products for a vendor storefront, keyed by shopId.
final shopProductsProvider = AsyncNotifierProvider.family<
    ShopProductsNotifier, List<Product>, String>(ShopProductsNotifier.new);

class ShopProductsNotifier extends AsyncNotifier<List<Product>>
    with RefreshableListNotifier<Product> {
  ShopProductsNotifier(this.shopId);

  final String shopId;

  @override
  Future<List<Product>> build() => fetch();

  @override
  Future<List<Product>> fetch() =>
      ref.read(productRepositoryProvider).fetchProductsByShop(shopId);
}
