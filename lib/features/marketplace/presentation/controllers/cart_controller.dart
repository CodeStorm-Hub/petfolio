import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — global singleton, no family key
// ─────────────────────────────────────────────────────────────────────────────

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory cart.  All state is lost on app restart (intentional — the order
/// row in Supabase is the source of truth once checkout begins).
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState.empty;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Add one unit of [product] to the cart (or increment quantity if already
  /// present with the same subscription preference).
  void add(
    Product product, {
    bool subscribe = false,
    int frequencyWeeks = 4,
  }) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere(
      (i) => i.product.id == product.id && i.isSubscribed == subscribe,
    );

    if (idx == -1) {
      items.add(CartItem(
        product: product,
        quantity: 1,
        isSubscribed: subscribe && product.subscribable,
        frequencyWeeks: frequencyWeeks,
      ));
    } else {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    }
    state = CartState(items: items);
  }

  /// Remove one unit; remove the line entirely if quantity reaches 0.
  void decrement(String productId, {bool isSubscribed = false}) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere(
      (i) => i.product.id == productId && i.isSubscribed == isSubscribed,
    );
    if (idx == -1) return;

    final item = items[idx];
    if (item.quantity <= 1) {
      items.removeAt(idx);
    } else {
      items[idx] = item.copyWith(quantity: item.quantity - 1);
    }
    state = CartState(items: items);
  }

  /// Remove a line entirely.
  void remove(String productId, {bool isSubscribed = false}) {
    state = CartState(
      items: state.items
          .where((i) =>
              !(i.product.id == productId && i.isSubscribed == isSubscribed))
          .toList(),
    );
  }

  /// Toggle subscribe-and-save on an existing cart line.
  void toggleSubscription(String productId) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return;

    final item = items[idx];
    if (!item.product.subscribable) return;

    items[idx] = item.copyWith(isSubscribed: !item.isSubscribed);
    state = CartState(items: items);
  }

  /// Change delivery frequency for a subscribed line.
  void setFrequency(String productId, int weeks) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return;

    items[idx] = items[idx].copyWith(frequencyWeeks: weeks);
    state = CartState(items: items);
  }

  /// Remove all items belonging to a specific vendor (called after per-vendor checkout).
  void clearShopCart(String shopId) {
    state = CartState(
      items: state.items
          .where((i) => i.product.shopId != shopId)
          .toList(),
    );
  }

  /// Empty the entire cart.
  void clear() => state = CartState.empty;
}
