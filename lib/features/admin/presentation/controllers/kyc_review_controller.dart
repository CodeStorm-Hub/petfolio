import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../marketplace/data/models/shop.dart';
import '../../data/repositories/admin_repository.dart';

final kycReviewProvider =
    AsyncNotifierProvider<KycReviewNotifier, List<Shop>>(
  KycReviewNotifier.new,
);

class KycReviewNotifier extends AsyncNotifier<List<Shop>> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<List<Shop>> build() => _repo.fetchSubmittedKycShops();

  Future<void> approve(String shopId) async {
    await _repo.approveKyc(shopId);
    state = AsyncData(
      state.requireValue.where((s) => s.id != shopId).toList(),
    );
  }

  Future<void> reject(String shopId, String reason) async {
    await _repo.rejectKyc(shopId, reason);
    state = AsyncData(
      state.requireValue.where((s) => s.id != shopId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.fetchSubmittedKycShops);
  }

  Future<String> getDocumentUrl(String storagePath) =>
      _repo.getSecureDocumentUrl(storagePath);
}
