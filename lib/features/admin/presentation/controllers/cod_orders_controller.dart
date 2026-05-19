import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../marketplace/data/models/marketplace_order.dart';
import '../../data/repositories/admin_repository.dart';

final codOrdersProvider =
    AsyncNotifierProvider<CodOrdersNotifier, List<MarketplaceOrder>>(
  CodOrdersNotifier.new,
);

class CodOrdersNotifier extends AsyncNotifier<List<MarketplaceOrder>> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<List<MarketplaceOrder>> build() => _repo.fetchDeliveredCodOrders();

  Future<void> markCashReceived(String orderId) async {
    await _repo.markCashReceived(orderId);
    state = AsyncData(
      state.requireValue.where((o) => o.id != orderId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.fetchDeliveredCodOrders);
  }
}
