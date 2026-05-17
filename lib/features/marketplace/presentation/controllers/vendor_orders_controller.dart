import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/marketplace_order.dart';
import '../../data/repositories/order_repository.dart';
import 'my_shop_controller.dart';

final vendorOrdersProvider =
    AsyncNotifierProvider<VendorOrdersNotifier, List<MarketplaceOrder>>(
  VendorOrdersNotifier.new,
);

class VendorOrdersNotifier extends AsyncNotifier<List<MarketplaceOrder>> {
  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  Future<List<MarketplaceOrder>> build() async {
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return [];
    return _repo.fetchVendorOrders(shop.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final shop = await ref.read(myShopProvider.future);
    if (shop == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = await AsyncValue.guard(() => _repo.fetchVendorOrders(shop.id));
  }

  Future<bool> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await _repo.updateOrderStatus(orderId: orderId, status: status);
      state = state.whenData(
        (orders) => [
          for (final o in orders)
            if (o.id == orderId) o.copyWith(status: status) else o,
        ],
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTracking({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String carrier,
  }) async {
    try {
      await _repo.updateOrderTracking(
        orderId:        orderId,
        trackingNumber: trackingNumber,
        trackingUrl:    trackingUrl,
        carrier:        carrier,
      );
      final now = DateTime.now();
      state = state.whenData(
        (orders) => [
          for (final o in orders)
            if (o.id == orderId)
              o.copyWith(
                status:                 OrderStatus.shipped,
                shippingTrackingNumber: trackingNumber,
                shippingTrackingUrl:    trackingUrl,
                shippingCarrier:        carrier,
                shippedAt:              now,
              )
            else
              o,
        ],
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
