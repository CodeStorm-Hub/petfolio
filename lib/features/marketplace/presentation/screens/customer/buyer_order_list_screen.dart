import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import '../../controllers/buyer_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';
import '../../widgets/marketplace_back_button.dart';
import '../../widgets/marketplace_state_views.dart';

class BuyerOrderListScreen extends ConsumerWidget {
  const BuyerOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const MarketplaceBackButton(),
                  const SizedBox(width: 4),
                  Text(
                    'My Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: pt.ink950,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Icon(Icons.refresh_rounded,
                        size: 22, color: pt.ink500),
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
                error: (e, _) => MarketplaceErrorView(
                  message: 'Could not load your orders',
                  onRetry: () => ref.read(buyerOrdersProvider.notifier).refresh(),
                ),
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
      final cs = Theme.of(context).colorScheme;
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final actions = _actionsFor(order.status);

    return Semantics(
      label: 'Order: ${order.title}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          boxShadow: [
            BoxShadow(color: pt.line, spreadRadius: 0.5),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: pt.ink950,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(order.createdAt)}  ·  ${order.amountFormatted}',
                          style: TextStyle(
                              fontSize: 12, color: pt.ink500),
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
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: pt.ink300),
                    ],
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              Divider(height: 1, color: pt.line),
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
    return MarketplaceEmptyView(
      icon: Icons.receipt_long_outlined,
      title: 'No orders yet',
      message: 'Your order history will appear here.',
      ctaLabel: 'Browse Products',
      onCta: () => context.go('/marketplace'),
    );
  }
}
