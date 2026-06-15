import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/wishlist_item.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (_) => WishlistRepository(Supabase.instance.client),
);

class WishlistProduct {
  const WishlistProduct({required this.item, required this.product});
  final WishlistItem item;
  final Product product;
}

class WishlistRepository {
  const WishlistRepository(this._client);

  final SupabaseClient _client;

  Future<String> _getOrCreateWishlistId() async {
    final result = await _client.rpc('get_or_create_wishlist');
    return result as String;
  }

  Future<List<WishlistProduct>> fetchWishlistProducts() async {
    if (_client.auth.currentUser == null) return [];
    final wishlistId = await _getOrCreateWishlistId();
    final rows = await _client
        .from('wishlist_items')
        .select('*, products!inner(*, shops!inner(shop_name))')
        .eq('wishlist_id', wishlistId)
        .order('added_at', ascending: false);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return WishlistProduct(
        item: WishlistItem.fromJson(map),
        product: Product.fromJson(map['products'] as Map<String, dynamic>),
      );
    }).toList();
  }

  Future<bool> isInWishlist(String productId, {String? variantId}) async {
    if (_client.auth.currentUser == null) return false;
    final wishlistId = await _getOrCreateWishlistId();
    var query = _client
        .from('wishlist_items')
        .select()
        .eq('wishlist_id', wishlistId)
        .eq('product_id', productId);
    if (variantId != null) {
      query = query.eq('variant_id', variantId);
    } else {
      query = query.isFilter('variant_id', null);
    }
    final result = await query.maybeSingle();
    return result != null;
  }

  Future<void> addToWishlist(String productId, {String? variantId}) async {
    final wishlistId = await _getOrCreateWishlistId();
    final payload = <String, dynamic>{
      'wishlist_id': wishlistId,
      'product_id': productId,
    };
    if (variantId != null) payload['variant_id'] = variantId;
    await _client.from('wishlist_items').insert(payload);
  }

  Future<void> removeFromWishlist(String productId, {String? variantId}) async {
    final wishlistId = await _getOrCreateWishlistId();
    var query = _client
        .from('wishlist_items')
        .delete()
        .eq('wishlist_id', wishlistId)
        .eq('product_id', productId);
    if (variantId != null) {
      query = query.eq('variant_id', variantId);
    } else {
      query = query.isFilter('variant_id', null);
    }
    await query;
  }
}
