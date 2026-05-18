// ignore_for_file: use_null_aware_elements
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop.dart';

final kycRepositoryProvider = Provider<KycRepository>(
  (_) => KycRepository(Supabase.instance.client),
);

class KycRepository {
  const KycRepository(this._client);

  final SupabaseClient _client;

  Future<Shop> submitKyc({
    required String shopId,
    required Map<String, String> bankDetails,
    Uint8List? nidBytes,
    Uint8List? tradeLicenseBytes,
  }) async {
    String? nidPath;
    String? tradeLicensePath;

    if (nidBytes != null) {
      nidPath = await _uploadKycDoc(nidBytes, shopId, 'nid');
    }
    if (tradeLicenseBytes != null) {
      tradeLicensePath = await _uploadKycDoc(tradeLicenseBytes, shopId, 'trade_license');
    }

    final row = await _client
        .from('shops')
        .update({
          'kyc_status':           'submitted',
          'bank_account_details': bankDetails,
          if (nidPath != null)          'national_id_url':   nidPath,
          if (tradeLicensePath != null) 'trade_license_url': tradeLicensePath,
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
    return path;
  }
}
