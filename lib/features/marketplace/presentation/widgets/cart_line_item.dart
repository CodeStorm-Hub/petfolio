import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
                child: ProductGlyph(glyphType: p.glyphType, size: 30),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink950,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.brand,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.ink500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.ink950,
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
              ),
              onIncrement: () => cart.add(
                p,
                subscribe: item.isSubscribed,
                frequencyWeeks: item.frequencyWeeks,
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.surface2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(label: '−', onTap: onDecrement),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.ink950,
              ),
            ),
          ),
          _StepBtn(label: '+', onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink950,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
