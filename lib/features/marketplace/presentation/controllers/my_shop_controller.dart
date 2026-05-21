import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/shop.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'deletion_request_controller.dart';

part 'my_shop_controller.g.dart';

@Riverpod(keepAlive: true)
class MyShop extends _$MyShop {
  ShopRepository get _repo => ref.read(shopRepositoryProvider);

  @override
  Future<Shop?> build() => _repo.fetchMyShop();

  Future<bool> createShop({
    required String name,
    required String slug,
    String? description,
    PayoutMethod payoutMethod = PayoutMethod.stripe,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.createShop(
        name: name,
        slug: slug,
        description: description,
        payoutMethod: payoutMethod,
      ),
    );
    return state.hasValue && state.value != null;
  }

  Future<bool> submitKyc({
    required Map<String, String> bankDetails,
    Uint8List? nidBytes,
    Uint8List? tradeLicenseBytes,
  }) async {
    final shop = state.value;
    if (shop == null) return false;
    final prev = state;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(kycRepositoryProvider).submitKyc(
        shopId: shop.id,
        bankDetails: bankDetails,
        nidBytes: nidBytes,
        tradeLicenseBytes: tradeLicenseBytes,
      ),
    );
    if (state.hasError) {
      state = prev;
      return false;
    }
    return true;
  }

  Future<bool> updateShop({
    String? shopName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    final shop = state.value;
    if (shop == null) return false;

    final prev = state;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.updateShop(
        id:          shop.id,
        shopName:    shopName,
        description: description,
        logoUrl:     logoUrl,
        bannerUrl:   bannerUrl,
      ),
    );
    if (state.hasError) {
      state = prev;
      return false;
    }
    return true;
  }

  Future<String> startOnboarding() async {
    final shop = state.value;
    if (shop == null) {
      throw const StripeOnboardingException('Create your shop before setting up payments.');
    }
    return _repo.startOnboarding(shop.id);
  }

  Future<void> refreshAfterOnboarding() async {
    final snapshot = state;
    const maxAttempts = 4;
    const baseDelayMs = 500;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: baseDelayMs * (1 << (attempt - 1))),
        );
      }
      try {
        final shop = await _repo.fetchMyShop();
        state = AsyncValue.data(shop);
        ref.invalidate(deletionRequestProvider);
        return;
      } catch (e, st) {
        if (attempt < maxAttempts - 1) continue;
        state = snapshot.hasValue ? snapshot : AsyncValue.error(e, st);
        return;
      }
    }
  }
}
