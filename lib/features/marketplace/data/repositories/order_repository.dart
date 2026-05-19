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

  /// Insert a pending order row for a single vendor and return its id.
  /// [shopId] is required because the orders table has a NOT NULL FK to shops.
  Future<String> insertPendingOrder({
    required String buyerId,
    required String shopId,
    required CartState cart,
  }) async {
    final row = await _client
        .from('marketplace_orders')
        .insert({
          'buyer_id':    buyerId,
          'shop_id':     shopId,
          'title':       'PetFolio Order',
          'status':      'pending',
          'amount_cents': cart.totalCentsForShop(shopId),
          'currency':    'usd',
          'line_items':  cart.lineItemsJsonForShop(shopId),
        })
        .select('id')
        .single();

    return row['id'] as String;
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

  /// No-op — the stripe-webhook Edge Function transitions pending → processing
  /// when payment_intent.succeeded fires. Kept so the existing checkout
  /// controller compiles until Phase 5 removes the call.
  Future<void> confirmOrder(String orderId) async {}

  /// Cancel a pending order (user dismissed Payment Sheet).
  Future<void> cancelOrder(String orderId) async {
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
    await _client
        .from('marketplace_orders')
        .update({'status': status.name})
        .eq('id', orderId);
  }

  /// Vendor pastes tracking info after shipping.
  Future<void> updateOrderTracking({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String carrier,
  }) async {
    await _client
        .from('marketplace_orders')
        .update({
          'shipping_tracking_number': trackingNumber,
          'shipping_tracking_url':    trackingUrl,
          'shipping_carrier':         carrier,
          'shipped_at':               DateTime.now().toIso8601String(),
          'status':                   OrderStatus.shipped.name,
        })
        .eq('id', orderId);
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
