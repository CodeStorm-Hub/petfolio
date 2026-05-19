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
    PayoutMethod payoutMethod = PayoutMethod.stripe,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('shops')
        .insert({
          'owner_id':     userId,
          'shop_name':    name,
          'slug':         slug,
          'payout_method': payoutMethod.name,
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
    String? businessEmail,
    String? businessPhone,
    String? addressStreet,
    String? addressCity,
    String? addressState,
    String? addressZip,
    String? returnPolicy,
    String? shippingPolicy,
    Map<String, dynamic>? socialLinks,
  }) async {
    final row = await _client
        .from('shops')
        .update({
          if (shopName       != null) 'shop_name':        shopName,
          if (description    != null) 'description':      description,
          if (logoUrl        != null) 'logo_url':         logoUrl,
          if (bannerUrl      != null) 'banner_url':       bannerUrl,
          if (businessEmail  != null) 'business_email':   businessEmail,
          if (businessPhone  != null) 'business_phone':   businessPhone,
          if (addressStreet  != null) 'address_street':   addressStreet,
          if (addressCity    != null) 'address_city':     addressCity,
          if (addressState   != null) 'address_state':    addressState,
          if (addressZip     != null) 'address_zip':      addressZip,
          if (returnPolicy   != null) 'return_policy':    returnPolicy,
          if (shippingPolicy != null) 'shipping_policy':  shippingPolicy,
          if (socialLinks    != null) 'social_links':     socialLinks,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Shop.fromJson(row);
  }

  Future<Shop> saveShopProfile(Shop shop) async {
    final row = await _client
        .from('shops')
        .update({
          'shop_name':       shop.shopName,
          'description':     shop.description,
          'logo_url':        shop.logoUrl,
          'banner_url':      shop.bannerUrl,
          'business_email':  shop.businessEmail,
          'business_phone':  shop.businessPhone,
          'address_street':  shop.addressStreet,
          'address_city':    shop.addressCity,
          'address_state':   shop.addressState,
          'address_zip':     shop.addressZip,
          'return_policy':   shop.returnPolicy,
          'shipping_policy': shop.shippingPolicy,
          'social_links':    shop.socialLinks,
          'updated_at':      DateTime.now().toIso8601String(),
        })
        .eq('id', shop.id)
        .select()
        .single();
    return Shop.fromJson(row);
  }

  /// Calls the `stripe-onboard-vendor` Edge Function (not a Postgres RPC).
  /// Returns the Stripe account-link URL to open in the user's browser.
  Future<String> startOnboarding(String shopId) async {
    try {
      final response = await _client.functions.invoke(
        'stripe-onboard-vendor',
        body: {'shopId': shopId},
      );

      final data = _functionResponseMap(response.data);
      final status = response.status;

      if (status >= 400) {
        throw StripeOnboardingException(_errorMessageFromPayload(data, status));
      }

      final url = data['accountLinkUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw const StripeOnboardingException(
          'Stripe onboarding did not return a link. Please try again.',
        );
      }
      return url;
    } on FunctionException catch (e) {
      throw StripeOnboardingException(
        _errorMessageFromPayload(_functionResponseMap(e.details), e.status),
      );
    }
  }

  /// Alias used in architecture docs.
  Future<String> startStripeOnboarding(String shopId) =>
      startOnboarding(shopId);

  Map<String, dynamic> _functionResponseMap(Object? data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String _errorMessageFromPayload(Map<String, dynamic> data, int status) {
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) return error;
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return 'Stripe onboarding failed (HTTP $status). Please try again.';
  }
}

class StripeOnboardingException implements Exception {
  const StripeOnboardingException(this.message);

  final String message;

  @override
  String toString() => message;
}
