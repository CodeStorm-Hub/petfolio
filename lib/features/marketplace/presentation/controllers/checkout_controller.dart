import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/platform/platform_payments.dart';
import '../../../../core/platform/web_app_url.dart';
import '../../../../core/services/stripe_init_service.dart';
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
const _stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

// ─────────────────────────────────────────────────────────────────────────────
// Checkout status
// ─────────────────────────────────────────────────────────────────────────────

enum CheckoutStatus {
  idle,
  loadingIntent,
  awaitingSheet,
  awaitingRedirect,
  success,
  failure,
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
      status == CheckoutStatus.awaitingSheet ||
      status == CheckoutStatus.awaitingRedirect;

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

      if (useStripeHostedCheckout) {
        final checkoutUrl = await _repo.createCheckoutSession(
          orderId: orderId,
          successUrl: petfolioAppUrl(
            '/marketplace/order/$orderId',
            queryParameters: const {'stripe': 'success'},
          ),
          cancelUrl: petfolioAppUrl(
            '/marketplace',
            queryParameters: const {'stripe': 'cancel'},
          ),
        );

        state = state.copyWith(status: CheckoutStatus.awaitingRedirect);

        final launched = await launchUrl(
          Uri.parse(checkoutUrl),
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_self' : null,
        );
        if (!launched) {
          throw Exception('Could not open Stripe Checkout.');
        }
        return;
      }

      final clientSecret = await _repo.createPaymentIntent(orderId);

      await ensureStripeReady(publishableKey: _stripePublishableKey);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PetFolio',
          style: ThemeMode.system,
          googlePay: kIsWeb
              ? null
              : const PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  currencyCode: 'usd',
                  testEnv: true,
                ),
          applePay: kIsWeb
              ? null
              : const PaymentSheetApplePay(
                  merchantCountryCode: 'US',
                ),
        ),
      );

      state = state.copyWith(status: CheckoutStatus.awaitingSheet);

      await Stripe.instance.presentPaymentSheet();

      await _finalizePaidCheckout(shopId: shopId, orderId: orderId);
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

  Future<void> resumeWebCheckoutIfNeeded() async {
    if (!kIsWeb) return;

    final orderId = state.orderId;
    final shopId = state.activeShopId;
    if (state.status != CheckoutStatus.awaitingRedirect ||
        orderId == null ||
        shopId == null) {
      return;
    }

    try {
      await _finalizePaidCheckout(shopId: shopId, orderId: orderId);
    } catch (_) {}
  }

  Future<void> _finalizePaidCheckout({
    required String shopId,
    required String orderId,
  }) async {
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

    ref.read(cartProvider.notifier).clearShopCart(shopId);
    ref.invalidate(buyerOrdersProvider);
    state = state.copyWith(
      status: CheckoutStatus.success,
      verificationPending: false,
      clearError: true,
    );
  }

  Future<void> startCheckout() => startCheckoutForShop(_petfolioOfficialShopId);

  bool get isLoading =>
      state.status == CheckoutStatus.loadingIntent ||
      state.status == CheckoutStatus.awaitingSheet ||
      state.status == CheckoutStatus.awaitingRedirect;

  void reset() => state = const CheckoutState(status: CheckoutStatus.idle);
}
