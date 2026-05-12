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

// Remote table: public.marketplace_orders
// Columns used:
//   id                       uuid  PK
//   buyer_id                 uuid  (auth.uid of the purchaser)
//   title                    text  (required, short human label for the order)
//   amount_cents             bigint (total in smallest currency unit, e.g. 1998 = $19.98)
//   currency                 text  default 'usd'
//   status                   text  pending | confirmed | cancelled | ...
//   stripe_payment_intent_id text  nullable
//   line_items               jsonb (cart snapshot)

class OrderRepository {
  const OrderRepository(this._client);

  final SupabaseClient _client;

  /// Insert a pending order and return its id.
  Future<String> insertPendingOrder({
    required String buyerId,
    required CartState cart,
  }) async {
    final row = await _client
        .from('marketplace_orders')
        .insert({
          'buyer_id':    buyerId,
          'title':       'PetFolio Order',
          'status':      'pending',
          'amount_cents': cart.totalCents,
          'line_items':  cart.toLineItemsJson(),
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
      body: {'orderId': orderId},
    );

    if (response.status != 200) {
      throw Exception('Edge Function error ${response.status}: ${response.data}');
    }

    final clientSecret =
        (response.data as Map<String, dynamic>)['clientSecret'] as String?;
    if (clientSecret == null) throw Exception('Missing clientSecret in response');
    return clientSecret;
  }

  /// Mark the order as confirmed after the Payment Sheet succeeds.
  Future<void> confirmOrder(String orderId) async {
    await _client
        .from('marketplace_orders')
        .update({'status': 'confirmed'})
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
    return row;
  }
}
