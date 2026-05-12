import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/cart_item.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/cart_line_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CartScreen — full-screen route (outside ShellRoute)
// ─────────────────────────────────────────────────────────────────────────────

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);

    // Navigate to confirmation when checkout succeeds.
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

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
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
                          fontFamily: 'Sora',
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

                // Body
                Expanded(
                  child: cart.isEmpty
                      ? const _EmptyCart()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 200),
                          children: [
                            for (final item in cart.items)
                              CartLineItem(item: item),
                            const SizedBox(height: 16),
                            _OrderSummaryCard(cart: cart),
                          ],
                        ),
                ),
              ],
            ),

            // Sticky pay bar
            if (!cart.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PayBar(
                  cart: cart,
                  isLoading: checkout.isLoading,
                  onPay: () =>
                      ref.read(checkoutProvider.notifier).startCheckout(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary
// ─────────────────────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
            BoxShadow(
              color: Color(0x040B1220),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 10),
            _SumRow(
              label: 'Subtotal',
              value:
                  '\$${(cart.items.fold(0, (s, i) => s + i.product.priceCents * i.quantity) / 100).toStringAsFixed(2)}',
            ),
            if (cart.savingsCents > 0) ...[
              const SizedBox(height: 8),
              _SumRow(
                label: 'Subscribe & Save (12%)',
                value: '− \$${(cart.savingsCents / 100).toStringAsFixed(2)}',
                accent: AppColors.success,
              ),
            ],
            const SizedBox(height: 8),
            const _SumRow(label: 'Delivery', value: 'Calculated at payment'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.line200, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total today',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink950,
                  ),
                ),
                Text(
                  cart.totalFormatted,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: -0.22,
                    color: AppColors.ink950,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.ink500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: accent ?? AppColors.ink950,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky pay bar
// ─────────────────────────────────────────────────────────────────────────────

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.cart,
    required this.isLoading,
    required this.onPay,
  });

  final CartState cart;
  final bool isLoading;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surface1.withAlpha(235),
        boxShadow: const [
          BoxShadow(
            color: AppColors.line200,
            offset: Offset(0, -0.5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryPillButton(
            label: 'Pay ${cart.totalFormatted}',
            size: PillButtonSize.xl,
            isFullWidth: true,
            isLoading: isLoading,
            onPressed: isLoading ? null : onPay,
            leadingIcon: isLoading
                ? null
                : const Icon(Icons.face_retouching_natural, size: 20),
          ),
          if (cart.hasSubscription) ...[
            const SizedBox(height: 8),
            const Text(
              'Includes recurring subscription · manage anytime in Settings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.ink500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty cart
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface2,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 36, color: AppColors.ink300),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.ink950,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse the shop to find food,\ngear, treats and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.ink500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon button helper
// ─────────────────────────────────────────────────────────────────────────────

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
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
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
