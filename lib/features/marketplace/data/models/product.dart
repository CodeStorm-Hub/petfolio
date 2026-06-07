import 'package:flutter/painting.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Product category
// ─────────────────────────────────────────────────────────────────────────────

enum ProductCategory {
  all,
  food,
  gear,
  toys,
  treats,
  health,
  grooming,
  beds,
  apparel;

  String get label => switch (this) {
        ProductCategory.all      => 'All',
        ProductCategory.food     => 'Food',
        ProductCategory.gear     => 'Gear',
        ProductCategory.toys     => 'Toys',
        ProductCategory.treats   => 'Treats',
        ProductCategory.health   => 'Health',
        ProductCategory.grooming => 'Grooming',
        ProductCategory.beds     => 'Beds',
        ProductCategory.apparel  => 'Apparel',
      };

  static ProductCategory fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => ProductCategory.all,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Product glyph — used by ProductGlyph widget to pick the right SVG path.
// ─────────────────────────────────────────────────────────────────────────────

enum ProductGlyphType { bag, ball, leash, bone, pill, brush, bowl, rope, unknown }

// ─────────────────────────────────────────────────────────────────────────────
// Product model
// ─────────────────────────────────────────────────────────────────────────────

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.variant,
    required this.category,
    required this.priceCents,
    required this.currency,
    required this.subscribable,
    required this.glyphType,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shopId,
    required this.shopName,
    required this.imageUrls,
    required this.inventoryCount,
    this.subPriceCentsDb,
    this.rating,
  });

  final String          id;
  final String          name;
  final String          brand;
  final String          variant;
  final ProductCategory category;

  /// Price in smallest currency unit (e.g. cents for USD).
  final int    priceCents;
  final String currency;

  final bool             subscribable;
  final ProductGlyphType glyphType;

  final Color gradientStart;
  final Color gradientEnd;

  final String       shopId;
  final String       shopName;
  final List<String> imageUrls;
  final int          inventoryCount;

  /// Vendor-set subscription price. Null = fall back to the computed 12%-off value.
  final int? subPriceCentsDb;

  /// Average star rating (0.0 – 5.0). Null = not yet rated.
  final double? rating;

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Human-readable price, e.g. "$48.00".
  String get priceFormatted => '\$${(priceCents / 100).toStringAsFixed(2)}';

  /// Subscribe-and-save price in cents. Uses vendor-set value when available,
  /// otherwise defaults to 12% off the regular price.
  int get subPriceCents => subPriceCentsDb ?? (priceCents * 0.88).round();

  String get subPriceFormatted => '\$${(subPriceCents / 100).toStringAsFixed(2)}';

  int savingsCents(bool subscribed) => subscribed ? priceCents - subPriceCents : 0;

  // ── JSON factory ───────────────────────────────────────────────────────────

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id:               json['id'] as String,
        name:             json['name'] as String,
        brand:            json['brand'] as String,
        variant:          (json['variant'] as String?) ?? '',
        category:         ProductCategory.fromString((json['category'] as String?) ?? 'food'),
        priceCents:       json['price_cents'] as int,
        currency:         (json['currency'] as String?) ?? 'usd',
        subscribable:     (json['subscribable'] as bool?) ?? false,
        glyphType:        _parseGlyph((json['glyph'] as String?) ?? ''),
        gradientStart:    _hexColor((json['gradient_start'] as String?) ?? '#F4B57A'),
        gradientEnd:      _hexColor((json['gradient_end']   as String?) ?? '#C46A4F'),
        shopId:           (json['shop_id'] as String?) ?? '',
        shopName:         (json['shops'] as Map<String, dynamic>?)?['shop_name'] as String? ?? '',
        imageUrls:        (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        inventoryCount:   (json['inventory_count'] as int?) ?? 0,
        subPriceCentsDb:  json['sub_price_cents'] as int?,
        rating:           (json['rating'] as num?)?.toDouble(),
      );

  static ProductGlyphType _parseGlyph(String s) => switch (s) {
        'bag'   => ProductGlyphType.bag,
        'ball'  => ProductGlyphType.ball,
        'leash' => ProductGlyphType.leash,
        'bone'  => ProductGlyphType.bone,
        'pill'  => ProductGlyphType.pill,
        'brush' => ProductGlyphType.brush,
        'bowl'  => ProductGlyphType.bowl,
        'rope'  => ProductGlyphType.rope,
        _       => ProductGlyphType.unknown,
      };

  Map<String, dynamic> toStorageJson() => {
        'id':               id,
        'name':             name,
        'brand':            brand,
        'variant':          variant,
        'category':         category.name,
        'price_cents':      priceCents,
        'currency':         currency,
        'subscribable':     subscribable,
        'glyph':            _glyphToString(glyphType),
        'gradient_start':   _colorToHex(gradientStart),
        'gradient_end':     _colorToHex(gradientEnd),
        'shop_id':          shopId,
        'shop_name':        shopName,
        'image_urls':       imageUrls,
        'inventory_count':  inventoryCount,
        if (subPriceCentsDb != null) 'sub_price_cents': subPriceCentsDb,
        if (rating != null) 'rating': rating,
      };

  factory Product.fromStorageJson(Map<String, dynamic> json) => Product(
        id:              json['id'] as String,
        name:            json['name'] as String,
        brand:           json['brand'] as String,
        variant:         (json['variant'] as String?) ?? '',
        category:        ProductCategory.fromString((json['category'] as String?) ?? 'food'),
        priceCents:      json['price_cents'] as int,
        currency:        (json['currency'] as String?) ?? 'usd',
        subscribable:    (json['subscribable'] as bool?) ?? false,
        glyphType:       _parseGlyph((json['glyph'] as String?) ?? ''),
        gradientStart:   _hexColor((json['gradient_start'] as String?) ?? '#F4B57A'),
        gradientEnd:     _hexColor((json['gradient_end']   as String?) ?? '#C46A4F'),
        shopId:          (json['shop_id'] as String?) ?? '',
        shopName:        (json['shop_name'] as String?) ?? '',
        imageUrls:       (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        inventoryCount:  (json['inventory_count'] as int?) ?? 0,
        subPriceCentsDb: json['sub_price_cents'] as int?,
        rating:          (json['rating'] as num?)?.toDouble(),
      );

  static Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static String _colorToHex(Color c) =>
      '#${(c.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _glyphToString(ProductGlyphType g) => switch (g) {
        ProductGlyphType.bag     => 'bag',
        ProductGlyphType.ball    => 'ball',
        ProductGlyphType.leash   => 'leash',
        ProductGlyphType.bone    => 'bone',
        ProductGlyphType.pill    => 'pill',
        ProductGlyphType.brush   => 'brush',
        ProductGlyphType.bowl    => 'bowl',
        ProductGlyphType.rope    => 'rope',
        ProductGlyphType.unknown => '',
      };
}
