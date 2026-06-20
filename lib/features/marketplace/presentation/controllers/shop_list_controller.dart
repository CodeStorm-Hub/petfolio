import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';
import 'refreshable_list_notifier.dart';

final shopListProvider =
    AsyncNotifierProvider<ShopListNotifier, List<Shop>>(ShopListNotifier.new);

final shopByIdProvider = FutureProvider.family<Shop, String>((ref, shopId) {
  return ref.read(shopRepositoryProvider).fetchShopById(shopId);
});

class ShopListNotifier extends AsyncNotifier<List<Shop>>
    with RefreshableListNotifier<Shop> {
  @override
  Future<List<Shop>> build() => fetch();

  @override
  Future<List<Shop>> fetch() =>
      ref.read(shopRepositoryProvider).fetchAllActiveShops();
}
