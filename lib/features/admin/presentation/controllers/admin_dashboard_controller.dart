import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository.dart';

// ── Activity model ─────────────────────────────────────────────────────────────

enum ActivityType { shopJoined, orderDelivered }

class RecentActivityItem {
  const RecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
}

// ── Dashboard data model ───────────────────────────────────────────────────────

class AdminDashboardData {
  const AdminDashboardData({
    required this.activeShopCount,
    required this.pendingKycCount,
    required this.platformRevenueCents,
    required this.recentActivity,
  });

  final int activeShopCount;
  final int pendingKycCount;
  final int platformRevenueCents;
  final List<RecentActivityItem> recentActivity;

  String get revenueFormatted =>
      '\$${(platformRevenueCents / 100).toStringAsFixed(2)}';
}

// ── Provider ───────────────────────────────────────────────────────────────────

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardData>(
  AdminDashboardNotifier.new,
);

// ── Notifier ───────────────────────────────────────────────────────────────────

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardData> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<AdminDashboardData> build() => _fetch();

  Future<AdminDashboardData> _fetch() async {
    final results = await Future.wait([
      _repo.fetchActiveShopCount(),
      _repo.fetchOverviewMetrics(),
      _repo.fetchPlatformRevenueCents(),
      _repo.fetchRecentShops(limit: 5),
      _repo.fetchRecentOrders(limit: 5),
    ]);

    final metrics = results[1] as AdminOverviewMetrics;
    final shopRows =
        (results[3] as List).cast<Map<String, dynamic>>();
    final orderRows =
        (results[4] as List).cast<Map<String, dynamic>>();

    final activity = _buildActivity(shopRows, orderRows);

    return AdminDashboardData(
      activeShopCount: results[0] as int,
      pendingKycCount: metrics.pendingKycCount,
      platformRevenueCents: results[2] as int,
      recentActivity: activity,
    );
  }

  List<RecentActivityItem> _buildActivity(
    List<Map<String, dynamic>> shopRows,
    List<Map<String, dynamic>> orderRows,
  ) {
    final items = <RecentActivityItem>[];

    for (final row in shopRows) {
      items.add(RecentActivityItem(
        type: ActivityType.shopJoined,
        title: row['shop_name'] as String? ?? 'Unknown shop',
        subtitle: 'Vendor registered',
        timestamp: DateTime.parse(row['created_at'] as String),
      ));
    }

    for (final row in orderRows) {
      final id = row['id'] as String;
      items.add(RecentActivityItem(
        type: ActivityType.orderDelivered,
        title: 'Order #${id.substring(0, 8).toUpperCase()}',
        subtitle: 'Marked as delivered',
        timestamp: DateTime.parse(row['created_at'] as String),
      ));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(5).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
