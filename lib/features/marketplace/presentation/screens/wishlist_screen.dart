import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/product.dart';
import '../controllers/wishlist_controller.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final async = ref.watch(wishlistItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _IconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Back',
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Wishlist',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('$e')),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptyWishlist(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _WishlistProductCard(
                      product: items[i].product,
                      wishlistItemId: items[i].item.id,
                      onRemove: () => _removeItem(ref, items[i].item.productId),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeItem(WidgetRef ref, String productId) async {
    await ref
        .read(wishlistItemsProvider.notifier)
        .toggle(productId);
    AppSnackBar.show('Removed from wishlist');
  }
}

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    required this.wishlistItemId,
    required this.onRemove,
  });

  final Product product;
  final String wishlistItemId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProductCard(
          product: product,
          onTap: () => context.push(
            '/marketplace/product/${product.id}',
            extra: product,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Semantics(
            label: 'Remove from wishlist',
            button: true,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(230),
                  boxShadow: const [
                    BoxShadow(color: AppColors.line, spreadRadius: 0.5),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppColors.poppy,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border_rounded,
            size: 56, color: pt.ink300),
        const SizedBox(height: 16),
        Text(
          'Your wishlist is empty',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: pt.ink950,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the heart on any product\nto save it here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: pt.ink500),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/marketplace'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.poppy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text('Browse Products',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
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
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: pt.ink700),
      ),
    ),
    );
  }
}
