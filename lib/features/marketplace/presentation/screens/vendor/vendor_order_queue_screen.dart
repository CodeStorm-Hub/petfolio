import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/vendor_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';
import '../../../../../core/theme/app_theme.dart';


class VendorOrderQueueScreen extends ConsumerWidget {
  const VendorOrderQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Order Queue',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        size: 22, color: Color(0xFF64748B)),
                    onPressed: () =>
                        ref.read(vendorOrdersProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator.adaptive()),
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
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: active.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10),
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _statusColor(context, order.status).withAlpha(26),
              ),
              child: Icon(
                _statusIcon(order.status),
                size: 22,
                color: _statusColor(context, order.status),
              ),
            ),
            SizedBox(width: 14),
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
                  SizedBox(height: 3),
                  Text(
                    '${order.lineItems.length} item${order.lineItems.length == 1 ? '' : 's'}  ·  ${order.amountFormatted}',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: order.status),
                SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: pt.ink300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, OrderStatus s) {
    return switch (s) {
      OrderStatus.pending    => Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
      OrderStatus.processing => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
      OrderStatus.shipped    => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
      OrderStatus.delivered  => Theme.of(context).extension<PetfolioThemeExtension>()!.success,
      OrderStatus.cancelled  => Theme.of(context).colorScheme.error,
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

  Color _color(BuildContext context) => switch (status) {
        OrderStatus.pending    => Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
        OrderStatus.processing => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
        OrderStatus.shipped    => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
        OrderStatus.delivered  => Theme.of(context).extension<PetfolioThemeExtension>()!.success,
        OrderStatus.cancelled  => Theme.of(context).colorScheme.error,
      };

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _color(context).withAlpha(26),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color(context),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: pt.ink300),
            SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: pt.ink950,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New orders from buyers will appear here.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: Color(0xFF334155)),
      ),
    );
  }
}
