import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/vendor_product_repository.dart';
import 'my_shop_controller.dart';

final vendorProductsProvider =
    AsyncNotifierProvider<VendorProductsNotifier, List<Product>>(
  VendorProductsNotifier.new,
);

class VendorProductsNotifier extends AsyncNotifier<List<Product>> {
  VendorProductRepository get _repo =>
      ref.read(vendorProductRepositoryProvider);

  @override
  Future<List<Product>> build() async {
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return [];
    return _repo.fetchProductsByShop(shop.id);
  }

  Future<bool> createProduct({
    required String name,
    required String brand,
    required String variant,
    required String category,
    required int priceCents,
    String currency = 'usd',
    bool subscribable = false,
    String glyph = 'unknown',
    String gradientStart = '#F4B57A',
    String gradientEnd = '#C46A4F',
    List<String> imageUrls = const [],
    int inventoryCount = 0,
  }) async {
    final shop = await ref.read(myShopProvider.future);
    if (shop == null) return false;

    try {
      final product = await _repo.createProduct(
        shopId:        shop.id,
        name:          name,
        brand:         brand,
        variant:       variant,
        category:      category,
        priceCents:    priceCents,
        currency:      currency,
        subscribable:  subscribable,
        glyph:         glyph,
        gradientStart: gradientStart,
        gradientEnd:   gradientEnd,
        imageUrls:     imageUrls,
        inventoryCount: inventoryCount,
      );
      state = state.whenData((products) => [...products, product]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? brand,
    String? variant,
    String? category,
    int? priceCents,
    bool? subscribable,
    List<String>? imageUrls,
    int? inventoryCount,
    bool? active,
  }) async {
    try {
      final updated = await _repo.updateProduct(
        id:            id,
        name:          name,
        brand:         brand,
        variant:       variant,
        category:      category,
        priceCents:    priceCents,
        subscribable:  subscribable,
        imageUrls:     imageUrls,
        inventoryCount: inventoryCount,
        active:        active,
      );
      state = state.whenData(
        (products) => [for (final p in products) if (p.id == id) updated else p],
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    final prev = state;
    state = state.whenData(
      (products) => products.where((p) => p.id != id).toList(),
    );
    try {
      await _repo.deleteProduct(id);
      return true;
    } catch (_) {
      state = prev;
      return false;
    }
  }
}
