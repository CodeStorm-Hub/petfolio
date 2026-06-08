// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

final vendorProductRepositoryProvider = Provider<VendorProductRepository>(
  (_) => VendorProductRepository(Supabase.instance.client),
);

class VendorProductRepository {
  const VendorProductRepository(this._client);

  final SupabaseClient _client;

  /// All products for a given shop (active and inactive) — used by vendor dashboard.
  Future<List<Product>> fetchProductsByShop(String shopId) async {
    final rows = await _client
        .from('products')
        .select('*, shops!inner(shop_name)')
        .eq('shop_id', shopId)
        .order('created_at')
        .limit(200);
    return (rows as List)
        .map((r) => Product.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String brand,
    required String variant,
    required String category,
    required int priceCents,
    String currency = 'usd',
    bool subscribable = false,
    int? subPriceCents,
    String glyph = 'unknown',
    String gradientStart = '#F4B57A',
    String gradientEnd = '#C46A4F',
    List<String> imageUrls = const [],
    int inventoryCount = 0,
  }) async {
    final row = await _client
        .from('products')
        .insert({
          'shop_id':         shopId,
          'name':            name,
          'brand':           brand,
          'variant':         variant,
          'category':        category,
          'price_cents':     priceCents,
          'currency':        currency,
          'subscribable':    subscribable,
          if (subPriceCents != null) 'sub_price_cents': subPriceCents,
          'glyph':           glyph,
          'gradient_start':  gradientStart,
          'gradient_end':    gradientEnd,
          'image_urls':      imageUrls,
          'inventory_count': inventoryCount,
          'active':          true,
        })
        .select('*, shops!inner(shop_name)')
        .single();
    return Product.fromJson(row);
  }

  Future<Product> updateProduct({
    required String id,
    String? name,
    String? brand,
    String? variant,
    String? category,
    int? priceCents,
    bool? subscribable,
    int? subPriceCents,
    bool clearSubPrice = false,
    List<String>? imageUrls,
    int? inventoryCount,
    bool? active,
  }) async {
    final row = await _client
        .from('products')
        .update({
          if (name           != null) 'name':            name,
          if (brand          != null) 'brand':           brand,
          if (variant        != null) 'variant':         variant,
          if (category       != null) 'category':        category,
          if (priceCents     != null) 'price_cents':     priceCents,
          if (subscribable   != null) 'subscribable':    subscribable,
          if (clearSubPrice)          'sub_price_cents': null,
          if (!clearSubPrice && subPriceCents != null) 'sub_price_cents': subPriceCents,
          if (imageUrls      != null) 'image_urls':      imageUrls,
          if (inventoryCount != null) 'inventory_count': inventoryCount,
          if (active         != null) 'active':          active,
        })
        .eq('id', id)
        .select('*, shops!inner(shop_name)')
        .single();
    return Product.fromJson(row);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
