import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../controllers/ledger_controller.dart';
import 'admin_shared_widgets.dart';

class FinancialLedgerTab extends ConsumerWidget {
  const FinancialLedgerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider);

    return AdminPanelScaffold(
      title: 'Payouts',
      onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
      child: ledgerAsync.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (groups) => groups.isEmpty
            ? const AdminEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'No vendors with available balance',
              )
            : ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) => _PayoutCard(group: groups[i]),
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
        color: cs.surface,
        boxShadow: pt.shadowE1,
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
                      style: tt.headlineSmall!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${group.ledgers.length} '
                      'order${group.ledgers.length == 1 ? '' : 's'}',
                      style: tt.labelMedium,
                    ),
                  ],
                ),
              ),
              Text(
                group.totalFormatted,
                style: tt.headlineSmall!.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (bank != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text(
                    'Bank details',
                    style: tt.labelMedium!.copyWith(color: AppColors.blue500),
                  ),
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
              AdminBankRow(
                label: 'Holder',
                value: bank['account_holder']?.toString(),
              ),
              AdminBankRow(
                label: 'Account',
                value: bank['account_number']?.toString(),
              ),
              AdminBankRow(
                label: 'Bank',
                value: bank['bank_name']?.toString(),
              ),
              AdminBankRow(
                label: 'Branch',
                value: bank['branch']?.toString(),
              ),
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
