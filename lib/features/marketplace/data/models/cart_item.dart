import '../../domain/services/currency_formatter.dart';
import 'product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CartItem — one line in the in-memory cart
// ─────────────────────────────────────────────────────────────────────────────

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    required this.isSubscribed,
    required this.frequencyWeeks,
    this.variantId,
    this.overridePriceCents,
  });

  final Product product;
  final int quantity;
  final bool isSubscribed;
  final int frequencyWeeks;
  final String? variantId;
  final int? overridePriceCents;

  // ── Computed ───────────────────────────────────────────────────────────────

  int get unitCents {
    if (overridePriceCents != null) {
      return isSubscribed && product.subscribable
          ? (overridePriceCents! * 0.88).round()
          : overridePriceCents!;
    }
    return isSubscribed && product.subscribable
        ? product.subPriceCents
        : product.priceCents;
  }

  int get lineTotalCents => unitCents * quantity;

  String get lineTotalFormatted => formatCents(lineTotalCents);

  int get savingsCentsTotal =>
      isSubscribed && product.subscribable
          ? (product.priceCents - product.subPriceCents) * quantity
          : 0;

  // ── Copy helpers ───────────────────────────────────────────────────────────

  CartItem copyWith({
    int? quantity,
    bool? isSubscribed,
    int? frequencyWeeks,
    String? variantId,
    int? overridePriceCents,
  }) =>
      CartItem(
        product:             product,
        quantity:            quantity            ?? this.quantity,
        isSubscribed:        isSubscribed        ?? this.isSubscribed,
        frequencyWeeks:      frequencyWeeks      ?? this.frequencyWeeks,
        variantId:           variantId           ?? this.variantId,
        overridePriceCents:  overridePriceCents  ?? this.overridePriceCents,
      );

  // ── JSON (for persisting to Supabase line_items column) ───────────────────

  Map<String, dynamic> toJson() => {
        'product_id':       product.id,
        'product_name':     product.name,
        'shop_id':          product.shopId,
        'quantity':         quantity,
        'unit_cents':       unitCents,
        'line_total_cents': lineTotalCents,
        'is_subscribed':    isSubscribed,
        'frequency_weeks':  frequencyWeeks,
        if (variantId != null) 'variant_id': variantId,
      };

  Map<String, dynamic> rpcJson() => {
        'product_id':      product.id,
        'quantity':        quantity,
        'is_subscribed':   isSubscribed,
        'frequency_weeks': frequencyWeeks,
        if (variantId != null) 'variant_id': variantId,
      };

  // ── JSON (for local SharedPreferences persistence — full round-trip) ───────

  Map<String, dynamic> toStorageJson() => {
        'product':              product.toStorageJson(),
        'quantity':             quantity,
        'is_subscribed':        isSubscribed,
        'frequency_weeks':      frequencyWeeks,
        if (variantId != null) 'variant_id': variantId,
        if (overridePriceCents != null) 'override_price_cents': overridePriceCents,
      };

  factory CartItem.fromStorageJson(Map<String, dynamic> json) => CartItem(
        product:             Product.fromStorageJson(json['product'] as Map<String, dynamic>),
        quantity:            json['quantity'] as int,
        isSubscribed:        json['is_subscribed'] as bool,
        frequencyWeeks:      json['frequency_weeks'] as int,
        variantId:           json['variant_id'] as String?,
        overridePriceCents:  json['override_price_cents'] as int?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CartState — full in-memory cart
// ─────────────────────────────────────────────────────────────────────────────

class CartState {
  const CartState({required this.items});

  final List<CartItem> items;

  static const empty = CartState(items: []);

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (s, e) => s + e.quantity);

  /// Grand total in cents (after any subscription discounts).
  int get totalCents => items.fold(0, (s, e) => s + e.lineTotalCents);

  /// Total savings from subscribe-and-save across all subscribed lines.
  int get savingsCents => items.fold(0, (s, e) => s + e.savingsCentsTotal);

  String get totalFormatted => formatCents(totalCents);

  /// True if any line is a subscription.
  bool get hasSubscription => items.any((i) => i.isSubscribed && i.product.subscribable);

  List<Map<String, dynamic>> toLineItemsJson() =>
      items.map((i) => i.toJson()).toList();

  /// Items grouped by shopId. Preserves insertion order of first item per shop.
  Map<String, List<CartItem>> get itemsByShop {
    final result = <String, List<CartItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.product.shopId, () => []).add(item);
    }
    return result;
  }

  /// Total in cents for a single vendor's items.
  int totalCentsForShop(String shopId) => items
      .where((i) => i.product.shopId == shopId)
      .fold(0, (s, e) => s + e.lineTotalCents);

  /// Line-items JSON snapshot for a single vendor's items.
  List<Map<String, dynamic>> lineItemsJsonForShop(String shopId) => items
      .where((i) => i.product.shopId == shopId)
      .map((i) => i.toJson())
      .toList();

  /// Stripped payload for the process_checkout RPC (no client price fields).
  List<Map<String, dynamic>> rpcLineItemsJsonForShop(String shopId) => items
      .where((i) => i.product.shopId == shopId)
      .map((i) => i.rpcJson())
      .toList();

  Map<String, dynamic> toStorageJson() => {
        'items': items.map((i) => i.toStorageJson()).toList(),
      };

  factory CartState.fromStorageJson(Map<String, dynamic> json) => CartState(
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromStorageJson(e as Map<String, dynamic>))
            .toList(),
      );
}
