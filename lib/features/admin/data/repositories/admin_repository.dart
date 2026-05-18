import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../marketplace/data/models/marketplace_order.dart';
import '../../../marketplace/data/models/shop.dart';
import '../../../marketplace/data/models/vendor_ledger.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepository(Supabase.instance.client),
);

class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  // ── KYC ───────────────────────────────────────────────────────────────────

  Future<List<Shop>> fetchSubmittedKycShops() async {
    final rows = await _client
        .from('shops')
        .select()
        .eq('kyc_status', 'submitted')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((r) => Shop.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveKyc(String shopId) async {
    await _client.from('shops').update({
      'kyc_status': 'approved',
      'is_verified': true,
      'rejection_reason': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shopId);
  }

  Future<void> rejectKyc(String shopId, String reason) async {
    await _client.from('shops').update({
      'kyc_status': 'rejected',
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shopId);
  }

  // ── KYC document signed URLs ──────────────────────────────────────────────

  Future<String> getSignedDocUrl(String path) =>
      _client.storage.from('kyc-documents').createSignedUrl(path, 60);

  Future<String> getSecureDocumentUrl(String storagePath) {
    final path = _resolveStoragePath(storagePath);
    return _client.storage.from('kyc-documents').createSignedUrl(path, 60);
  }

  static String _resolveStoragePath(String value) {
    if (!value.startsWith('http')) return value;
    final uri = Uri.parse(value);
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('kyc-documents');
    if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
      return segments.sublist(bucketIndex + 1).join('/');
    }
    return value;
  }

  // ── COD reconciliation ────────────────────────────────────────────────────

  Future<List<MarketplaceOrder>> fetchDeliveredCodOrders() async {
    final rows = await _client
        .from('marketplace_orders')
        .select()
        .eq('payment_method', 'cod')
        .eq('status', 'delivered')
        .eq('payment_status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceOrder.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markCashReceived(String orderId) async {
    await _client
        .from('marketplace_orders')
        .update({'payment_status': 'collected'}).eq('id', orderId);
    await _client
        .from('vendor_ledgers')
        .update({'status': LedgerStatus.available.name}).eq('order_id', orderId).eq(
          'status',
          LedgerStatus.pendingClearance.name,
        );
  }

  // ── Payouts ───────────────────────────────────────────────────────────────

  Future<List<VendorLedger>> fetchAvailableLedgers() async {
    final rows = await _client
        .from('vendor_ledgers')
        .select()
        .eq('status', LedgerStatus.available.name)
        .order('created_at');
    return (rows as List)
        .map((r) => VendorLedger.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Shop>> fetchShopsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _client.from('shops').select().inFilter('id', ids);
    return (rows as List)
        .map((r) => Shop.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markShopPaid(String shopId) async {
    await _client
        .from('vendor_ledgers')
        .update({'status': LedgerStatus.paid.name})
        .eq('shop_id', shopId)
        .eq('status', LedgerStatus.available.name);
  }

  // ── Overview ──────────────────────────────────────────────────────────────

  Future<AdminOverviewMetrics> fetchOverviewMetrics() async {
    final results = await Future.wait([
      _client
          .from('shops')
          .select('id')
          .eq('kyc_status', KycStatus.submitted.name),
      _client
          .from('marketplace_orders')
          .select('id')
          .eq('payment_method', PaymentMethod.cod.name)
          .eq('status', OrderStatus.delivered.name)
          .eq('payment_status', PaymentStatus.pending.name),
      _client
          .from('vendor_ledgers')
          .select('shop_id')
          .eq('status', LedgerStatus.available.name),
    ]);

    final pendingKyc = (results[0] as List).length;
    final codPending = (results[1] as List).length;
    final availableShops =
        (results[2] as List).map((r) => r['shop_id']).toSet().length;

    return AdminOverviewMetrics(
      pendingKycCount: pendingKyc,
      pendingCodCount: codPending,
      vendorsWithBalanceCount: availableShops,
    );
  }
}

class AdminOverviewMetrics {
  const AdminOverviewMetrics({
    required this.pendingKycCount,
    required this.pendingCodCount,
    required this.vendorsWithBalanceCount,
  });

  final int pendingKycCount;
  final int pendingCodCount;
  final int vendorsWithBalanceCount;
}

class NotAdminException implements Exception {
  @override
  String toString() => 'Admin access required.';
}
