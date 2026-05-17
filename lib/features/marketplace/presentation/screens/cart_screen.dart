import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/cart_item.dart';
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
    final checkout = ref.watch(checkoutProvider);
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
            Expanded(
              child: cart.isEmpty
                  ? const _EmptyCart()
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
                            cart: cart,
                            checkout: checkout,
                            canCheckout: entry.key == _petfolioOfficialShopId ||
                                verifiedShopIds.contains(entry.key),
                            onCheckout: () => ref
                                .read(checkoutProvider.notifier)
                                .startCheckoutForShop(entry.key),
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

class _VendorGroup extends StatelessWidget {
  const _VendorGroup({
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.cart,
    required this.checkout,
    required this.canCheckout,
    required this.onCheckout,
  });

  final String shopId;
  final String shopName;
  final List<CartItem> items;
  final CartState cart;
  final CheckoutState checkout;
  final bool canCheckout;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final subtotalCents = cart.totalCentsForShop(shopId);
    final subtotal = '\$${(subtotalCents / 100).toStringAsFixed(2)}';
    final isLoading = checkout.isLoadingShop(shopId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
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
                    child: Text(
                      shopName,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.ink950,
                      ),
                    ),
                  ),
                  Text(
                    '${items.fold<int>(0, (s, i) => s + i.quantity)} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
            if (!canCheckout)
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
            for (final item in items) CartLineItem(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink950,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PrimaryPillButton(
                label: 'Checkout $shopName',
                size: PillButtonSize.lg,
                isFullWidth: true,
                isLoading: isLoading,
                onPressed: canCheckout && !isLoading ? onCheckout : null,
                leadingIcon: isLoading
                    ? null
                    : const Icon(Icons.lock_outline_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
