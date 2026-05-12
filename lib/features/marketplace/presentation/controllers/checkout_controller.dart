import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/order_repository.dart';
import 'cart_controller.dart';
import 'package:flutter/material.dart';

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
    this.errorMessage,
  });

  final CheckoutStatus status;
  final String? orderId;

  /// Non-null only on [CheckoutStatus.failure].  Null on user cancel.
  final String? errorMessage;

  bool get isLoading =>
      status == CheckoutStatus.loadingIntent ||
      status == CheckoutStatus.awaitingSheet;

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? orderId,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CheckoutState(
        status:       status       ?? this.status,
        orderId:      orderId      ?? this.orderId,
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

/// Drives the full checkout flow:
///   idle → loadingIntent → awaitingSheet → success | failure
///
/// Cancel path (user swipes down Payment Sheet):
///   awaitingSheet → idle  (silent; order row is cancelled in Supabase)
class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState(status: CheckoutStatus.idle);

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Entry point called by the "Pay" button.
  Future<void> startCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const CheckoutState(
        status: CheckoutStatus.failure,
        errorMessage: 'You must be logged in to checkout.',
      );
      return;
    }

    state = const CheckoutState(status: CheckoutStatus.loadingIntent);

    String? orderId;

    try {
      // 1. Insert pending order row → get idempotency UUID.
      orderId = await _repo.insertPendingOrder(
        buyerId: user.id,
        cart: cart,
      );
      state = state.copyWith(orderId: orderId);

      // 2. Call Edge Function → get Stripe client_secret.
      final clientSecret = await _repo.createPaymentIntent(orderId);

      // 3. Initialize the Payment Sheet.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PetFolio',
          style: ThemeMode.system,
        ),
      );

      state = state.copyWith(status: CheckoutStatus.awaitingSheet);

      // 4. Present the Payment Sheet — this suspends until dismissed.
      await Stripe.instance.presentPaymentSheet();

      // 5. Success path.
      await _repo.confirmOrder(orderId);
      ref.read(cartProvider.notifier).clear();
      state = state.copyWith(
        status: CheckoutStatus.success,
        clearError: true,
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User dismissed — silent cancel, clean up the pending row.
        if (orderId != null) unawaited(_repo.cancelOrder(orderId));
        state = const CheckoutState(status: CheckoutStatus.idle);
      } else {
        if (orderId != null) unawaited(_repo.cancelOrder(orderId));
        state = CheckoutState(
          status: CheckoutStatus.failure,
          errorMessage: e.error.localizedMessage ?? 'Payment failed.',
        );
      }
    } catch (e) {
      if (orderId != null) unawaited(_repo.cancelOrder(orderId));
      state = CheckoutState(
        status: CheckoutStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset back to idle (e.g. after displaying an error snackbar).
  void reset() => state = const CheckoutState(status: CheckoutStatus.idle);
}
