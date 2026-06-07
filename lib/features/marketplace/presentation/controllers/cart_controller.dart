import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/prefs_schema.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — global singleton, no family key
// ─────────────────────────────────────────────────────────────────────────────

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CartNotifier extends Notifier<CartState> {
  SecureStorageService get _secureStorage =>
      ref.read(secureStorageServiceProvider);

  String get _secureKey {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null
        ? '${PrefsSchema.secureCartPrefix}$uid'
        : PrefsSchema.secureCartPrefix;
  }

  String get _legacyKey {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null ? '${PrefsSchema.cartPrefix}$uid' : 'cart';
  }

  @override
  CartState build() {
    ref.listen<bool>(isLoggedInProvider, (prev, next) {
      if (prev != next) {
        state = CartState.empty;
        _loadFromPrefs();
      }
    });
    _loadFromPrefs();
    return CartState.empty;
  }

  Future<void> _loadFromPrefs() async {
    try {
      var raw = await _secureStorage.read(_secureKey);
      if (raw == null) {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_legacyKey);
        if (raw != null) {
          await _secureStorage.write(_secureKey, raw);
          await prefs.remove(_legacyKey);
        }
      }
      if (raw == null) return;
      state = CartState.fromStorageJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {}
  }

  void _persist() {
    final snapshot = state;
    _secureStorage.write(
      _secureKey,
      jsonEncode(snapshot.toStorageJson()),
    );
  }

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
    _persist();
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
    _persist();
  }

  /// Remove a line entirely.
  void remove(String productId, {bool isSubscribed = false}) {
    state = CartState(
      items: state.items
          .where((i) =>
              !(i.product.id == productId && i.isSubscribed == isSubscribed))
          .toList(),
    );
    _persist();
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
    _persist();
  }

  /// Change delivery frequency for a subscribed line.
  void setFrequency(String productId, int weeks) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return;

    items[idx] = items[idx].copyWith(frequencyWeeks: weeks);
    state = CartState(items: items);
    _persist();
  }

  /// Remove all items belonging to a specific vendor (called after per-vendor checkout).
  void clearShopCart(String shopId) {
    state = CartState(
      items: state.items
          .where((i) => i.product.shopId != shopId)
          .toList(),
    );
    _persist();
  }

  /// Empty the entire cart and remove its persisted snapshot.
  void clear() {
    state = CartState.empty;
    _secureStorage.delete(_secureKey);
    SharedPreferences.getInstance().then((p) => p.remove(_legacyKey));
  }
}
