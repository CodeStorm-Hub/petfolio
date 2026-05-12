import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final orderRepositoryProvider = Provider<OrderRepository>(
  (_) => OrderRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class OrderRepository {
  const OrderRepository(this._client);

  final SupabaseClient _client;

  /// Insert a pending order row and return its id.
  ///
  /// Called BEFORE the Stripe Payment Sheet is presented so we have an
  /// idempotency key ([orderId]) ready for the Edge Function.
  Future<String> insertPendingOrder({
    required String buyerId,
    required CartState cart,
  }) async {
    final row = await _client
        .from('marketplace_orders')
        .insert({
          'buyer_id':    buyerId,
          'status':      'pending',
          'amount_cents': cart.totalCents,
          'currency':    'usd',
          'line_items':  cart.toLineItemsJson(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  /// Request the Edge Function to create (or retrieve) a PaymentIntent.
  /// Returns the Stripe client_secret.
  Future<String> createPaymentIntent(String orderId) async {
    final response = await _client.functions.invoke(
      'create-payment-intent',
      body: {'orderId': orderId},
    );

    if (response.status != 200) {
      throw Exception('Edge Function error ${response.status}: ${response.data}');
    }

    final clientSecret = (response.data as Map<String, dynamic>)['clientSecret'] as String?;
    if (clientSecret == null) throw Exception('Missing clientSecret in response');
    return clientSecret;
  }

  /// Mark the order as paid after Payment Sheet succeeds.
  Future<void> confirmOrder(String orderId) async {
    await _client
        .from('marketplace_orders')
        .update({'status': 'paid'})
        .eq('id', orderId);
  }

  /// Mark the order as cancelled (user dismissed Payment Sheet).
  Future<void> cancelOrder(String orderId) async {
    await _client
        .from('marketplace_orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId);
  }

  /// Fetch a confirmed order for the confirmation screen.
  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    final row = await _client
        .from('marketplace_orders')
        .select()
        .eq('id', orderId)
        .single();
    return row as Map<String, dynamic>;
  }
}
