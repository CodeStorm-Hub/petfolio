import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import 'product_glyph.dart';
import 'star_rating_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductCard — used in the 2-column grid on the shop screen
// ─────────────────────────────────────────────────────────────────────────────

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: product.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductTile(product: product),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _QuickAddButton(
                      onTap: () => ref.read(cartProvider.notifier).add(product),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ProductMeta(product: product),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProductCardCompact — narrower horizontal card (Subscribe & Save row)
// ─────────────────────────────────────────────────────────────────────────────

class ProductCardCompact extends ConsumerWidget {
  const ProductCardCompact({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: product.name,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 156,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductTile(product: product),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _QuickAddButton(
                        onTap: () =>
                            ref.read(cartProvider.notifier).add(product),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _ProductMeta(product: product, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickAddButton — circular "+" overlay, bottom-right of tile
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add to cart',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowE2L,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductTile — the gradient image square
// ─────────────────────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [product.gradientStart, product.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outlineVariant,
            blurRadius: 0,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial specular highlight
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const RadialGradient(
                  center: Alignment(-0.4, -0.5),
                  radius: 0.7,
                  colors: [Color(0x52FFFFFF), Colors.transparent],
                ),
              ),
            ),
          ),
          // Glyph
          Center(
            child: LayoutBuilder(
              builder: (_, constraints) => ProductGlyph(
                glyphType: product.glyphType,
                size: constraints.maxWidth * 0.42,
              ),
            ),
          ),
          // Rating badge
          if (product.rating != null && product.rating! > 0)
            Positioned(
              top: 8,
              left: product.subscribable ? 88 : 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withAlpha(242),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: AppColors.sunny700,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // "SUB · SAVE 12%" badge
          if (product.subscribable)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withAlpha(242),
                ),
                child: Text(
                  'SUB · SAVE 12%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          // Save / wishlist button
          Positioned(
            top: 8,
            right: 8,
            child: Semantics(
              label: 'Save to wishlist',
              button: true,
              child: GestureDetector(
              onTap: () => AppSnackBar.show('Wishlist coming soon 💛'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(230),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowE2L,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductMeta — brand + name + price text below the tile
// ─────────────────────────────────────────────────────────────────────────────

class _ProductMeta extends StatelessWidget {
  const _ProductMeta({required this.product, this.compact = false});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (product.rating != null && product.rating! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                StarRatingWidget(rating: product.rating!, size: 12),
                if (product.reviewCount != null &&
                    product.reviewCount! > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${product.reviewCount})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Text(
              product.priceFormatted,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (product.subscribable) ...[
              const SizedBox(width: 6),
              Text(
                '${product.subPriceFormatted} sub',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
