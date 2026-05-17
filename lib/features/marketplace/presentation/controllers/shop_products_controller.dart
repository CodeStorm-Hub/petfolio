import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

/// Public-facing products for a vendor storefront, keyed by shopId.
final shopProductsProvider = AsyncNotifierProvider.family<
    ShopProductsNotifier, List<Product>, String>(ShopProductsNotifier.new);

class ShopProductsNotifier extends AsyncNotifier<List<Product>> {
  ShopProductsNotifier(this.shopId);

  final String shopId;

  @override
  Future<List<Product>> build() =>
      ref.read(productRepositoryProvider).fetchProductsByShop(shopId);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).fetchProductsByShop(shopId),
    );
  }
}
