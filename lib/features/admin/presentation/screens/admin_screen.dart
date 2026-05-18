import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/data/models/shop.dart';
import '../../data/repositories/admin_repository.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/cod_orders_controller.dart';
import '../controllers/kyc_review_controller.dart';
import '../controllers/ledger_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

enum _AdminSection { overview, kyc, cod, payouts }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  _AdminSection _section = _AdminSection.overview;

  static const _destinations = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Overview', section: _AdminSection.overview),
    (icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user_rounded, label: 'KYC', section: _AdminSection.kyc),
    (icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, label: 'COD', section: _AdminSection.cod),
    (icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Payouts', section: _AdminSection.payouts),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.ink300),
              const SizedBox(height: 16),
              const Text('Admin access required',
                  style: TextStyle(fontSize: 16, color: AppColors.ink700)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedIndex =
        _destinations.indexWhere((d) => d.section == _section);

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface0,
            leading: const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _AdminBadge(),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/home'),
                    tooltip: 'Back to app',
                  ),
                ),
              ),
            ),
            onDestinationSelected: (i) =>
                setState(() => _section = _destinations[i].section),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: switch (_section) {
              _AdminSection.overview => const _OverviewPanel(),
              _AdminSection.kyc => const _KycPanel(),
              _AdminSection.cod => const _CodPanel(),
              _AdminSection.payouts => const _PayoutsPanel(),
            },
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue500.withAlpha(20),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 20, color: AppColors.blue500),
          ),
          const SizedBox(height: 4),
          const Text('Admin', style: TextStyle(fontSize: 11, color: AppColors.blue500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview panel
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewPanel extends ConsumerWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(overviewMetricsProvider);

    return _PanelScaffold(
      title: 'Overview',
      onRefresh: () => ref.invalidate(overviewMetricsProvider),
      child: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
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

// ─────────────────────────────────────────────────────────────────────────────
// KYC panel
// ─────────────────────────────────────────────────────────────────────────────

class _KycPanel extends ConsumerWidget {
  const _KycPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycAsync = ref.watch(kycReviewProvider);

    return _PanelScaffold(
      title: 'KYC Approvals',
      onRefresh: () => ref.read(kycReviewProvider.notifier).refresh(),
      child: kycAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (shops) => shops.isEmpty
            ? const _EmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'No pending KYC submissions',
              )
            : ListView.separated(
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _KycCard(shop: shops[i]),
              ),
      ),
    );
  }
}

class _KycCard extends ConsumerStatefulWidget {
  const _KycCard({required this.shop});
  final Shop shop;

  @override
  ConsumerState<_KycCard> createState() => _KycCardState();
}

class _KycCardState extends ConsumerState<_KycCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    await ref.read(kycReviewProvider.notifier).approve(widget.shop.id);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog(context);
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    await ref
        .read(kycReviewProvider.notifier)
        .reject(widget.shop.id, reason.trim());
    if (mounted) setState(() => _busy = false);
  }

  Future<String?> _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe why the documents are rejected…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final bank = shop.bankAccountDetails;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface0,
        boxShadow: const [BoxShadow(color: AppColors.line200, spreadRadius: 0.5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_outlined, size: 18, color: AppColors.ink500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shop.shopName,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink950,
                  ),
                ),
              ),
              _StatusChip(label: 'Submitted', color: AppColors.warning),
            ],
          ),
          if (bank != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.line200),
            const SizedBox(height: 12),
            _BankRow(label: 'Holder', value: bank['account_holder']?.toString()),
            _BankRow(label: 'Account', value: bank['account_number']?.toString()),
            _BankRow(label: 'Bank', value: bank['bank_name']?.toString()),
            _BankRow(label: 'Branch', value: bank['branch']?.toString()),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (shop.nationalIdUrl != null)
                _DocButton(label: 'View NID', storagePath: shop.nationalIdUrl!),
              if (shop.nationalIdUrl != null && shop.tradeLicenseUrl != null)
                const SizedBox(width: 8),
              if (shop.tradeLicenseUrl != null)
                _DocButton(label: 'View License', storagePath: shop.tradeLicenseUrl!),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _approve,
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
          ),
          Expanded(
            child: Text(value!,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink950)),
          ),
        ],
      ),
    );
  }
}

class _DocButton extends ConsumerStatefulWidget {
  const _DocButton({required this.label, required this.storagePath});
  final String label;
  final String storagePath;

  @override
  ConsumerState<_DocButton> createState() => _DocButtonState();
}

class _DocButtonState extends ConsumerState<_DocButton> {
  bool _loading = false;

  Future<void> _open() async {
    setState(() => _loading = true);
    try {
      final url = await ref
          .read(adminRepositoryProvider)
          .getSignedDocUrl(widget.storagePath);
      if (!mounted) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _open,
      icon: _loading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : const Icon(Icons.open_in_new_rounded, size: 14),
      label: Text(widget.label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: AppColors.line200),
        foregroundColor: AppColors.blue500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COD panel
// ─────────────────────────────────────────────────────────────────────────────

class _CodPanel extends ConsumerWidget {
  const _CodPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codAsync = ref.watch(codOrdersProvider);

    return _PanelScaffold(
      title: 'COD Reconciliation',
      onRefresh: () => ref.read(codOrdersProvider.notifier).refresh(),
      child: codAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (orders) => orders.isEmpty
            ? const _EmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'No COD orders pending collection',
              )
            : ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return _CodOrderCard(
                    orderId: order.id,
                    title: order.title,
                    amountFormatted: order.amountFormatted,
                    createdAt: order.createdAt,
                    itemCount: order.lineItems.length,
                    onMarkReceived: () => ref
                        .read(codOrdersProvider.notifier)
                        .markCashReceived(order.id),
                  );
                },
              ),
      ),
    );
  }
}

class _CodOrderCard extends StatefulWidget {
  const _CodOrderCard({
    required this.orderId,
    required this.title,
    required this.amountFormatted,
    required this.createdAt,
    required this.itemCount,
    required this.onMarkReceived,
  });

  final String orderId;
  final String title;
  final String amountFormatted;
  final DateTime createdAt;
  final int itemCount;
  final Future<void> Function() onMarkReceived;

  @override
  State<_CodOrderCard> createState() => _CodOrderCardState();
}

class _CodOrderCardState extends State<_CodOrderCard> {
  bool _busy = false;

  Future<void> _mark() async {
    setState(() => _busy = true);
    await widget.onMarkReceived();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface0,
        boxShadow: const [BoxShadow(color: AppColors.line200, spreadRadius: 0.5)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.blue500.withAlpha(15),
            ),
            child: const Icon(Icons.payments_outlined,
                size: 22, color: AppColors.blue500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.amountFormatted,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink950,
                  ),
                ),
                Text(
                  '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} · ${_fmtDate(widget.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink500),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _busy ? null : _mark,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Cash Received'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payouts panel
// ─────────────────────────────────────────────────────────────────────────────

class _PayoutsPanel extends ConsumerWidget {
  const _PayoutsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider);

    return _PanelScaffold(
      title: 'Payouts',
      onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
      child: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (groups) => groups.isEmpty
            ? const _EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'No vendors with available balance',
              )
            : ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _PayoutCard(group: groups[i]),
              ),
      ),
    );
  }
}

class _PayoutCard extends ConsumerStatefulWidget {
  const _PayoutCard({required this.group});
  final VendorPayoutGroup group;

  @override
  ConsumerState<_PayoutCard> createState() => _PayoutCardState();
}

class _PayoutCardState extends ConsumerState<_PayoutCard> {
  bool _busy = false;
  bool _expanded = false;

  Future<void> _markPaid() async {
    setState(() => _busy = true);
    await ref.read(ledgerProvider.notifier).markShopPaid(widget.group.shop.id);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bank = group.shop.bankAccountDetails;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface0,
        boxShadow: const [BoxShadow(color: AppColors.line200, spreadRadius: 0.5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.shop.shopName,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink950,
                      ),
                    ),
                    Text(
                      '${group.ledgers.length} order${group.ledgers.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink500),
                    ),
                  ],
                ),
              ),
              Text(
                group.totalFormatted,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.ink950,
                ),
              ),
            ],
          ),
          if (bank != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Text('Bank details',
                      style: TextStyle(fontSize: 12, color: AppColors.blue500)),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.blue500,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              _BankRow(label: 'Holder', value: bank['account_holder']?.toString()),
              _BankRow(label: 'Account', value: bank['account_number']?.toString()),
              _BankRow(label: 'Bank', value: bank['bank_name']?.toString()),
              _BankRow(label: 'Branch', value: bank['branch']?.toString()),
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _markPaid,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.done_all_rounded, size: 16),
              label: Text('Mark as Paid (${group.totalFormatted})'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PanelScaffold extends StatelessWidget {
  const _PanelScaffold({
    required this.title,
    required this.child,
    required this.onRefresh,
  });

  final String title;
  final Widget child;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink950,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onRefresh,
                color: AppColors.ink500,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line200),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withAlpha(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.ink300),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 14, color: AppColors.ink500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.ink700)),
        ],
      ),
    );
  }
}
