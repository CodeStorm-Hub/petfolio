import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import 'product_glyph.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductCard — used in the 2-column grid on the shop screen
// ─────────────────────────────────────────────────────────────────────────────

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
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
          const SizedBox(height: 8),
          _ProductMeta(product: product),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 156,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
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
            const SizedBox(height: 8),
            _ProductMeta(product: product, compact: true),
          ],
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
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: const CircleBorder(),
        color: Colors.white,
        elevation: 3,
        shadowColor: const Color(0x1A0B1220),
        child: InkWell(
          onTap: onTap,
          child: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink950),
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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [product.gradientStart, product.gradientEnd],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.line200, blurRadius: 0, spreadRadius: 0.5),
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
                      letterSpacing: 0.04 * 10,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: tt.labelSmall!.copyWith(color: pt.ink500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          product.name,
          style: tt.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 13 : null,
            height: 1.25,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              product.priceFormatted,
              style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            if (product.subscribable) ...[
              const SizedBox(width: 6),
              Text(
                '${product.subPriceFormatted} sub',
                style: tt.labelSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
