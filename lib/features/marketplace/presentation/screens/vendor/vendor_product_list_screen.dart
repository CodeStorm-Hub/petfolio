import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/vendor_products_controller.dart';
import '../../../data/models/product.dart';
import '../../widgets/product_glyph.dart';

class VendorProductListScreen extends ConsumerWidget {
  const VendorProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

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
                    'My Products',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.ink950,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AppColors.ink950,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push('/seller/products/add'),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.add_rounded,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (products) => products.isEmpty
                    ? _EmptyProducts(
                        onAdd: () => context.push('/seller/products/add'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: products.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ProductTile(
                          product: products[i],
                          onEdit: () => context.push(
                            '/seller/products/${products[i].id}/edit',
                            extra: products[i],
                          ),
                          onDelete: () => _confirmDelete(
                            context,
                            ref,
                            products[i].id,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
            'This will permanently remove the product from your shop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(vendorProductsProvider.notifier).deleteProduct(productId);
    }
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface0,
        boxShadow: const [
          BoxShadow(color: AppColors.line, spreadRadius: 0.5),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [product.gradientStart, product.gradientEnd],
            ),
          ),
          child: Center(
            child: ProductGlyph(glyphType: product.glyphType, size: 28),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.ink950,
          ),
        ),
        subtitle: Text(
          '${product.priceFormatted}  ·  ${product.inventoryCount} in stock',
          style: const TextStyle(fontSize: 12, color: AppColors.ink500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.ink500),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 36, color: AppColors.ink300),
            ),
            const SizedBox(height: 20),
            const Text(
              'No products yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first product to start selling.',
              style: TextStyle(fontSize: 14, color: AppColors.ink500),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'Add Product',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: onAdd,
              leadingIcon: const Icon(Icons.add_rounded, size: 20),
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
    return Material(
      color: AppColors.surface0,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      shadowColor: AppColors.line,
      elevation: 0.5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: AppColors.ink700),
        ),
      ),
    );
  }
}
