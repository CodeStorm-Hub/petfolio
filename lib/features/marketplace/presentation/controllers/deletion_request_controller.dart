import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/shop_repository.dart';
import 'my_shop_controller.dart';

final deletionRequestProvider =
    AsyncNotifierProvider<DeletionRequestNotifier, Map<String, dynamic>?>(
  DeletionRequestNotifier.new,
);

class DeletionRequestNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return null;
    return ref.read(shopRepositoryProvider).fetchMyDeletionRequest(shop.id);
  }

  Future<void> submitRequest(String shopId, {String? reason}) async {
    await ref.read(shopRepositoryProvider).requestShopDeletion(
          shopId,
          reason: reason,
        );
    state = await AsyncValue.guard(
      () => ref.read(shopRepositoryProvider).fetchMyDeletionRequest(shopId),
    );
  }
}

String parseDeletionError(Object e) {
  final msg = e.toString();
  if (msg.contains('ACTIVE_ORDERS:')) {
    final raw = msg.split('ACTIVE_ORDERS:').last.trim();
    final count = RegExp(r'\d+').firstMatch(raw)?.group(0) ?? raw;
    return 'You have $count active order(s). Fulfil them before requesting deletion.';
  }
  if (msg.contains('PENDING_REQUEST_EXISTS')) {
    return 'A deletion request is already pending for this shop.';
  }
  if (msg.contains('NOT_SHOP_OWNER')) return 'You do not own this shop.';
  return 'Something went wrong. Please try again.';
}
