import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

/// Derived provider: products filtered by category (client-side).
final filteredProductsProvider =
    Provider.family<List<Product>, ProductCategory>((ref, cat) {
  final all = ref.watch(productListProvider).valueOrNull ?? [];
  if (cat == ProductCategory.all) return all;
  return all.where((p) => p.category == cat).toList();
});

/// Subscribable products only.
final subscribableProductsProvider = Provider<List<Product>>((ref) {
  final all = ref.watch(productListProvider).valueOrNull ?? [];
  return all.where((p) => p.subscribable).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    try {
      return await ref.read(productRepositoryProvider).fetchProducts();
    } catch (_) {
      // Fall back to bundled demo catalog so the UI always shows products.
      return _demoCatalog;
    }
  }

  // ── Demo catalog (mirrors the Supabase seed) ──────────────────────────────

  static const _demoCatalog = [
    Product(
      id: 'aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa',
      name: 'Wild Salmon & Sweet Potato Kibble',
      brand: 'Wholepack',
      variant: '12 kg bag',
      category: ProductCategory.food,
      priceCents: 4800,
      currency: 'usd',
      subscribable: true,
      glyphType: ProductGlyphType.bag,
      gradientStart: Color(0xFFF4B57A),
      gradientEnd: Color(0xFFC46A4F),
    ),
    Product(
      id: 'aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa',
      name: 'Tug-of-War Rope Twist',
      brand: 'Pawhaus',
      variant: 'Medium',
      category: ProductCategory.toys,
      priceCents: 1450,
      currency: 'usd',
      subscribable: false,
      glyphType: ProductGlyphType.rope,
      gradientStart: Color(0xFF9BB59A),
      gradientEnd: Color(0xFF485F4F),
    ),
    Product(
      id: 'aaaaaaaa-0003-0003-0003-aaaaaaaaaaaa',
      name: 'Reflective Trail Harness',
      brand: 'Highline',
      variant: 'M · Slate',
      category: ProductCategory.gear,
      priceCents: 3800,
      currency: 'usd',
      subscribable: false,
      glyphType: ProductGlyphType.leash,
      gradientStart: Color(0xFF4B7DFA),
      gradientEnd: Color(0xFF173FA3),
    ),
    Product(
      id: 'aaaaaaaa-0004-0004-0004-aaaaaaaaaaaa',
      name: 'Single-Source Beef Liver Treats',
      brand: 'Wholepack',
      variant: '200 g jar',
      category: ProductCategory.treats,
      priceCents: 920,
      currency: 'usd',
      subscribable: true,
      glyphType: ProductGlyphType.bone,
      gradientStart: Color(0xFFE76F51),
      gradientEnd: Color(0xFFB14530),
    ),
    Product(
      id: 'aaaaaaaa-0005-0005-0005-aaaaaaaaaaaa',
      name: 'Joint Support Chews · Glucosamine',
      brand: 'Vitavet',
      variant: '60 chews',
      category: ProductCategory.health,
      priceCents: 2400,
      currency: 'usd',
      subscribable: true,
      glyphType: ProductGlyphType.pill,
      gradientStart: Color(0xFF9B5C8A),
      gradientEnd: Color(0xFF5E3354),
    ),
    Product(
      id: 'aaaaaaaa-0006-0006-0006-aaaaaaaaaaaa',
      name: 'Slicker Brush · Self-Cleaning',
      brand: 'Pawhaus',
      variant: 'Long-haired',
      category: ProductCategory.grooming,
      priceCents: 1950,
      currency: 'usd',
      subscribable: false,
      glyphType: ProductGlyphType.brush,
      gradientStart: Color(0xFFF5C49B),
      gradientEnd: Color(0xFFC49370),
    ),
    Product(
      id: 'aaaaaaaa-0007-0007-0007-aaaaaaaaaaaa',
      name: 'Pumpkin Digestive Wet Food',
      brand: 'Wholepack',
      variant: '12 × 400g',
      category: ProductCategory.food,
      priceCents: 3200,
      currency: 'usd',
      subscribable: true,
      glyphType: ProductGlyphType.bowl,
      gradientStart: Color(0xFFF4A261),
      gradientEnd: Color(0xFFB86E2C),
    ),
    Product(
      id: 'aaaaaaaa-0008-0008-0008-aaaaaaaaaaaa',
      name: 'Bouncing Squeaker Ball',
      brand: 'Pawhaus',
      variant: 'Two-pack',
      category: ProductCategory.toys,
      priceCents: 800,
      currency: 'usd',
      subscribable: false,
      glyphType: ProductGlyphType.ball,
      gradientStart: Color(0xFF6BAF92),
      gradientEnd: Color(0xFF2F6A4D),
    ),
  ];
}
