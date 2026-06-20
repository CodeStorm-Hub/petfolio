import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/marketplace_order.dart';
import '../../data/repositories/order_repository.dart';
import 'refreshable_list_notifier.dart';

final orderByIdProvider = FutureProvider.autoDispose
    .family<MarketplaceOrder, String>(
  (ref, orderId) => ref.read(orderRepositoryProvider).fetchOrder(orderId),
);

final buyerOrdersProvider =
    AsyncNotifierProvider<BuyerOrdersNotifier, List<MarketplaceOrder>>(
  BuyerOrdersNotifier.new,
);

class BuyerOrdersNotifier extends AsyncNotifier<List<MarketplaceOrder>>
    with RefreshableListNotifier<MarketplaceOrder> {
  @override
  Future<List<MarketplaceOrder>> build() => fetch();

  @override
  Future<List<MarketplaceOrder>> fetch() =>
      ref.read(orderRepositoryProvider).fetchBuyerOrders();
}
