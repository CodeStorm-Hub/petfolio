import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/marketplace_order.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (_) => OrderRepository(Supabase.instance.client),
);

class OrderRepository {
  const OrderRepository(this._client);

  final SupabaseClient _client;

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Atomically validates the shop and inventory, creates the order row, and
  /// reserves stock in `inventory_reservations` — all in one Postgres transaction
  /// via RPC. Inventory is decremented later by `confirm_order_inventory` when
  /// the Stripe webhook confirms payment. Returns the new order id.
  Future<String> insertPendingOrder({
    required String buyerId,
    required String shopId,
    required CartState cart,
    String? promoCode,
  }) async {
    try {
      final result = await _client.rpc('process_checkout', params: {
        'p_buyer_id':   buyerId,
        'p_shop_id':    shopId,
        'p_cart_items': cart.rpcLineItemsJsonForShop(shopId),
        if (promoCode != null && promoCode.isNotEmpty)
          'p_promo_code': promoCode.toUpperCase().trim(),
      });
      return result as String;
    } on PostgrestException catch (e) {
      mapAndThrowCheckoutRpcException(e);
    }
  }

  /// Call the Edge Function to create (or retrieve) a Stripe PaymentIntent.
  /// Returns the client_secret.
  Future<String> createPaymentIntent(String orderId) async {
    final response = await _client.functions.invoke(
      'create-payment-intent',
      body: {'orderId': orderId, 'payment_method': 'stripe'},
    );

    if (response.status != 200) {
      final data = response.data as Map<String, dynamic>?;
      final code = data?['code'] as String?;
      if (code == 'SHOP_NOT_VERIFIED') throw const ShopNotVerifiedException();
      throw Exception('Edge Function error ${response.status}: ${response.data}');
    }

    final clientSecret =
        (response.data as Map<String, dynamic>)['clientSecret'] as String?;
    if (clientSecret == null) throw Exception('Missing clientSecret in response');
    return clientSecret;
  }

  Future<String> createCheckoutSession({
    required String orderId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _client.functions.invoke(
      'create-payment-intent',
      body: {
        'orderId': orderId,
        'payment_method': 'stripe',
        'checkout_mode': true,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );

    if (response.status != 200) {
      final data = response.data as Map<String, dynamic>?;
      final code = data?['code'] as String?;
      if (code == 'SHOP_NOT_VERIFIED') throw const ShopNotVerifiedException();
      throw Exception('Edge Function error ${response.status}: ${response.data}');
    }

    final checkoutUrl =
        (response.data as Map<String, dynamic>)['checkoutUrl'] as String?;
    if (checkoutUrl == null) {
      throw Exception('Missing checkoutUrl in response');
    }
    return checkoutUrl;
  }

  Future<void> setPaymentMethod(String orderId, PaymentMethod method) async {
    await _client
        .from('marketplace_orders')
        .update({'payment_method': method.name})
        .eq('id', orderId)
        .eq('status', 'pending');
  }

  /// Validate a CoD order via the Edge Function (inventory check, shop active
  /// guard) and stamp payment_method='cod' on the row server-side.
  /// Returns the confirmed orderId on success.
  Future<String> confirmCodOrder(String orderId) async {
    final response = await _client.functions.invoke(
      'create-payment-intent',
      body: {'orderId': orderId, 'payment_method': 'cod'},
    );

    if (response.status != 200) {
      final data = response.data as Map<String, dynamic>?;
      final code = data?['code'] as String?;
      final message = data?['error'] as String?;
      if (code == 'SHOP_INACTIVE') throw const ShopInactiveException();
      if (code == 'INSUFFICIENT_STOCK') {
        throw InsufficientStockException(
          productName: message ?? 'A product',
          available: (data?['available'] as num?)?.toInt() ?? 0,
          requested: (data?['requested'] as num?)?.toInt() ?? 0,
        );
      }
      throw Exception('CoD confirmation failed ${response.status}: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['orderId'] as String? ?? orderId;
  }

  /// Create an SSLCommerz payment session for bKash / Nagad checkout.
  /// Returns the gateway URL to open in an external browser.
  Future<SslcommerzSessionResult> createSslcommerzSession({
    required String orderId,
    required PaymentMethod paymentMethod,
    required String successUrl,
    required String failUrl,
    required String cancelUrl,
  }) async {
    final response = await _client.functions.invoke(
      'create-sslcommerz-session',
      body: {
        'orderId':        orderId,
        'payment_method': paymentMethod.name,
        'success_url':    successUrl,
        'fail_url':       failUrl,
        'cancel_url':     cancelUrl,
      },
    );

    if (response.status != 200) {
      final data = response.data as Map<String, dynamic>?;
      final code = data?['code'] as String?;
      if (code == 'SHOP_NOT_VERIFIED') throw const ShopNotVerifiedException();
      if (code == 'SHOP_INACTIVE')     throw const ShopInactiveException();
      throw Exception('SSLCommerz session error ${response.status}: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    return SslcommerzSessionResult(
      gatewayUrl:    data['gatewayUrl']    as String,
      transactionId: data['transactionId'] as String,
    );
  }

  /// No-op — the stripe-webhook Edge Function transitions pending → processing
  /// when payment_intent.succeeded fires. Kept so the existing checkout
  /// controller compiles until Phase 5 removes the call.
  Future<void> confirmOrder(String orderId) async {}

  /// Cancel a pending order (user dismissed Payment Sheet).
  /// Releases the inventory reservation before cancelling the order row.
  Future<void> cancelOrder(String orderId) async {
    try {
      await _client.rpc(
        'release_order_inventory',
        params: {'p_order_id': orderId},
      );
    } catch (_) {}
    await _client
        .from('marketplace_orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId)
        .eq('status', 'pending');
  }

  // ── Vendor fulfillment ─────────────────────────────────────────────────────

  /// Vendor advances an order status (e.g. processing → shipped).
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _client.rpc('vendor_update_order', params: {
      'p_order_id': orderId,
      'p_status':   status.name,
    });
  }

  /// Vendor pastes tracking info after shipping.
  Future<void> updateOrderTracking({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String carrier,
  }) async {
    await _client.rpc('vendor_update_order', params: {
      'p_order_id':        orderId,
      'p_status':          OrderStatus.shipped.name,
      'p_tracking_number': trackingNumber,
      'p_tracking_url':    trackingUrl,
      'p_carrier':         carrier,
    });
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Buyer's full order history, newest first.
  Future<List<MarketplaceOrder>> fetchBuyerOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('marketplace_orders')
        .select()
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => MarketplaceOrder.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Vendor's incoming orders for their shop, newest first.
  Future<List<MarketplaceOrder>> fetchVendorOrders(String shopId) async {
    final rows = await _client
        .from('marketplace_orders')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => MarketplaceOrder.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single order by id.
  Future<MarketplaceOrder> fetchOrder(String orderId) async {
    final row = await _client
        .from('marketplace_orders')
        .select()
        .eq('id', orderId)
        .single();
    return MarketplaceOrder.fromJson(row);
  }

  /// Poll until the backend confirms payment (webhook updated the row) or
  /// [timeout] elapses.  Throws [PaymentTimeoutException] on timeout so the
  /// caller can distinguish "still pending" from a hard failure.
  Future<MarketplaceOrder> pollOrderConfirmation(
    String orderId, {
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final order = await fetchOrder(orderId);
      if (order.paymentStatus == PaymentStatus.paid ||
          order.status == OrderStatus.processing) {
        return order;
      }
      if (order.status == OrderStatus.cancelled) {
        throw Exception('Order was cancelled during verification.');
      }
      await Future<void>.delayed(interval);
    }
    throw const PaymentTimeoutException();
  }
}

class SslcommerzSessionResult {
  const SslcommerzSessionResult({
    required this.gatewayUrl,
    required this.transactionId,
  });

  final String gatewayUrl;
  final String transactionId;
}

/// Stripe confirmed the payment but the backend webhook has not updated the
/// order row within the polling window.  The charge almost certainly went
/// through — callers should treat this as a soft success and tell the user
/// to check their orders.
class PaymentTimeoutException implements Exception {
  const PaymentTimeoutException();

  @override
  String toString() =>
      'Your payment was accepted but confirmation is still processing. '
      'Check your Orders for the final status.';
}

class ShopNotVerifiedException implements Exception {
  const ShopNotVerifiedException();

  @override
  String toString() =>
      'This seller has not completed their payment setup yet.';
}

@visibleForTesting
Never mapAndThrowCheckoutRpcException(PostgrestException e) {
  final msg = e.message;
  if (msg.contains('SHOP_INACTIVE')) throw const ShopInactiveException();
  if (msg.contains('SHOP_NOT_VERIFIED')) throw const ShopNotVerifiedException();
  if (msg.contains('INSUFFICIENT_STOCK:')) {
    final parts = msg.split(':');
    throw InsufficientStockException(
      productName: parts.length > 1 ? parts[1] : 'A product',
      available: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
      requested: parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0,
    );
  }
  throw e;
}

class ShopInactiveException implements Exception {
  const ShopInactiveException();

  @override
  String toString() => 'This shop is currently inactive.';
}

class InsufficientStockException implements Exception {
  const InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  });

  final String productName;
  final int available;
  final int requested;

  @override
  String toString() =>
      'Only $available of "$productName" available (requested $requested).';
}
