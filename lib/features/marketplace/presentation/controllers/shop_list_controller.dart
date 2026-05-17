import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';

final shopListProvider =
    AsyncNotifierProvider<ShopListNotifier, List<Shop>>(ShopListNotifier.new);

final shopByIdProvider = FutureProvider.family<Shop, String>((ref, shopId) {
  return ref.read(shopRepositoryProvider).fetchShopById(shopId);
});

class ShopListNotifier extends AsyncNotifier<List<Shop>> {
  @override
  Future<List<Shop>> build() =>
      ref.read(shopRepositoryProvider).fetchAllActiveShops();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(shopRepositoryProvider).fetchAllActiveShops(),
    );
  }
}
