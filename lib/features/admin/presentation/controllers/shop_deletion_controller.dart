import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shop_deletion_request.dart';
import '../../data/repositories/admin_repository.dart';

final shopDeletionRequestsProvider =
    AsyncNotifierProvider<ShopDeletionNotifier, List<ShopDeletionRequest>>(
  ShopDeletionNotifier.new,
);

class ShopDeletionNotifier
    extends AsyncNotifier<List<ShopDeletionRequest>> {
  @override
  Future<List<ShopDeletionRequest>> build() =>
      ref.read(adminRepositoryProvider).fetchPendingDeletionRequests();

  Future<void> resolve(
    String requestId, {
    required bool approve,
    String? rejectionNote,
  }) async {
    await ref.read(adminRepositoryProvider).resolveDeletionRequest(
          requestId,
          approve: approve,
          rejectionNote: rejectionNote,
        );
    final current = state.value ?? [];
    state = AsyncData(current.where((r) => r.id != requestId).toList());
  }

  Future<void> refresh() async {
    if (state is AsyncLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).fetchPendingDeletionRequests(),
    );
  }
}
