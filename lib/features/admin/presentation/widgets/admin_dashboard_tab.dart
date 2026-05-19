import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../controllers/admin_dashboard_controller.dart';
import 'admin_shared_widgets.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);

    return AdminPanelScaffold(
      title: 'Dashboard',
      onRefresh: () => ref.read(adminDashboardProvider.notifier).refresh(),
      child: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (data) => _DashboardBody(data: data),
      ),
    );
  }
}

// ── Main content ───────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricsBanner(data: data),
          const SizedBox(height: 28),
          _RecentActivitySection(items: data.recentActivity),
        ],
      ),
    );
  }
}

// ── Metrics banner ─────────────────────────────────────────────────────────────

class _MetricsBanner extends StatelessWidget {
  const _MetricsBanner({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // ink950 → blue600 — both from AppColors
          colors: [AppColors.ink950, AppColors.blue600],
        ),
        boxShadow: pt.shadowE2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Overview',
            style: tt.headlineSmall!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live metrics across all vendors',
            style: tt.labelLarge!.copyWith(
              color: Colors.white.withAlpha(160),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              final cards = [
                _MetricGlassCard(
                  icon: Icons.storefront_rounded,
                  label: 'Active Shops',
                  value: data.activeShopCount.toString(),
                  iconColor: AppColors.blue300,
                ),
                _MetricGlassCard(
                  icon: Icons.assignment_outlined,
                  label: 'Pending KYC',
                  value: data.pendingKycCount.toString(),
                  iconColor: AppColors.warningD,
                ),
                _MetricGlassCard(
                  icon: Icons.attach_money_rounded,
                  label: 'Platform Revenue',
                  value: data.revenueFormatted,
                  iconColor: AppColors.successD,
                ),
              ];
              if (isNarrow) {
                return Column(
                  children: cards
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c,
                          ))
                      .toList(),
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricGlassCard extends StatelessWidget {
  const _MetricGlassCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withAlpha(35),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: tt.headlineMedium!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: tt.labelSmall!.copyWith(
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity section ────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.items});

  final List<RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: tt.headlineSmall!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusPill),
                  color: AppColors.blue500.withAlpha(15),
                ),
                child: Text(
                  '${items.length}',
                  style: tt.labelSmall!.copyWith(color: AppColors.blue500),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const AdminEmptyState(
            icon: Icons.history_rounded,
            message: 'No recent activity yet',
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(PetfolioThemeExtension.radiusLg),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: pt.shadowE1,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 64,
                color: AppColors.line200,
              ),
              itemBuilder: (context, i) => _ActivityTile(item: items[i]),
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    final (icon, color) = switch (item.type) {
      ActivityType.shopJoined => (
          Icons.storefront_outlined,
          AppColors.blue500,
        ),
      ActivityType.orderDelivered => (
          Icons.check_circle_outline_rounded,
          pt.success,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(18),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: tt.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: tt.labelMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo(item.timestamp), style: tt.labelSmall),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
