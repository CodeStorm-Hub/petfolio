import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_glyph.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/subscription_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductDetailScreen — Phase 3: seller row, image carousel,
// dual sticky CTA (Add to Cart + Buy Now), variant customize sheet.
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

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _subscribe = false;
  int _frequencyWeeks = 4;
  bool _popping = false;
  late final PageController _pageCtrl;
  int _pageIndex = 0;

  Product? get _product =>
      widget.product ??
      ref.read(productListProvider).value?.firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => throw StateError('Product not found'),
          );

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (widget.product != null) {
      _subscribe = widget.product!.subscribable;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // Add to cart inline — no navigation, shows snackbar
  void _handleAddToCart() {
    final p = _product;
    if (p == null) return;
    HapticFeedback.selectionClick();
    setState(() => _popping = true);
    ref.read(cartProvider.notifier).add(p, subscribe: false, frequencyWeeks: _frequencyWeeks);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _popping = false);
    });
    AppSnackBar.showSuccess('Added to cart 🛒');
  }

  // Buy Now — opens variant sheet, on confirm adds qty items and goes to cart
  void _handleBuyNow() {
    final p = _product;
    if (p == null) return;
    showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantSheetContent(
        product: p,
        subscribe: _subscribe,
        frequencyWeeks: _frequencyWeeks,
      ),
    ).then((qty) {
      if (qty == null || qty <= 0 || !mounted) return;
      setState(() => _popping = true);
      for (var i = 0; i < qty; i++) {
        Future.delayed(Duration(milliseconds: i * 90), () {
          ref.read(cartProvider.notifier).add(
            p,
            subscribe: _subscribe,
            frequencyWeeks: _frequencyWeeks,
          );
        });
      }
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _popping = false);
          context.push('/marketplace/cart');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cartItemCount = ref.watch(cartProvider.select((c) => c.itemCount));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : const Color(0xFFF6F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Image carousel / glyph hero ──────────────────────────────
              SliverToBoxAdapter(
                child: _ProductHeroCarousel(
                  product: product,
                  cartCount: cartItemCount,
                  popping: _popping,
                  pageCtrl: _pageCtrl,
                  pageIndex: _pageIndex,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  isDark: isDark,
                  pt: pt,
                ),
              ),

              // ── Seller row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SellerRow(product: product, isDark: isDark, pt: pt),
                ),
              ),

              // ── Product info ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ProductInfo(product: product, subscribe: _subscribe, pt: pt),
                ),
              ),

              // ── Reviews ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: ProductReviewsSection(product: product),
                ),
              ),

              // ── Subscribe card ────────────────────────────────────────────
              if (product.subscribable)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _SubscribeCard(
                      product: product,
                      subscribe: _subscribe,
                      frequencyWeeks: _frequencyWeeks,
                      onSubscribeChanged: (v) => setState(() => _subscribe = v),
                      onFrequencyChanged: (w) => setState(() => _frequencyWeeks = w),
                    ),
                  ),
                ),

              // ── Bottom clearance for dual CTA ─────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 116 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),

          // ── Dual CTA sticky footer ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DualCtaBar(
              product: product,
              subscribe: _subscribe,
              onAddToCart: _handleAddToCart,
              onBuyNow: _handleBuyNow,
              isDark: isDark,
              pt: pt,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product hero carousel — swipeable images with fallback to ProductGlyph
// ─────────────────────────────────────────────────────────────────────────────

class _ProductHeroCarousel extends StatelessWidget {
  const _ProductHeroCarousel({
    required this.product,
    required this.cartCount,
    required this.popping,
    required this.pageCtrl,
    required this.pageIndex,
    required this.onPageChanged,
    required this.isDark,
    required this.pt,
  });

  final Product product;
  final int cartCount;
  final bool popping;
  final PageController pageCtrl;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final hasImages = product.imageUrls.isNotEmpty;

    return SizedBox(
      height: 320 + topPad,
      child: Stack(
        children: [
          // ── Gradient background ───────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      product.gradientStart,
                      isDark ? Colors.black : Colors.white,
                      0.45,
                    )!,
                    product.gradientStart,
                  ],
                ),
              ),
            ),
          ),

          // ── Image carousel or animated glyph ──────────────────────────────
          Padding(
            padding: EdgeInsets.only(top: topPad + 56, bottom: 44),
            child: hasImages
                ? PageView.builder(
                    controller: pageCtrl,
                    onPageChanged: onPageChanged,
                    itemCount: product.imageUrls.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrls[i],
                        fit: BoxFit.contain,
                        placeholder: (_, _) => Center(
                          child: ProductGlyph(glyphType: product.glyphType, size: 160),
                        ),
                        errorWidget: (_, _, _) =>
                            Center(child: ProductGlyph(glyphType: product.glyphType, size: 160)),
                      ),
                    ),
                  )
                : Center(
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

          // ── Pagination dots (> 1 image) ────────────────────────────────────
          if (hasImages && product.imageUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: pageCtrl,
                  count: product.imageUrls.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Colors.white,
                    dotColor: Color(0x66FFFFFF),
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3,
                    spacing: 6,
                  ),
                ),
              ),
            ),

          // ── Header row: back / bookmark / cart ────────────────────────────
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

          // ── Wave transition into page background ──────────────────────────
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _WavePainter(
                  color: isDark ? pt.surface1 : const Color(0xFFF6F7FA),
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
// Wave painter — smooth bottom-of-hero transition
// ─────────────────────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.66)
      ..cubicTo(
        size.width * (90 / 412), size.height * (10 / 60),
        size.width * (160 / 412), size.height * (70 / 60),
        size.width * (220 / 412), size.height * (40 / 60),
      )
      ..cubicTo(
        size.width * (280 / 412), size.height * (15 / 60),
        size.width * (340 / 412), size.height * (60 / 60),
        size.width, size.height * (30 / 60),
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Seller row — shop initial avatar + name + category → storefront
// ─────────────────────────────────────────────────────────────────────────────

class _SellerRow extends StatelessWidget {
  const _SellerRow({
    required this.product,
    required this.isDark,
    required this.pt,
  });

  final Product product;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final shopName = product.shopName.isNotEmpty ? product.shopName : 'PetFolio Shop';
    final initial = shopName[0].toUpperCase();

    return Material(
      color: isDark ? pt.surface2 : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (product.shopId.isEmpty) return;
          HapticFeedback.selectionClick();
          context.push('/shop/${product.shopId}');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isDark ? Border.all(color: Colors.white.withAlpha(14)) : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.shadowE3L,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Shop initial avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: product.gradientStart.withAlpha(isDark ? 60 : 40),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: product.gradientStart,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Shop name + category label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shopName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: pt.ink950,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pt.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: pt.ink500, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product info — badges, brand, name, variant, price with discount badge
// ─────────────────────────────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.product,
    required this.subscribe,
    required this.pt,
  });

  final Product product;
  final bool subscribe;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final showSubPrice = subscribe && product.subscribable;
    final displayCents = showSubPrice ? product.subPriceCents : product.priceCents;
    final displayFormatted = '\$${(displayCents / 100).toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rating + free delivery badges ─────────────────────────────────
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

        // ── Brand eyebrow ─────────────────────────────────────────────────
        Text(
          product.brand.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: pt.ink500,
          ),
        ),
        const SizedBox(height: 4),

        // ── Product name ──────────────────────────────────────────────────
        Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            height: 1.2,
            color: pt.ink950,
          ),
        ),

        // ── Variant label ─────────────────────────────────────────────────
        if (product.variant.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            product.variant,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pt.ink500,
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── Price row — subscribe: strikethrough + discount badge ──────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayFormatted,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: pt.ink950,
                letterSpacing: -0.3,
              ),
            ),
            if (showSubPrice) ...[
              const SizedBox(width: 10),
              Text(
                product.priceFormatted,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: pt.ink500,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: pt.ink500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.poppy,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  '-12%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
// Subscribe card — unchanged from Phase 2
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
                  color: subscribe ? AppColors.mint : AppColors.surface2,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink500,
                      ),
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState:
                subscribe ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
// Dual CTA sticky footer — outlined "Add to Cart" + filled "Buy Now"
// ─────────────────────────────────────────────────────────────────────────────

class _DualCtaBar extends StatelessWidget {
  const _DualCtaBar({
    required this.product,
    required this.subscribe,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.isDark,
    required this.pt,
  });

  final Product product;
  final bool subscribe;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final buyNowPrice = subscribe && product.subscribable
        ? '\$${(product.subPriceCents / 100).toStringAsFixed(2)}'
        : product.priceFormatted;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: isDark
            ? pt.surface1.withAlpha(242)
            : Colors.white.withAlpha(242),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withAlpha(16) : AppColors.line,
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(14),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                  spreadRadius: -4,
                ),
              ],
      ),
      child: Row(
        children: [
          // ── Add to Cart — outlined ────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? pt.ink950 : AppColors.ink950,
                  side: BorderSide(
                    color: isDark ? pt.line : AppColors.line,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Buy Now — filled (2× width) ───────────────────────────────────
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onBuyNow,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.poppy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Buy Now'),
                    const SizedBox(width: 8),
                    Text(
                      buyNowPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
// Variant sheet — "Customize as per your choice" Pathao-style bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _VariantSheetContent extends StatefulWidget {
  const _VariantSheetContent({
    required this.product,
    required this.subscribe,
    required this.frequencyWeeks,
  });

  final Product product;
  final bool subscribe;
  final int frequencyWeeks;

  @override
  State<_VariantSheetContent> createState() => _VariantSheetContentState();
}

class _VariantSheetContentState extends State<_VariantSheetContent> {
  int _qty = 1;

  int get _unitCents => widget.subscribe && widget.product.subscribable
      ? widget.product.subPriceCents
      : widget.product.priceCents;

  int get _totalCents => _unitCents * _qty;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final showDiscount = widget.subscribe && product.subscribable;
    final variantLabel = product.variant.isNotEmpty ? product.variant : 'Standard';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? pt.surface1 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: pt.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customize as per your choice',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: pt.ink950,
                      ),
                    ),
                  ),
                  Material(
                    color: isDark ? pt.surface2 : const Color(0xFFF0F1F5),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Icon(Icons.close_rounded, size: 16, color: pt.ink500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: pt.line),

            // ── Choose variant section ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Choose one',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pt.ink500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mint700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Auto-selected variant row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? pt.surface2 : const Color(0xFFF6F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.mint.withAlpha(isDark ? 70 : 60),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio indicator — auto-selected
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.mint, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mint,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            variantLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: pt.ink950,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? pt.surface1 : const Color(0xFFECEDF1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Auto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pt.ink500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Divider(height: 1, color: pt.line),

            // ── Quantity stepper ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: pt.ink950,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: isDark ? pt.surface2 : const Color(0xFFF0F1F5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SheetStepperBtn(
                          label: '−',
                          isDark: isDark,
                          pt: pt,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (_qty > 1) setState(() => _qty--);
                          },
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$_qty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: pt.ink950,
                            ),
                          ),
                        ),
                        _SheetStepperBtn(
                          label: '+',
                          isDark: isDark,
                          pt: pt,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _qty++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Confirm CTA ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(_qty);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.poppy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${(_totalCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          product.priceFormatted,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white60,
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
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
// Sheet stepper button — used inside _VariantSheetContent
// ─────────────────────────────────────────────────────────────────────────────

class _SheetStepperBtn extends StatelessWidget {
  const _SheetStepperBtn({
    required this.label,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? pt.surface1 : Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black.withAlpha(isDark ? 40 : 14),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
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

// ─────────────────────────────────────────────────────────────────────────────
// Icon button helper (hero overlay buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.bg});

  final IconData icon;
  final VoidCallback onTap;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg ?? AppColors.surface0,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: const Color(0x0F0B1220),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: AppColors.ink700),
        ),
      ),
    );
  }
}
