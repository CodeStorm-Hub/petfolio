import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_glyph.dart';
import '../widgets/subscription_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductDetailScreen — full-screen route (outside ShellRoute)
// ─────────────────────────────────────────────────────────────────────────────

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  /// Route param from GoRouter (/marketplace/product/:id).
  final String productId;

  /// Passed via GoRouter `extra` for instant paint; nullable if navigated
  /// directly by URL.
  final Product? product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _subscribe = false;
  int _frequencyWeeks = 4;
  int _quantity = 1;

  Product? get _product =>
      widget.product ??
      ref.read(productListProvider).valueOrNull?.firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => throw StateError('Product not found'),
          );

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _subscribe = widget.product!.subscribable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unitCents =
        _subscribe && product.subscribable ? product.subPriceCents : product.priceCents;
    final totalCents = unitCents * _quantity;
    final savingsCents =
        _subscribe && product.subscribable ? product.priceCents - product.subPriceCents : 0;

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProductHero(product: product),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ProductInfo(product: product),
                ),
              ),
              if (product.subscribable)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _SubscribeCard(
                      product: product,
                      subscribe: _subscribe,
                      frequencyWeeks: _frequencyWeeks,
                      onSubscribeChanged: (v) =>
                          setState(() => _subscribe = v),
                      onFrequencyChanged: (w) =>
                          setState(() => _frequencyWeeks = w),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _QuantityStepper(
                    quantity: _quantity,
                    onDecrement: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                    onIncrement: () => setState(() => _quantity++),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _OrderSummaryCard(
                    product: product,
                    quantity: _quantity,
                    unitCents: unitCents,
                    totalCents: totalCents,
                    savingsCents: savingsCents,
                    subscribe: _subscribe,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),

          // Close button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: _IconBtn(
              icon: Icons.close_rounded,
              onTap: () => context.pop(),
            ),
          ),

          // Sticky Pay bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PayBar(
              totalCents: totalCents,
              subscribe: _subscribe,
              frequencyWeeks: _frequencyWeeks,
              onPay: () {
                ref.read(cartProvider.notifier).add(
                      product,
                      subscribe: _subscribe,
                      frequencyWeeks: _frequencyWeeks,
                    );
                // Add requested quantity (add() always adds 1, call multiple times)
                for (var i = 1; i < _quantity; i++) {
                  ref.read(cartProvider.notifier).add(
                        product,
                        subscribe: _subscribe,
                        frequencyWeeks: _frequencyWeeks,
                      );
                }
                context.push('/marketplace/cart');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product hero — gradient tile with glyph
// ─────────────────────────────────────────────────────────────────────────────

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      height: 280 + topPad,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [product.gradientStart, product.gradientEnd],
        ),
      ),
      child: Stack(
        children: [
          // Specular highlight
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 0.8,
                  colors: [
                    Colors.white.withAlpha(80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: topPad),
              child: ProductGlyph(glyphType: product.glyphType, size: 120),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product info block
// ─────────────────────────────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.ink500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.name,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            height: 1.2,
            color: AppColors.ink950,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.variant,
          style: const TextStyle(fontSize: 13, color: AppColors.ink500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              product.priceFormatted,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.ink950,
              ),
            ),
            if (product.subscribable) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.success.withAlpha(26),
                ),
                child: Text(
                  '${product.subPriceFormatted} subscribed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscribe card
// ─────────────────────────────────────────────────────────────────────────────

class _SubscribeCard extends StatelessWidget {
  const _SubscribeCard({
    required this.product,
    required this.subscribe,
    required this.frequencyWeeks,
    required this.onSubscribeChanged,
    required this.onFrequencyChanged,
  });

  final Product product;
  final bool subscribe;
  final int frequencyWeeks;
  final ValueChanged<bool> onSubscribeChanged;
  final ValueChanged<int> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final savingsCents = product.priceCents - product.subPriceCents;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: subscribe ? const Color(0xFFEDF7F2) : AppColors.surface0,
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
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: subscribe ? AppColors.meadow500 : AppColors.surface2,
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 20,
                  color: subscribe ? Colors.white : AppColors.ink500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Subscribe & Save',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink950,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.success.withAlpha(26),
                          ),
                          child: const Text(
                            'Save 12%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subscribe
                          ? 'Auto-delivers every $frequencyWeeks weeks · save \$${(savingsCents / 100).toStringAsFixed(2)}'
                          : 'Save 12% on every refill · cancel anytime',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink500),
                    ),
                  ],
                ),
              ),
              SubscriptionToggle(
                value: subscribe,
                onChanged: onSubscribeChanged,
              ),
            ],
          ),

          // Frequency chips — animated expand
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState: subscribe
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVERY FREQUENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.88,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FrequencyChips(
                    selected: frequencyWeeks,
                    onSelected: onFrequencyChanged,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity stepper card
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.ink950,
            ),
          ),
          const Spacer(),
          Container(
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.surface2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperBtn(label: '−', onTap: onDecrement),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink950,
                    ),
                  ),
                ),
                _StepperBtn(label: '+', onTap: onIncrement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary card
// ─────────────────────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.product,
    required this.quantity,
    required this.unitCents,
    required this.totalCents,
    required this.savingsCents,
    required this.subscribe,
  });

  final Product product;
  final int quantity;
  final int unitCents;
  final int totalCents;
  final int savingsCents;
  final bool subscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value: '\$${(product.priceCents * quantity / 100).toStringAsFixed(2)}',
          ),
          if (subscribe && savingsCents > 0) ...[
            const SizedBox(height: 8),
            _SumRow(
              label: 'Subscribe & Save (12%)',
              value: '− \$${(savingsCents * quantity / 100).toStringAsFixed(2)}',
              accent: AppColors.success,
            ),
          ],
          const SizedBox(height: 8),
          const _SumRow(label: 'Delivery', value: 'Calculated at checkout'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line200, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink950,
                ),
              ),
              Text(
                '\$${(totalCents / 100).toStringAsFixed(2)}',
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
    required this.totalCents,
    required this.subscribe,
    required this.frequencyWeeks,
    required this.onPay,
  });

  final int totalCents;
  final bool subscribe;
  final int frequencyWeeks;
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
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryPillButton(
            label: subscribe
                ? 'Add to cart · \$${(totalCents / 100).toStringAsFixed(2)}'
                : 'Add to cart · \$${(totalCents / 100).toStringAsFixed(2)}',
            size: PillButtonSize.xl,
            isFullWidth: true,
            onPressed: onPay,
            leadingIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
          ),
          if (subscribe) ...[
            const SizedBox(height: 8),
            Text(
              'Then \$${(totalCents / 100).toStringAsFixed(2)} every $frequencyWeeks weeks · pause anytime',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.ink500),
            ),
          ],
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
