// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop.dart';

final shopRepositoryProvider = Provider<ShopRepository>(
  (_) => ShopRepository(Supabase.instance.client),
);

class ShopRepository {
  const ShopRepository(this._client);

  final SupabaseClient _client;

  Future<Shop> fetchShopById(String id) async {
    final row = await _client
        .from('shops')
        .select()
        .eq('id', id)
        .single();
    return Shop.fromJson(row);
  }

  Future<List<Shop>> fetchAllActiveShops() async {
    final rows = await _client
        .from('shops')
        .select()
        .eq('is_active', true)
        .eq('is_verified', true)
        .order('shop_name');
    return (rows as List)
        .map((r) => Shop.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns the shop owned by the currently authenticated user, or null.
  Future<Shop?> fetchMyShop() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('shops')
        .select()
        .eq('owner_id', userId)
        .limit(1);

    if (rows.isEmpty) return null;
    return Shop.fromJson(rows.first);
  }

  Future<Shop> createShop({
    required String name,
    required String slug,
    String? description,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('shops')
        .insert({
          'owner_id':  userId,
          'shop_name': name,
          'slug':      slug,
          if (description != null) 'description': description,
        })
        .select()
        .single();
    return Shop.fromJson(row);
  }

  Future<Shop> updateShop({
    required String id,
    String? shopName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    final row = await _client
        .from('shops')
        .update({
          if (shopName    != null) 'shop_name':   shopName,
          if (description != null) 'description': description,
          if (logoUrl     != null) 'logo_url':    logoUrl,
          if (bannerUrl   != null) 'banner_url':  bannerUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Shop.fromJson(row);
  }

  /// Calls the stripe-onboard-vendor Edge Function.
  /// Returns the Stripe account-link URL to open in the user's browser.
  Future<String> startOnboarding(String shopId) async {
    final response = await _client.functions.invoke(
      'stripe-onboard-vendor',
      body: {'shopId': shopId},
    );

    if (response.status != 200) {
      throw Exception(
        'stripe-onboard-vendor error ${response.status}: ${response.data}',
      );
    }

    final url =
        (response.data as Map<String, dynamic>)['accountLinkUrl'] as String?;
    if (url == null) throw Exception('Missing accountLinkUrl in response');
    return url;
  }
}
