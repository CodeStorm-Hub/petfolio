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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface0,
        border: Border(
          bottom: BorderSide(color: AppColors.line100, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.gradientStart, p.gradientEnd],
              ),
            ),
            child: Center(
              child: ProductGlyph(glyphType: p.glyphType, size: 32),
            ),
          ),
          const SizedBox(width: 12),

          // Name + price + subscription label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.brand,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.ink500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.ink950,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.isSubscribed)
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
            ),
          ),
          const SizedBox(width: 12),

          // Quantity stepper + line total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Line total
              Text(
                '\$${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.ink950,
                ),
              ),
              const SizedBox(height: 8),

              // Stepper
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
        ],
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
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.surface2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(label: '−', onTap: onDecrement),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
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
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink700,
            ),
          ),
        ),
      ),
    );
  }
}
