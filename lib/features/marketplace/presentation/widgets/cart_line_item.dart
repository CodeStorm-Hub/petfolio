import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import '../../data/models/cart_item.dart';
import '../controllers/cart_controller.dart';
import 'product_glyph.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CartLineItem — one row in the CartScreen list
// ─────────────────────────────────────────────────────────────────────────────

class CartLineItem extends ConsumerWidget {
  const CartLineItem({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cart = ref.read(cartProvider.notifier);
    final p = item.product;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(p.gradientStart, Colors.white, 0.5)!, 
                    p.gradientStart
                  ],
                ),
              ),
              child: Center(
                child: p.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrls.first,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          placeholder: (_, _) =>
                              ProductGlyph(glyphType: p.glyphType, size: 30),
                          errorWidget: (_, _, _) =>
                              ProductGlyph(glyphType: p.glyphType, size: 30),
                        ),
                      )
                    : ProductGlyph(glyphType: p.glyphType, size: 30),
              ),
            ),
            const SizedBox(width: 12),
  
            // Name + sub + line total
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: pt.ink950,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.brand,
                    style: TextStyle(
                      fontSize: 11,
                      color: pt.ink500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.lineTotalFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: pt.ink950,
                    ),
                  ),
                  if (item.isSubscribed) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.success.withAlpha(26),
                      ),
                      child: Text(
                        'Sub · every ${item.frequencyWeeks}wk · save 12%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
  
            // Quantity stepper
            _Stepper(
              quantity: item.quantity,
              onDecrement: () => cart.decrement(
                p.id,
                isSubscribed: item.isSubscribed,
                variantId: item.variantId,
              ),
              onIncrement: () => cart.add(
                p,
                subscribe: item.isSubscribed,
                frequencyWeeks: item.frequencyWeeks,
                variantId: item.variantId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.surface2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(label: '−', semanticsLabel: 'Decrease quantity', onTap: onDecrement),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: pt.ink950,
              ),
            ),
          ),
          _StepBtn(label: '+', semanticsLabel: 'Increase quantity', onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.label, required this.semanticsLabel, required this.onTap});

  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.surface0,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: pt.ink950,
              height: 1.1,
            ),
          ),
        ),
      ),
    ),
    );
  }
}
