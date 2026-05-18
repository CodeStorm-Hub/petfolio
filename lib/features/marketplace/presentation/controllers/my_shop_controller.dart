import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';

final myShopProvider =
    AsyncNotifierProvider<MyShopNotifier, Shop?>(MyShopNotifier.new);

class MyShopNotifier extends AsyncNotifier<Shop?> {
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
      () => _repo.submitKyc(
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

  /// Calls the stripe-onboard-vendor Edge Function and returns the KYC URL.
  Future<String> startOnboarding() async {
    final shop = state.value;
    if (shop == null) {
      throw const StripeOnboardingException('Create your shop before setting up payments.');
    }
    return _repo.startOnboarding(shop.id);
  }

  /// Re-fetches the shop row after the user returns from Stripe KYC.
  /// The webhook may have already set is_verified; this polls for the update.
  Future<void> refreshAfterOnboarding() async {
    final previous = state;
    try {
      final shop = await _repo.fetchMyShop();
      state = AsyncValue.data(shop);
    } catch (e, st) {
      state = previous.hasValue ? previous : AsyncValue.error(e, st);
    }
  }
}
