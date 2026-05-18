import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/ledger_controller.dart';
import 'admin_shared_widgets.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(overviewMetricsProvider);

    return AdminPanelScaffold(
      title: 'Overview',
      onRefresh: () => ref.invalidate(overviewMetricsProvider),
      child: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (m) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              label: 'Pending KYC',
              count: m.pendingKycCount,
              icon: Icons.verified_user_outlined,
              color: AppColors.warning,
            ),
            _MetricCard(
              label: 'COD to Collect',
              count: m.pendingCodCount,
              icon: Icons.payments_outlined,
              color: AppColors.blue500,
            ),
            _MetricCard(
              label: 'Payouts Ready',
              count: m.vendorsWithBalanceCount,
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF22C55E),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface0,
        boxShadow: const [BoxShadow(color: AppColors.line200, spreadRadius: 0.5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withAlpha(20),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            count.toString(),
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.ink950,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink500)),
        ],
      ),
    );
  }
}
