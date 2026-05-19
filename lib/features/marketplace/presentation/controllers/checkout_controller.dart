import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/order_repository.dart'
    show
        InsufficientStockException,
        OrderRepository,
        orderRepositoryProvider,
        PaymentTimeoutException,
        ShopInactiveException,
        ShopNotVerifiedException;
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
    this.verificationPending = false,
  });

  final CheckoutStatus status;
  final String? orderId;

  /// Which vendor's checkout is currently in progress.
  final String? activeShopId;

  /// Non-null only on [CheckoutStatus.failure]. Null on user cancel.
  final String? errorMessage;

  /// True when Stripe confirmed but the backend webhook has not yet updated
  /// the order row within the polling window.  The charge still went through;
  /// the UI should prompt the user to check their Orders screen.
  final bool verificationPending;

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
    bool? verificationPending,
    bool clearError = false,
  }) =>
      CheckoutState(
        status:              status              ?? this.status,
        orderId:             orderId             ?? this.orderId,
        activeShopId:        activeShopId        ?? this.activeShopId,
        verificationPending: verificationPending ?? this.verificationPending,
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

      // 5. Verify backend received the webhook and updated the order row.
      //    pollOrderConfirmation throws PaymentTimeoutException after 15 s if
      //    the webhook is delayed — treated as a soft success below.
      try {
        await _repo.pollOrderConfirmation(orderId);
      } on PaymentTimeoutException {
        ref.read(cartProvider.notifier).clearShopCart(shopId);
        ref.invalidate(buyerOrdersProvider);
        state = state.copyWith(
          status: CheckoutStatus.success,
          verificationPending: true,
          clearError: true,
        );
        return;
      }

      // 6. Backend confirmed — full success.
      ref.read(cartProvider.notifier).clearShopCart(shopId);
      ref.invalidate(buyerOrdersProvider);
      state = state.copyWith(
        status: CheckoutStatus.success,
        verificationPending: false,
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

  /// Cash-on-Delivery checkout — inserts order then validates via Edge Function.
  Future<void> startCodCheckoutForShop(String shopId) async {
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
      orderId = await _repo.insertPendingOrder(
        buyerId: user.id,
        shopId: shopId,
        cart: cart,
      );
      state = state.copyWith(orderId: orderId);

      final confirmedOrderId = await _repo.confirmCodOrder(orderId);

      ref.read(cartProvider.notifier).clearShopCart(shopId);
      ref.invalidate(buyerOrdersProvider);
      state = state.copyWith(
        status: CheckoutStatus.success,
        orderId: confirmedOrderId,
        clearError: true,
      );
    } on ShopInactiveException catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status: CheckoutStatus.failure,
        activeShopId: shopId,
        errorMessage: e.toString(),
      );
    } on InsufficientStockException catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status: CheckoutStatus.failure,
        activeShopId: shopId,
        errorMessage: e.toString(),
      );
    } catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status: CheckoutStatus.failure,
        activeShopId: shopId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Legacy single-vendor checkout for the PetFolio Official shop.
  Future<void> startCheckout() => startCheckoutForShop(_petfolioOfficialShopId);

  bool get isLoading =>
      state.status == CheckoutStatus.loadingIntent ||
      state.status == CheckoutStatus.awaitingSheet;

  /// Reset back to idle (e.g. after displaying an error snackbar).
  void reset() => state = const CheckoutState(status: CheckoutStatus.idle);
}
