import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../controllers/buyer_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';

class BuyerOrderListScreen extends ConsumerWidget {
  const BuyerOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);

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
                    'My Orders',
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
                        ref.read(buyerOrdersProvider.notifier).refresh(),
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
                  final sorted = [...orders]
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  if (sorted.isEmpty) {
                    return const _EmptyOrders();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderTile(
                      order: sorted[i],
                      onTap: () => context.push(
                        '/marketplace/orders/${sorted[i].id}',
                        extra: sorted[i],
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
    final actions = _actionsFor(order.status);

    return Semantics(
      label: 'Order: ${order.title}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                          '${_formatDate(order.createdAt)}  ·  ${order.amountFormatted}',
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
            if (actions.isNotEmpty) ...[
              Divider(height: 1, color: AppColors.line),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: actions.map((a) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ActionBtn(
                      label: a.$1,
                      icon: a.$2,
                      color: a.$3,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${a.$1} — coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  List<(String, IconData, Color)> _actionsFor(OrderStatus s) => switch (s) {
        OrderStatus.delivered => [
            ('Rate', Icons.star_outline_rounded, AppColors.sunny),
            ('Reorder', Icons.replay_rounded, AppColors.mint),
            ('Return', Icons.assignment_return_outlined, AppColors.poppy),
          ],
        OrderStatus.shipped => [
            ('Track', Icons.local_shipping_outlined, AppColors.sky),
          ],
        OrderStatus.cancelled => [
            ('Reorder', Icons.replay_rounded, AppColors.mint),
          ],
        _ => [],
      };

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending    => AppColors.warning,
        OrderStatus.processing => AppColors.info,
        OrderStatus.shipped    => AppColors.blue500,
        OrderStatus.delivered  => AppColors.success,
        OrderStatus.cancelled  => AppColors.danger,
      };

  IconData _statusIcon(OrderStatus s) => switch (s) {
        OrderStatus.pending    => Icons.hourglass_empty_rounded,
        OrderStatus.processing => Icons.autorenew_rounded,
        OrderStatus.shipped    => Icons.local_shipping_outlined,
        OrderStatus.delivered  => Icons.check_circle_outline_rounded,
        OrderStatus.cancelled  => Icons.cancel_outlined,
      };

  String _formatDate(DateTime dt) {
    final m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
    );
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
              'No orders yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink950,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your order history will appear here.',
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
