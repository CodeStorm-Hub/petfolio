import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/cod_orders_controller.dart';
import 'admin_shared_widgets.dart';

class OrdersTab extends ConsumerWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codAsync = ref.watch(codOrdersProvider);

    return AdminPanelScaffold(
      title: 'COD Reconciliation',
      onRefresh: () => ref.read(codOrdersProvider.notifier).refresh(),
      child: codAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (orders) => orders.isEmpty
            ? const AdminEmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'No COD orders pending collection',
              )
            : ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return _CodOrderCard(
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
    required this.amountFormatted,
    required this.createdAt,
    required this.itemCount,
    required this.onMarkReceived,
  });

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

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
