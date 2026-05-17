import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/order_repository.dart';
import 'buyer_orders_controller.dart';
import 'cart_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _petfolioOfficialShopId = 'cccccccc-0000-0000-0000-cccccccccccc';

// ─────────────────────────────────────────────────────────────────────────────
// Checkout status
// ─────────────────────────────────────────────────────────────────────────────

enum CheckoutStatus {
  idle,
  loadingIntent,  // inserting order row + calling Edge Function
  awaitingSheet,  // Stripe Payment Sheet is visible
  success,        // payment confirmed
  failure,        // unrecoverable error (not cancel)
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout state
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutState {
  const CheckoutState({
    required this.status,
    this.orderId,
    this.activeShopId,
    this.errorMessage,
  });

  final CheckoutStatus status;
  final String? orderId;

  /// Which vendor's checkout is currently in progress.
  /// Used by the UI to show a loading indicator on the correct "Pay" button.
  final String? activeShopId;

  /// Non-null only on [CheckoutStatus.failure]. Null on user cancel.
  final String? errorMessage;

  bool get isLoading =>
      status == CheckoutStatus.loadingIntent ||
      status == CheckoutStatus.awaitingSheet;

  /// True when [shopId]'s checkout flow is in progress.
  bool isLoadingShop(String shopId) => isLoading && activeShopId == shopId;

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? orderId,
    String? activeShopId,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CheckoutState(
        status:       status       ?? this.status,
        orderId:      orderId      ?? this.orderId,
        activeShopId: activeShopId ?? this.activeShopId,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState(status: CheckoutStatus.idle);

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Per-vendor checkout — the main entry point called by vendor group "Pay" buttons.
  ///
  /// Flow: idle → loadingIntent → awaitingSheet → success | failure
  /// Cancel: awaitingSheet → idle (pending order row is cancelled)
  Future<void> startCheckoutForShop(String shopId) async {
    if (isLoading) return;

    final cart = ref.read(cartProvider);
    final shopItems = cart.itemsByShop[shopId] ?? [];
    if (shopItems.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const CheckoutState(
        status: CheckoutStatus.failure,
        errorMessage: 'You must be logged in to checkout.',
      );
      return;
    }

    state = CheckoutState(
      status: CheckoutStatus.loadingIntent,
      activeShopId: shopId,
    );

    String? orderId;

    try {
      // 1. Insert pending order row for this vendor.
      orderId = await _repo.insertPendingOrder(
        buyerId: user.id,
        shopId:  shopId,
        cart:    cart,
      );
      state = state.copyWith(orderId: orderId);

      // 2. Call Edge Function → get Stripe client_secret.
      final clientSecret = await _repo.createPaymentIntent(orderId);

      // 3. Initialize Payment Sheet.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PetFolio',
          style: ThemeMode.system,
        ),
      );

      state = state.copyWith(status: CheckoutStatus.awaitingSheet);

      // 4. Present Payment Sheet — suspends until dismissed.
      await Stripe.instance.presentPaymentSheet();

      // 5. Success — remove only this vendor's items from the cart.
      ref.read(cartProvider.notifier).clearShopCart(shopId);
      ref.invalidate(buyerOrdersProvider);
      state = state.copyWith(
        status: CheckoutStatus.success,
        clearError: true,
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (orderId != null) unawaited(_repo.cancelOrder(orderId));
        state = const CheckoutState(status: CheckoutStatus.idle);
      } else {
        if (orderId != null) unawaited(_repo.cancelOrder(orderId));
        state = CheckoutState(
          status:       CheckoutStatus.failure,
          activeShopId: shopId,
          errorMessage: e.error.localizedMessage ?? 'Payment failed.',
        );
      }
    } on ShopNotVerifiedException catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status:       CheckoutStatus.failure,
        activeShopId: shopId,
        errorMessage: e.toString(),
      );
    } catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status:       CheckoutStatus.failure,
        activeShopId: shopId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Legacy single-vendor checkout for the PetFolio Official shop.
  /// Kept for backward compatibility until Phase 6 screens migrate to
  /// per-vendor "Pay" buttons.
  Future<void> startCheckout() => startCheckoutForShop(_petfolioOfficialShopId);

  bool get isLoading =>
      state.status == CheckoutStatus.loadingIntent ||
      state.status == CheckoutStatus.awaitingSheet;

  /// Reset back to idle (e.g. after displaying an error snackbar).
  void reset() => state = const CheckoutState(status: CheckoutStatus.idle);
}
