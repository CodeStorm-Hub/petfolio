import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/product.dart';
import '../../data/models/product_variant.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../controllers/product_variant_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../widgets/product_glyph.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/subscription_toggle.dart';

class _SheetResult {
  const _SheetResult(this.qty, {this.variantId, this.variantPrice});
  final int qty;
  final String? variantId;
  final int? variantPrice;
}

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
  String? _selectedVariantId;
  int? _selectedVariantPrice;

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

  void _handleAddToCart() {
    final p = _product;
    if (p == null) return;
    HapticFeedback.selectionClick();
    setState(() => _popping = true);
    ref.read(cartProvider.notifier).add(
      p,
      subscribe: false,
      frequencyWeeks: _frequencyWeeks,
      variantId: _selectedVariantId,
      overridePriceCents: _selectedVariantPrice,
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _popping = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart 🛒'),
        backgroundColor: AppColors.mint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBuyNow() {
    final p = _product;
    if (p == null) return;
    showModalBottomSheet<_SheetResult?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantSheetContent(
        product: p,
        subscribe: _subscribe,
        frequencyWeeks: _frequencyWeeks,
      ),
    ).then((result) {
      if (result == null || result.qty <= 0 || !mounted) return;
      setState(() => _popping = true);
      for (var i = 0; i < result.qty; i++) {
        Future.delayed(Duration(milliseconds: i * 90), () {
          ref.read(cartProvider.notifier).add(
            p,
            subscribe: _subscribe,
            frequencyWeeks: _frequencyWeeks,
            variantId: result.variantId,
            overridePriceCents: result.variantPrice,
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
    final isWishlisted = ref.watch(isWishlistedProvider(product.id)).value ?? false;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : pt.surface2,
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
                  isWishlisted: isWishlisted,
                  onWishlistTap: () =>
                      ref.read(wishlistItemsProvider.notifier).toggle(product.id),
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

              // ── Variant chips ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _VariantChipsSection(
                    productId: product.id,
                    selectedVariantId: _selectedVariantId,
                    onSelected: (id, price) => setState(() {
                      _selectedVariantId = id;
                      _selectedVariantPrice = price;
                    }),
                  ),
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
    required this.isWishlisted,
    required this.onWishlistTap,
  });

  final Product product;
  final int cartCount;
  final bool popping;
  final PageController pageCtrl;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final bool isWishlisted;
  final VoidCallback onWishlistTap;

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
                        errorWidget: (_, _, _) => Semantics(
                            label: 'Product image unavailable',
                            child: Center(child: ProductGlyph(glyphType: product.glyphType, size: 160)),
                          ),
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
                  tooltip: 'Back',
                  bg: Colors.white.withAlpha(235),
                  onTap: () => context.pop(),
                ),
                Row(
                  children: [
                    _IconBtn(
                      icon: isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      tooltip: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                      bg: Colors.white.withAlpha(235),
                      iconColor: isWishlisted ? AppColors.poppy : null,
                      onTap: onWishlistTap,
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _IconBtn(
                          icon: Icons.shopping_cart_outlined,
                          tooltip: 'View cart',
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
                                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
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
                    fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  if (product.reviewCount != null && product.reviewCount! > 0)
                    Text(
                      ' · ${product.reviewCount} review${product.reviewCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.sunny700,
                        fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: pt.ink500,
          ),
        ),
        const SizedBox(height: 4),

        // ── Product name ──────────────────────────────────────────────────
        Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: subscribe ? pt.mintSoft : cs.surface,
        border: Border.all(color: subscribe ? pt.success : pt.line),
        boxShadow: pt.shadowE1,
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
                  color: subscribe ? pt.success : pt.surface2,
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 24,
                  color: subscribe ? Colors.white : pt.ink500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subscribe & Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: pt.ink950,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: pt.success.withAlpha(26),
                          ),
                          child: Text(
                            'Save 12%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pt.success,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: pt.ink500,
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
                  Text(
                    'DELIVERY FREQUENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.88,
                      color: pt.ink500,
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
                    fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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

class _VariantChipsSection extends ConsumerWidget {
  const _VariantChipsSection({
    required this.productId,
    required this.selectedVariantId,
    required this.onSelected,
  });

  final String productId;
  final String? selectedVariantId;
  final void Function(String variantId, int priceCents) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productVariantsProvider(productId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (variants) {
        if (variants.isEmpty) return const SizedBox.shrink();
        final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
        final cs = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VARIANTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: variants.map((v) {
                  final selected = v.id == selectedVariantId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      label: '${v.attributeLabel}, ${v.priceFormatted}',
                      selected: selected,
                      button: true,
                      child: GestureDetector(
                      onTap: () => onSelected(v.id, v.priceCents),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selected
                              ? pt.success.withAlpha(30)
                              : cs.surface,
                          border: Border.all(
                            color: selected ? pt.success : pt.line,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.attributeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? pt.success
                                    : pt.ink700,
                              ),
                            ),
                            Text(
                              v.priceFormatted,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? pt.success
                                    : pt.ink500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VariantSheetContent extends ConsumerStatefulWidget {
  const _VariantSheetContent({
    required this.product,
    required this.subscribe,
    required this.frequencyWeeks,
  });

  final Product product;
  final bool subscribe;
  final int frequencyWeeks;

  @override
  ConsumerState<_VariantSheetContent> createState() =>
      _VariantSheetContentState();
}

class _VariantSheetContentState extends ConsumerState<_VariantSheetContent> {
  int _qty = 1;
  String? _selectedVariantId;
  int? _selectedVariantPrice;

  int get _unitCents {
    if (_selectedVariantPrice != null) {
      return widget.subscribe && widget.product.subscribable
          ? (_selectedVariantPrice! * 0.88).round()
          : _selectedVariantPrice!;
    }
    return widget.subscribe && widget.product.subscribable
        ? widget.product.subPriceCents
        : widget.product.priceCents;
  }

  int get _totalCents => _unitCents * _qty;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final showDiscount = widget.subscribe && product.subscribable;
    final variantsAsync = ref.watch(productVariantsProvider(product.id));

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
                        fontWeight: FontWeight.w700,
                        color: pt.ink950,
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Close',
                    button: true,
                    child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark ? pt.surface2 : pt.surface1,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close_rounded, size: 16, color: pt.ink500),
                    ),
                  ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: pt.line),

            // ── Variant rows ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: variantsAsync.when(
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (variants) {
                  final options = variants.isEmpty
                      ? <_VariantOption>[
                          _VariantOption(
                            id: null,
                            label: product.variant.isNotEmpty
                                ? product.variant
                                : 'Standard',
                            priceCents: widget.subscribe && product.subscribable
                                ? product.subPriceCents
                                : product.priceCents,
                          ),
                        ]
                      : variants
                          .map((v) => _VariantOption(
                                id: v.id,
                                label: v.attributeLabel,
                                priceCents: v.priceCents,
                              ))
                          .toList();

                  return Column(
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
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mint.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COMPLETE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mint700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...options.map((opt) {
                        final isSelected = _selectedVariantId == null
                            ? opt.id == null
                            : _selectedVariantId == opt.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            label: opt.label,
                            selected: isSelected,
                            button: true,
                            child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedVariantId = opt.id;
                              _selectedVariantPrice =
                                  opt.id != null ? opt.priceCents : null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? pt.surface2
                                    : pt.surface1,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.mint
                                      : pt.line,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.mint
                                            : pt.line2,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.mint,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opt.label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: pt.ink950,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${(opt.priceCents / 100).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.mint700
                                          : pt.ink500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
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
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: isDark ? pt.surface2 : pt.surface1,
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
                              fontWeight: FontWeight.w700,
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
                    Navigator.of(context).pop(
                      _SheetResult(
                        _qty,
                        variantId: _selectedVariantId,
                        variantPrice: _selectedVariantPrice,
                      ),
                    );
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
                          fontWeight: FontWeight.w700,
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
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

class _VariantOption {
  const _VariantOption({
    required this.id,
    required this.label,
    required this.priceCents,
  });
  final String? id;
  final String label;
  final int priceCents;
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
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? pt.surface1 : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 14),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: pt.ink950,
            height: 1.1,
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
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.bg,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? bg;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg ?? AppColors.surface0,
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowE2L,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: iconColor ?? AppColors.ink700),
        ),
      ),
    );
  }
}
