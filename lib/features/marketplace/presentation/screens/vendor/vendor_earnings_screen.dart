import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/vendor_ledger.dart';
import '../../controllers/my_shop_controller.dart';

final _vendorLedgerProvider = FutureProvider.autoDispose<List<VendorLedger>>((ref) async {
  final shop = ref.watch(myShopProvider).value;
  if (shop == null) return [];
  final client = Supabase.instance.client;
  final data = await client
      .from('vendor_ledgers')
      .select()
      .eq('shop_id', shop.id)
      .order('created_at', ascending: false);
  return (data as List).map((e) => VendorLedger.fromJson(e)).toList();
});

class VendorEarningsScreen extends ConsumerWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ledgerAsync = ref.watch(_vendorLedgerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Back',
                      button: true,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface0,
                            boxShadow: [BoxShadow(color: AppColors.line, spreadRadius: 0.5)],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: pt.ink700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Earnings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: pt.ink950),
                    ),
                  ],
                ),
              ),
            ),
            ledgerAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: pt.ink300),
                      const SizedBox(height: 12),
                      Text('Failed to load earnings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: pt.ink500)),
                      const SizedBox(height: 4),
                      Text(e.toString(), style: TextStyle(fontSize: 12, color: pt.ink300), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(_vendorLedgerProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 48, color: pt.ink300),
                          const SizedBox(height: 12),
                          Text('No earnings yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: pt.ink500)),
                          const SizedBox(height: 4),
                          Text('Earnings appear here once orders are completed', style: TextStyle(fontSize: 13, color: pt.ink300)),
                        ],
                      ),
                    ),
                  );
                }

                final totalEarnings = entries.fold<int>(0, (s, e) => s + e.vendorEarningsCents);
                final paidOut = entries.where((e) => e.status == LedgerStatus.paid).fold<int>(0, (s, e) => s + e.vendorEarningsCents);
                final available = entries.where((e) => e.status == LedgerStatus.available).fold<int>(0, (s, e) => s + e.vendorEarningsCents);
                final pending = paidOut == 0 ? totalEarnings : available;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Total earned', value: '\$${(totalEarnings / 100).toStringAsFixed(2)}', color: AppColors.mint)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(label: 'Pending payout', value: '\$${(pending / 100).toStringAsFixed(2)}', color: AppColors.tangerine)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Transaction history', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pt.ink500)),
                    ),
                    for (final entry in entries)
                      _LedgerRow(entry: entry, pt: pt),
                    const SizedBox(height: 24),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.pt});
  final VendorLedger entry;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.status == LedgerStatus.paid || entry.status == LedgerStatus.available;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface0,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.line, spreadRadius: 0.5)],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaid ? AppColors.mint.withAlpha(25) : AppColors.tangerine.withAlpha(25),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
              size: 18,
              color: isPaid ? AppColors.mint700 : AppColors.tangerine,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${entry.orderId.substring(0, 8)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pt.ink950)),
                const SizedBox(height: 2),
                Text(
                  isPaid ? 'Paid out' : _statusLabel(entry.status),
                  style: TextStyle(fontSize: 12, color: isPaid ? AppColors.mint700 : AppColors.tangerine),
                ),
              ],
            ),
          ),
          Text(
            '\$${(entry.vendorEarningsCents / 100).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: pt.ink950),
          ),
        ],
      ),
    );
  }

  String _statusLabel(LedgerStatus s) => switch (s) {
    LedgerStatus.pendingClearance => 'Clearing',
    LedgerStatus.available => 'Available',
    LedgerStatus.paid => 'Paid out',
  };
}
