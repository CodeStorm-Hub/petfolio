// ignore_for_file: use_null_aware_elements
import 'dart:typed_data';

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

  Future<Shop> submitKyc({
    required String shopId,
    required Map<String, String> bankDetails,
    Uint8List? nidBytes,
    Uint8List? tradeLicenseBytes,
  }) async {
    String? nidUrl;
    String? tradeLicenseUrl;

    if (nidBytes != null) {
      nidUrl = await _uploadKycDoc(nidBytes, shopId, 'nid');
    }
    if (tradeLicenseBytes != null) {
      tradeLicenseUrl = await _uploadKycDoc(tradeLicenseBytes, shopId, 'trade_license');
    }

    final row = await _client
        .from('shops')
        .update({
          'kyc_status':           'submitted',
          'bank_account_details': bankDetails,
          if (nidUrl != null)          'national_id_url':    nidUrl,
          if (tradeLicenseUrl != null) 'trade_license_url':  tradeLicenseUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shopId)
        .select()
        .single();
    return Shop.fromJson(row);
  }

  Future<String> _uploadKycDoc(Uint8List bytes, String shopId, String docType) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$shopId/$docType.jpg';
    await _client.storage.from('kyc-documents').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return await _client.storage.from('kyc-documents').createSignedUrl(path, 31536000);
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
