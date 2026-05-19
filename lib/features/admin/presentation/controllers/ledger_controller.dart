import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../marketplace/data/models/shop.dart';
import '../../../marketplace/data/models/vendor_ledger.dart';
import '../../data/repositories/admin_repository.dart';

class VendorPayoutGroup {
  const VendorPayoutGroup({
    required this.shop,
    required this.ledgers,
  });

  final Shop shop;
  final List<VendorLedger> ledgers;

  int get totalAvailableCents =>
      ledgers.fold(0, (sum, l) => sum + l.vendorEarningsCents);

  String get totalFormatted =>
      '\$${(totalAvailableCents / 100).toStringAsFixed(2)}';
}

final ledgerProvider =
    AsyncNotifierProvider<LedgerNotifier, List<VendorPayoutGroup>>(
  LedgerNotifier.new,
);

class LedgerNotifier extends AsyncNotifier<List<VendorPayoutGroup>> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<List<VendorPayoutGroup>> build() => _fetchGroups();

  Future<List<VendorPayoutGroup>> _fetchGroups() async {
    final ledgers = await _repo.fetchAvailableLedgers();
    if (ledgers.isEmpty) return [];

    final shopIds = ledgers.map((l) => l.shopId).toSet().toList();
    final shops = await _repo.fetchShopsByIds(shopIds);
    final shopMap = {for (final s in shops) s.id: s};

    final grouped = <String, List<VendorLedger>>{};
    for (final l in ledgers) {
      grouped.putIfAbsent(l.shopId, () => []).add(l);
    }

    return grouped.entries
        .where((e) => shopMap.containsKey(e.key))
        .map((e) => VendorPayoutGroup(shop: shopMap[e.key]!, ledgers: e.value))
        .toList();
  }

  Future<void> markShopPaid(String shopId) async {
    await _repo.markShopPaid(shopId);
    state = AsyncData(
      state.requireValue.where((g) => g.shop.id != shopId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchGroups);
  }
}

final overviewMetricsProvider =
    FutureProvider<AdminOverviewMetrics>((ref) async {
  return ref.read(adminRepositoryProvider).fetchOverviewMetrics();
});
