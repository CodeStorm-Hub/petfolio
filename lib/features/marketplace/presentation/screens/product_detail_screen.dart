import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_glyph.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/subscription_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  final String productId;
  final Product? product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with SingleTickerProviderStateMixin {
  bool _subscribe = false;
  int _frequencyWeeks = 4;
  int _quantity = 1;
  bool _popping = false;
  
  Product? get _product =>
      widget.product ??
      ref.read(productListProvider).value?.firstWhere(
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

  void _handleAdd() {
    setState(() => _popping = true);
    final p = _product;
    if (p != null) {
      for (int i = 0; i < _quantity; i++) {
        Future.delayed(Duration(milliseconds: i * 90), () {
          ref.read(cartProvider.notifier).add(p, subscribe: _subscribe, frequencyWeeks: _frequencyWeeks);
        });
      }
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _popping = false);
    });
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
        
    final cartItemCount = ref.watch(cartProvider.select((c) => c.itemCount));

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProductHero(
                  product: product, 
                  cartCount: cartItemCount, 
                  popping: _popping,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ProductInfo(product: product),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: ProductReviewsSection(product: product),
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

          // Sticky Pay bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PayBar(
              totalCents: totalCents,
              subscribe: _subscribe,
              frequencyWeeks: _frequencyWeeks,
              onPay: _handleAdd,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product hero
// ─────────────────────────────────────────────────────────────────────────────

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product, required this.cartCount, required this.popping});

  final Product product;
  final int cartCount;
  final bool popping;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 320 + topPad,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(product.gradientStart, Colors.white, 0.5)!, 
                    product.gradientStart
                  ],
                ),
              ),
            ),
          ),
          
          // Header icons
          Positioned(
            top: topPad + 14,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  bg: Colors.white.withAlpha(235),
                  onTap: () => context.pop(),
                ),
                Row(
                  children: [
                    _IconBtn(
                      icon: Icons.bookmark_outline_rounded,
                      bg: Colors.white.withAlpha(235),
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _IconBtn(
                          icon: Icons.shopping_cart_outlined,
                          bg: Colors.white.withAlpha(235),
                          onTap: () => context.push('/marketplace/cart'),
                        ),
                        if (cartCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.poppy,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Glyph
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: topPad),
              child: AnimatedScale(
                scale: popping ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: const ElasticOutCurve(0.8),
                child: AnimatedRotation(
                  turns: popping ? -8 / 360 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: const ElasticOutCurve(0.8),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ProductGlyph(glyphType: product.glyphType, size: 180),
                  ),
                ),
              ),
            ),
          ),
          
          // Wave bottom
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _WavePainter(color: AppColors.surface1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});
  final Color color;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height);
    path.cubicTo(
      size.width * 0.22, size.height * 0.25, 
      size.width * 0.39, size.height * 1.75, 
      size.width * 0.53, size.height
    );
    path.cubicTo(
      size.width * 0.68, size.height * 0.38, 
      size.width * 0.83, size.height * 1.5, 
      size.width, size.height * 0.75
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    // Better approximation of the SVG: d="M0,40 C90,10 160,70 220,40 C280,15 340,60 412,30 L412,60 L0,60 Z"
    final exactPath = Path();
    exactPath.moveTo(0, size.height * 0.66); // 40 / 60
    exactPath.cubicTo(
      size.width * (90/412), size.height * (10/60),
      size.width * (160/412), size.height * (70/60),
      size.width * (220/412), size.height * (40/60)
    );
    exactPath.cubicTo(
      size.width * (280/412), size.height * (15/60),
      size.width * (340/412), size.height * (60/60),
      size.width, size.height * (30/60)
    );
    exactPath.lineTo(size.width, size.height);
    exactPath.lineTo(0, size.height);
    exactPath.close();
    
    canvas.drawPath(exactPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sunny.withAlpha(26),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.sunny700, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    product.rating != null
                        ? product.rating!.toStringAsFixed(1)
                        : '—',
                    style: const TextStyle(
                      color: AppColors.sunny700,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  if (product.reviewCount != null && product.reviewCount! > 0)
                    Text(
                      ' · ${product.reviewCount} review${product.reviewCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.sunny700,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mint.withAlpha(26),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Free delivery',
                style: TextStyle(
                  color: AppColors.mint700,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.brand,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.ink500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            height: 1.1,
            color: AppColors.ink950,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.variant,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink500),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              product.priceFormatted,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: AppColors.ink950,
              ),
            ),
            if (product.subscribable) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.success.withAlpha(26),
                ),
                child: Text(
                  '${product.subPriceFormatted} subscribed',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: subscribe ? const Color(0xFFEDF7F2) : AppColors.surface0,
        border: Border.all(color: subscribe ? const Color(0xFFC3E8D6) : AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060B1220),
            offset: Offset(0, 4),
            blurRadius: 12,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: subscribe ? AppColors.meadow500 : AppColors.surface2,
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 24,
                  color: subscribe ? Colors.white : AppColors.ink500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Subscribe & Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink950,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.success.withAlpha(26),
                          ),
                          child: const Text(
                            'Save 12%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscribe
                          ? 'Auto-delivers every $frequencyWeeks weeks · save \$${(savingsCents / 100).toStringAsFixed(2)}'
                          : 'Save 12% on every refill · cancel anytime',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink500),
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
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVERY FREQUENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.88,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surface0,
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040B1220),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink950,
            ),
          ),
          const Spacer(),
          Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.surface2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperBtn(label: '−', onTap: onDecrement),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
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
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.surface0,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink950,
              height: 1.1,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surface0,
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040B1220),
            offset: Offset(0, 4),
            blurRadius: 12,
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
              fontWeight: FontWeight.w800,
              letterSpacing: 0.88,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 12),
          _SumRow(
            label: 'Subtotal',
            value: '\$${(product.priceCents * quantity / 100).toStringAsFixed(2)}',
          ),
          if (subscribe && savingsCents > 0) ...[
            const SizedBox(height: 10),
            _SumRow(
              label: 'Subscribe & Save (12%)',
              value: '− \$${(savingsCents * quantity / 100).toStringAsFixed(2)}',
              accent: AppColors.success,
            ),
          ],
          const SizedBox(height: 10),
          const _SumRow(label: 'Delivery', value: 'Calculated at checkout'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.ink950,
                ),
              ),
              Text(
                '\$${(totalCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surface1.withAlpha(235),
        boxShadow: const [
          BoxShadow(
            color: AppColors.line,
            offset: Offset(0, -1),
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
            const SizedBox(height: 10),
            Text(
              'Then \$${(totalCents / 100).toStringAsFixed(2)} every $frequencyWeeks weeks · pause anytime',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink500),
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
  const _IconBtn({required this.icon, required this.onTap, this.bg});

  final IconData icon;
  final VoidCallback onTap;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg ?? AppColors.surface0,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B1220),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: AppColors.ink700),
      ),
    );
  }
}
