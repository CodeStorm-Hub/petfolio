import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/marketplace_order.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/shop_list_controller.dart';
import '../widgets/cart_line_item.dart';

const _petfolioOfficialShopId = 'cccccccc-0000-0000-0000-cccccccccccc';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final shopsAsync = ref.watch(shopListProvider);
    final verifiedShopIds = shopsAsync.value?.map((s) => s.id).toSet() ?? {};

    ref.listen(checkoutProvider, (prev, next) {
      if (next.status == CheckoutStatus.success && next.orderId != null) {
        context.pushReplacement('/marketplace/order/${next.orderId}');
        ref.read(checkoutProvider.notifier).reset();
      }
      if (next.status == CheckoutStatus.failure &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(checkoutProvider.notifier).reset();
      }
    });

    final groups = cart.itemsByShop.entries.toList();

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
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Cart',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.ink950,
                    ),
                  ),
                  const Spacer(),
                  if (!cart.isEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(cartProvider.notifier).clear(),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? const PetfolioEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      subtitle: 'Browse the shop to find food, gear, treats and more.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        for (final entry in groups)
                          _VendorGroup(
                            shopId: entry.key,
                            shopName: entry.value.first.product.shopName
                                    .trim()
                                    .isNotEmpty
                                ? entry.value.first.product.shopName
                                : 'Shop',
                            items: entry.value,
                            canCheckout: entry.key == _petfolioOfficialShopId ||
                                verifiedShopIds.contains(entry.key),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorGroup extends ConsumerStatefulWidget {
  const _VendorGroup({
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.canCheckout,
  });

  final String shopId;
  final String shopName;
  final List<CartItem> items;
  final bool canCheckout;

  @override
  ConsumerState<_VendorGroup> createState() => _VendorGroupState();
}

class _VendorGroupState extends ConsumerState<_VendorGroup> {
  PaymentMethod _method = PaymentMethod.stripe;

  void _handleCheckout(int subtotalCents) {
    if (_method == PaymentMethod.cod) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _CodConfirmSheet(
          shopName: widget.shopName,
          items: widget.items,
          subtotalCents: subtotalCents,
          onConfirm: () {
            Navigator.pop(context);
            ref
                .read(checkoutProvider.notifier)
                .startCodCheckoutForShop(widget.shopId);
          },
        ),
      );
    } else {
      ref
          .read(checkoutProvider.notifier)
          .startCheckoutForShop(widget.shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final subtotalCents = cart.totalCentsForShop(widget.shopId);
    final subtotal = '\$${(subtotalCents / 100).toStringAsFixed(2)}';
    final isLoading = checkout.isLoadingShop(widget.shopId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
            BoxShadow(
              color: Color(0x040B1220),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 18, color: AppColors.ink500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.ink950,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Est. delivery: 2-3 business days',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.items.fold<int>(0, (s, i) => s + i.quantity)} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.canCheckout)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFFF3CD),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This shop is not ready to accept payments yet.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final item in widget.items) CartLineItem(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(fontSize: 13, color: AppColors.ink500),
                  ),
                  Text(
                    subtotal,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink950,
                    ),
                  ),
                ],
              ),
            ),
            _PaymentSelector(
              selected: _method,
              onChanged: (m) => setState(() => _method = m),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryPillButton(
                label: _method == PaymentMethod.cod
                    ? 'Place Order (COD)'
                    : 'Checkout ${widget.shopName}',
                size: PillButtonSize.lg,
                isFullWidth: true,
                isLoading: isLoading,
                onPressed: widget.canCheckout && !isLoading
                    ? () => _handleCheckout(subtotalCents)
                    : null,
                leadingIcon: isLoading
                    ? null
                    : Icon(
                        _method == PaymentMethod.cod
                            ? Icons.payments_outlined
                            : Icons.lock_outline_rounded,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _PaymentChip(
              label: 'Credit Card',
              icon: Icons.credit_card_rounded,
              selected: selected == PaymentMethod.stripe,
              onTap: () => onChanged(PaymentMethod.stripe),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PaymentChip(
              label: 'Cash on Delivery',
              icon: Icons.payments_outlined,
              selected: selected == PaymentMethod.cod,
              onTap: () => onChanged(PaymentMethod.cod),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? AppColors.blue500.withAlpha(15)
              : AppColors.surface1,
          border: Border.all(
            color: selected ? AppColors.blue500 : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.blue500 : AppColors.ink500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.blue500 : AppColors.ink700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodConfirmSheet extends StatelessWidget {
  const _CodConfirmSheet({
    required this.shopName,
    required this.items,
    required this.subtotalCents,
    required this.onConfirm,
  });

  final String shopName;
  final List<CartItem> items;
  final int subtotalCents;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final subtotal = '\$${(subtotalCents / 100).toStringAsFixed(2)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.line,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirm Order',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shopName,
              style: const TextStyle(fontSize: 13, color: AppColors.ink500),
            ),
            const SizedBox(height: 16),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} × ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                    Text(
                      '\$${((item.product.priceCents * item.quantity) / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24, color: AppColors.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink950,
                  ),
                ),
                Text(
                  subtotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink950,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFFFF3CD),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pay when you receive your order.',
                      style: TextStyle(fontSize: 12, color: AppColors.ink700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryPillButton(
              label: 'Place Order',
              size: PillButtonSize.xl,
              isFullWidth: true,
              onPressed: onConfirm,
              leadingIcon:
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
            BoxShadow(
              color: Color(0x0A0B1220),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink700),
      ),
    );
  }
}
