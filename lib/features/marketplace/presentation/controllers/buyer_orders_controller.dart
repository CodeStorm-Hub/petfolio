import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/marketplace_order.dart';
import '../../data/repositories/order_repository.dart';

final orderByIdProvider = FutureProvider.autoDispose
    .family<MarketplaceOrder, String>(
  (ref, orderId) => ref.read(orderRepositoryProvider).fetchOrder(orderId),
);

final buyerOrdersProvider =
    AsyncNotifierProvider<BuyerOrdersNotifier, List<MarketplaceOrder>>(
  BuyerOrdersNotifier.new,
);

class BuyerOrdersNotifier extends AsyncNotifier<List<MarketplaceOrder>> {
  @override
  Future<List<MarketplaceOrder>> build() =>
      ref.read(orderRepositoryProvider).fetchBuyerOrders();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).fetchBuyerOrders(),
    );
  }
}
