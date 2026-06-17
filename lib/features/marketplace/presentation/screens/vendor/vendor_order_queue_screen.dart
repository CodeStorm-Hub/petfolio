import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../controllers/vendor_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';

class VendorOrderQueueScreen extends ConsumerWidget {
  const VendorOrderQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Order Queue',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.ink950,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded,
                        size: 22, color: AppColors.ink500),
                    onPressed: () =>
                        ref.read(vendorOrdersProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (orders) {
                  final active = orders
                      .where((o) => o.status.isActive)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  if (active.isEmpty) {
                    return const _EmptyOrders();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: active.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderTile(
                      order: active[i],
                      onTap: () => context.push(
                        '/seller/orders/${active[i].id}',
                        extra: active[i],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final MarketplaceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Order: ${order.title}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _statusColor(order.status).withAlpha(26),
              ),
              child: Icon(
                _statusIcon(order.status),
                size: 22,
                color: _statusColor(order.status),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.ink950,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.lineItems.length} item${order.lineItems.length == 1 ? '' : 's'}  ·  ${order.amountFormatted}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: order.status),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.ink300),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Color _statusColor(OrderStatus s) {
    return switch (s) {
      OrderStatus.pending    => AppColors.warning,
      OrderStatus.processing => AppColors.info,
      OrderStatus.shipped    => AppColors.blue500,
      OrderStatus.delivered  => AppColors.success,
      OrderStatus.cancelled  => AppColors.danger,
    };
  }

  IconData _statusIcon(OrderStatus s) {
    return switch (s) {
      OrderStatus.pending    => Icons.hourglass_empty_rounded,
      OrderStatus.processing => Icons.autorenew_rounded,
      OrderStatus.shipped    => Icons.local_shipping_outlined,
      OrderStatus.delivered  => Icons.check_circle_outline_rounded,
      OrderStatus.cancelled  => Icons.cancel_outlined,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  Color get _color => switch (status) {
        OrderStatus.pending    => AppColors.warning,
        OrderStatus.processing => AppColors.info,
        OrderStatus.shipped    => AppColors.blue500,
        OrderStatus.delivered  => AppColors.success,
        OrderStatus.cancelled  => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _color.withAlpha(26),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.ink300),
            SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink950,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New orders from buyers will appear here.',
              style: TextStyle(fontSize: 14, color: AppColors.ink500),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink700),
      ),
    ),
    );
  }
}
