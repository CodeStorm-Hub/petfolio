

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/platform/web_image_cache.dart';
import '../../../../core/theme/app_colors.dart';
import 'marketplace_categories_screen.dart';
import 'shop_intro_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/services/currency_formatter.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/product_list_controller.dart';
import '../controllers/shop_list_controller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widgets/product_glyph.dart';
import '../widgets/marketplace_state_views.dart';
import '../widgets/web_checkout_resume_listener.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../widgets/address_sheet.dart';



// ─────────────────────────────────────────────────────────────────────────────
// FlyToCart Animation Layer
// ─────────────────────────────────────────────────────────────────────────────

class FlyToCartItem {
  FlyToCartItem({
    required this.id,
    required this.rect,
    required this.product,
  });
  final String id;
  final Rect rect;
  final Product product;
}

// ─────────────────────────────────────────────────────────────────────────────
// MarketplaceScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Width at which the wide-layout body (and the fly-to-cart animation's
/// landing point) is centered and constrained.
const _kWideLayoutMaxWidth = 840.0;

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> with TickerProviderStateMixin {
  final List<FlyToCartItem> _flyingItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) _handleStripeCancelQuery();
      _maybeShowIntro();
    });
  }

  Future<void> _maybeShowIntro() async {
    if (!mounted) return;
    final should = await ShopIntroScreen.shouldShow();
    if (should && mounted) {
      await ShopIntroSheet.show(context);
    }
  }

  void _handleStripeCancelQuery() {
    if (!mounted) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['stripe'] != 'cancel') return;
    final orderId = ref.read(checkoutProvider).orderId;
    if (orderId != null) {
      ref.read(orderRepositoryProvider).cancelOrder(orderId).ignore();
    }
    ref.read(checkoutProvider.notifier).reset();
    context.go('/marketplace');
    AppSnackBar.showError('Checkout cancelled');
  }

  void _addToCart(Product product, Rect? fromRect) {
    ref.read(cartProvider.notifier).add(product);
    if (fromRect != null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _flyingItems.add(FlyToCartItem(id: id, rect: fromRect, product: product));
      });
      Future.delayed(const Duration(milliseconds: 850), () {
        if (mounted) {
          setState(() {
            _flyingItems.removeWhere((e) => e.id == id);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final selectedCat = ref.watch(selectedCategoryProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => context.go('/home'),
      child: WebCheckoutResumeListener(
      child: Scaffold(
        backgroundColor: pt.surface1,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= ResponsiveLayout.mobileMax;
                Widget body = Column(
                  children: [
                    const _MarketHeader(),
                    _CategoryChips(
                      selected: selectedCat,
                      onSelected: (cat) =>
                          ref.read(selectedCategoryProvider.notifier).select(cat),
                    ),
                    Expanded(
                      child: _ShopBody(
                        selectedCat: selectedCat,
                        onProductTap: (p) =>
                            context.push('/marketplace/product/${p.id}', extra: p),
                        onAdd: _addToCart,
                      ),
                    ),
                  ],
                );
                if (isWide) {
                  body = Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _kWideLayoutMaxWidth),
                      child: body,
                    ),
                  );
                }
                return body;
              },
            ),
            ..._flyingItems.map((item) {
              return _FlyToCartAnim(
                key: ValueKey(item.id),
                item: item,
              );
            }),
          ],
        ),
      ),
      ),
    );
  }
}

class _FlyToCartAnim extends StatefulWidget {
  const _FlyToCartAnim({super.key, required this.item});
  final FlyToCartItem item;

  @override
  State<_FlyToCartAnim> createState() => _FlyToCartAnimState();
}

class _FlyToCartAnimState extends State<_FlyToCartAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<double>? _xAnim;
  Animation<double>? _yAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 30),
    ]).animate(_ctrl);
    
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      // Mirrors the wide-layout centering in MarketplaceScreen.build: once the
      // screen is wide enough, the body is centered in a _kWideLayoutMaxWidth
      // column, so the cart icon sits at that column's right edge, not the
      // screen's right edge.
      final endX = screenWidth >= ResponsiveLayout.mobileMax
          ? (screenWidth + _kWideLayoutMaxWidth) / 2 - 40
          : screenWidth - 40;

      _xAnim = Tween<double>(begin: widget.item.rect.center.dx - 24, end: endX).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubicEmphasized),
      );
      _yAnim = Tween<double>(begin: widget.item.rect.center.dy - 24, end: 50).animate(
        CurvedAnimation(parent: _ctrl, curve: const Cubic(0.5, -0.2, 0.8, 0.3)),
      );

      _initialized = true;
      _ctrl.forward();
    }
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: _xAnim!.value,
          top: _yAnim!.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.item.product.gradientStart,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: widget.item.product.gradientStart.withAlpha(128), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 12))],
                ),
                alignment: Alignment.center,
                child: widget.item.product.imageUrls.isNotEmpty 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.item.product.imageUrls.first,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        memCacheWidth: networkImageMemCacheWidth(
                          context,
                          48,
                          maxPixels: webNetworkImageMemCacheThumb,
                        ),
                        memCacheHeight: networkImageMemCacheWidth(
                          context,
                          48,
                          maxPixels: webNetworkImageMemCacheThumb,
                        ),
                      ),
                    )
                  : const Text('🦴', style: TextStyle(fontSize: 26)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _MarketHeader extends ConsumerWidget {
  const _MarketHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 76.0),
          const SizedBox(height: 16),
          _SearchBar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PfSearchAppBar(
      hintText: 'Search treats, beds, toys…',
      onQueryChanged: (v) =>
          ref.read(marketplaceSearchQueryProvider.notifier).set(v),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryModel {
  const _CategoryModel(this.id, this.label, this.emoji, this.color);
  final ProductCategory id;
  final String label;
  final String emoji;
  final Color color;
}

const _cats = [
  _CategoryModel(ProductCategory.food, 'Food', '🍖', AppColors.tangerine),
  _CategoryModel(ProductCategory.treats, 'Treats', '🦴', AppColors.sunny),
  _CategoryModel(ProductCategory.toys, 'Toys', '🎾', AppColors.mint),
  _CategoryModel(ProductCategory.beds,    'Beds',    '🛏️', AppColors.poppy),
  _CategoryModel(ProductCategory.apparel, 'Apparel', '🧶', AppColors.lilac),
  _CategoryModel(ProductCategory.grooming, 'Grooming', '🛁', AppColors.sky),
];

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});
  final ProductCategory selected;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      height: 112,
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == _cats.length) {
            return Semantics(
              label: 'All categories',
              button: true,
              child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                MarketplaceCategoriesSheet.show(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Color.lerp(pt.ink950, Theme.of(context).colorScheme.surface, 0.88),
                      border: Border.all(color: pt.line, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⊞', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
            ),
            );
          }
          final cat = _cats[i];
          final isActive = cat.id == selected;
          return Semantics(
            label: '${cat.label}${isActive ? ", selected" : ""}',
            button: true,
            child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(isActive ? ProductCategory.all : cat.id);
            },
            child: AnimatedScale(
              scale: isActive ? 1.07 : 1.0,
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: isActive
                          ? Color.lerp(cat.color, Theme.of(context).colorScheme.surface, 0.62)
                          : Color.lerp(cat.color, Theme.of(context).colorScheme.surface, 0.82),
                      border: Border.all(
                        color: isActive ? cat.color : pt.line,
                        width: isActive ? 2.0 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: cat.color.withAlpha(55), blurRadius: 14, offset: const Offset(0, 5), spreadRadius: -3)]
                          : const [BoxShadow(color: AppColors.shadowE1L, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    alignment: Alignment.center,
                    child: Text(cat.emoji, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? cat.color : pt.ink950,
                    ),
                    child: Text(cat.label),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop Body
// ─────────────────────────────────────────────────────────────────────────────

class _ShopBody extends ConsumerStatefulWidget {
  const _ShopBody({
    required this.selectedCat,
    required this.onProductTap,
    required this.onAdd,
  });

  final ProductCategory selectedCat;
  final ValueChanged<Product> onProductTap;
  final Function(Product, Rect?) onAdd;

  @override
  ConsumerState<_ShopBody> createState() => _ShopBodyState();
}

class _ShopBodyState extends ConsumerState<_ShopBody> {
  late final ScrollController _scrollController;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients || _loadingMore) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 400) return;

    final notifier = ref.read(productListProvider.notifier);
    if (!notifier.hasMore) return;

    setState(() => _loadingMore = true);
    await notifier.loadMore();
    if (mounted) setState(() => _loadingMore = false);
  }

  int _crossAxisCount(double maxWidth) {
    if (maxWidth >= ResponsiveLayout.tabletMax) return 4;
    if (maxWidth >= ResponsiveLayout.mobileMax) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Object?>(productLoadMoreErrorProvider, (_, err) {
      if (err == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => ref.read(productListProvider.notifier).loadMore(),
          ),
        ),
      );
    });
    return LayoutBuilder(
      builder: (context, constraints) => _buildBody(context, constraints.maxWidth),
    );
  }

  Widget _buildBody(BuildContext context, double maxWidth) {
    final productsAsync = ref.watch(productListProvider);
    final cols = _crossAxisCount(maxWidth);

    return productsAsync.when(
      loading: () => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => SkeletonLoader.productCard(key: ValueKey('shop-skel-$i')),
                childCount: 4,
              ),
            ),
          ),
        ],
      ),
      error: (_, _) => MarketplaceErrorView(
        message: 'Could not load products',
        onRetry: () => ref.invalidate(productListProvider),
      ),
      data: (_) {
        final filtered = ref.watch(filteredProductsProvider(widget.selectedCat));
        final query = ref.watch(marketplaceSearchQueryProvider).trim();

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (widget.selectedCat == ProductCategory.all)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(11, 8, 11, 0),
                  child: RepaintBoundary(child: _HeroCarousel()),
                ),
              ),
            if (widget.selectedCat == ProductCategory.all)
              const _DeliveryStrip(),

            if (widget.selectedCat == ProductCategory.all)
              _YoullLoveSection(
                allProducts: ref.watch(productListProvider).value ?? [],
                onTap: widget.onProductTap,
                onAdd: widget.onAdd,
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.selectedCat == ProductCategory.all
                            ? 'Trending in your pack'
                            : widget.selectedCat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .extension<PetfolioThemeExtension>()!
                              .ink950,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${filtered.length}+ items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .extension<PetfolioThemeExtension>()!
                            .ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (filtered.isEmpty && query.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoResultsState(query: query),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.64,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => RepaintBoundary(
                    child: _NewProductTile(
                      product: filtered[i],
                      onTap: () => widget.onProductTap(filtered[i]),
                      onAdd: widget.onAdd,
                    ),
                  ),
                ),
              ),
            if (_loadingMore && filtered.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Products you'll love" discovery section
// ─────────────────────────────────────────────────────────────────────────────

class _YoullLoveSection extends StatelessWidget {
  const _YoullLoveSection({
    required this.allProducts,
    required this.onTap,
    required this.onAdd,
  });

  final List<Product> allProducts;
  final ValueChanged<Product> onTap;
  final Function(Product, Rect?) onAdd;

  List<Product> _pick(List<Product> all) {
    if (all.isEmpty) return [];
    final byCategory = <ProductCategory, List<Product>>{};
    for (final p in all) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }
    final result = <Product>[];
    final cats = byCategory.keys.toList();
    for (var i = 0; i < cats.length && result.length < 8; i++) {
      final bucket = byCategory[cats[i]]!;
      result.add(bucket[i % bucket.length]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final picks = _pick(allProducts);
    if (picks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products you\'ll love',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: pt.ink950,
                        ),
                      ),
                      Text(
                        'Curated picks across all categories',
                        style: TextStyle(fontSize: 12, color: pt.ink500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => MarketplaceCategoriesSheet.show(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.poppy,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Browse all ›'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: picks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _YoullLoveTile(
                product: picks[i],
                onTap: () => onTap(picks[i]),
                onAdd: onAdd,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _YoullLoveTile extends StatelessWidget {
  const _YoullLoveTile({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final Function(Product, Rect?) onAdd;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = product.priceFormatted;

    return Semantics(
      label: product.name,
      hint: 'View product',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? pt.surface2 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowE1L, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      product.gradientStart.withAlpha(isDark ? 80 : 50),
                      product.gradientEnd.withAlpha(isDark ? 40 : 25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 110,
                        placeholder: (_, _) =>
                            ProductGlyph(glyphType: product.glyphType, size: 52),
                        errorWidget: (_, _, _) =>
                            ProductGlyph(glyphType: product.glyphType, size: 52),
                      )
                    : ProductGlyph(glyphType: product.glyphType, size: 52),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.poppy,
                        ),
                      ),
                      Semantics(
                        label: 'Add ${product.name} to cart',
                        button: true,
                        child: GestureDetector(
                        onTap: () => onAdd(product, null),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.poppy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Carousel — auto-scrolling promo slides with dot indicator
// ─────────────────────────────────────────────────────────────────────────────

typedef _Slide = ({
  String eyebrow,
  String title,
  String sub,
  String emoji,
  Color gradStart,
  Color gradEnd,
});

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late final PageController _pageCtrl;
  int _currentPage = 0;
  Timer? _timer;

  static const List<_Slide> _slides = [
    (
      eyebrow: 'MEMBERS ONLY',
      title: '20% off all\ntreats this week',
      sub: 'Limited time',
      emoji: '🦴',
      gradStart: AppColors.poppy,
      gradEnd: AppColors.tangerine,
    ),
    (
      eyebrow: 'NEW ARRIVALS',
      title: 'Premium beds\nfor every pet',
      sub: 'Comfort redefined',
      emoji: '🛏️',
      gradStart: AppColors.sky,
      gradEnd: AppColors.lilac,
    ),
    (
      eyebrow: 'FLASH SALE',
      title: 'Toys up to\n40% off today',
      sub: 'Limited stock',
      emoji: '🎾',
      gradStart: AppColors.mint,
      gradEnd: AppColors.sky,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 164,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _PromoCard(slide: _slides[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageCtrl,
          count: _slides.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppColors.tangerine,
            dotColor: AppColors.line,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
            spacing: 6,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [slide.gradStart, slide.gradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: slide.gradStart.withAlpha(85),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background watermark emoji
          Positioned(
            right: -18,
            top: -14,
            child: Opacity(
              opacity: 0.18,
              child: Text(slide.emoji, style: const TextStyle(fontSize: 110)),
            ),
          ),
          // Foreground emoji illustration (right side, slight tilt)
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.18,
                child: Text(slide.emoji, style: const TextStyle(fontSize: 76)),
              ),
            ),
          ),
          // Text content (left side, avoids emoji area)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 110, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.eyebrow,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.title,
                  style: GoogleFonts.sora(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Shop Now →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: slide.gradStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProductTile extends StatefulWidget {
  const _NewProductTile({required this.product, required this.onTap, required this.onAdd});
  final Product product;
  final VoidCallback onTap;
  final Function(Product, Rect?) onAdd;

  @override
  State<_NewProductTile> createState() => _NewProductTileState();
}

class _NewProductTileState extends State<_NewProductTile> {
  final GlobalKey _btnKey = GlobalKey();
  bool _popping = false;

  void _handleAdd() {
    final box = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box?.localToGlobal(Offset.zero) != null ? box!.localToGlobal(Offset.zero) & box.size : null;
    widget.onAdd(widget.product, rect);
    
    setState(() => _popping = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _popping = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHot = widget.product.rating != null && widget.product.rating! >= 4.5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? pt.surface2 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: isDark ? Border.all(color: Colors.white.withAlpha(12)) : null,
            boxShadow: isDark
                ? [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 14, offset: const Offset(0, 4), spreadRadius: -2)]
                : [
                    const BoxShadow(color: AppColors.shadowE3L, blurRadius: 18, offset: Offset(0, 6), spreadRadius: -3),
                    BoxShadow(color: widget.product.gradientStart.withAlpha(18), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image area ────────────────────────────────────────────
              SizedBox(
                height: 130,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(widget.product.gradientStart, Colors.white, isDark ? 0.2 : 0.72)!,
                        Color.lerp(widget.product.gradientStart, Colors.white, isDark ? 0.05 : 0.38)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Product image
                      Center(
                        child: AnimatedScale(
                          scale: _popping ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.elasticOut,
                          child: widget.product.imageUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.product.imageUrls.first,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  cacheManager: petfolioWebImageCacheManager(),
                                  memCacheWidth: networkImageMemCacheWidth(
                                    context,
                                    100,
                                    maxPixels: webNetworkImageMemCacheThumb,
                                  ),
                                )
                              : const Text('🦴', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                      // Rating pill — top left
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? pt.surface2 : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: AppColors.sunny),
                              const SizedBox(width: 3),
                              Text(
                                widget.product.rating != null ? widget.product.rating!.toStringAsFixed(1) : '—',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pt.ink950),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // HOT badge — top right (high-rated products only)
                      if (isHot)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.poppy,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '🔥 HOT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Product info ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pt.ink950, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.product.brand,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pt.ink500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.product.priceFormatted,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pt.ink950),
                          ),
                          const Spacer(),
                          Semantics(
                            label: 'Add ${widget.product.name} to cart',
                            button: true,
                            child: GestureDetector(
                            key: ValueKey<String>('marketplace_add_${widget.product.id}'),
                            onTap: _handleAdd,
                            child: AnimatedScale(
                              scale: _popping ? 1.18 : 1.0,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.elasticOut,
                              child: Container(
                                key: _btnKey,
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: widget.product.gradientStart,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.product.gradientStart.withAlpha(90),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No-results empty state
// ─────────────────────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return MarketplaceEmptyView(
      icon: Icons.search_off_rounded,
      title: 'No results for "$query"',
      message: 'Try a different keyword or browse categories',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Drawer
// ─────────────────────────────────────────────────────────────────────────────

const _petfolioOfficialShopId = 'cccccccc-0000-0000-0000-cccccccccccc';

class CartDrawer extends ConsumerStatefulWidget {
  const CartDrawer({super.key});

  @override
  ConsumerState<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends ConsumerState<CartDrawer> {
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final shopsAsync = ref.watch(shopListProvider);
    final verifiedShopIds = shopsAsync.value?.map((s) => s.id).toSet() ?? {};

    ref.listen(checkoutProvider, (prev, next) {
      if (next.status == CheckoutStatus.success && next.orderId != null) {
        Navigator.pop(context);
        context.pushReplacement('/marketplace/order/${next.orderId}');
        ref.read(checkoutProvider.notifier).reset();
      }
      if (next.status == CheckoutStatus.failure && next.errorMessage != null) {
        AppSnackBar.showError(next.errorMessage!);
        ref.read(checkoutProvider.notifier).reset();
      }
    });

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ink950 = pt.ink950;
    final ink500 = pt.ink500;
    final surface = pt.surface1;
    final bg = pt.surface1;

    final items = cart.items.toList();
    final subtotal = cart.totalCents / 100;
    final shipping = items.isNotEmpty ? 4.50 : 0.0;
    final total = subtotal + shipping;
    final shopGroups = cart.itemsByShop.entries.toList();
    final checkoutShopId = shopGroups.length == 1 ? shopGroups.first.key : null;
    final canCheckout = checkoutShopId != null &&
        (checkoutShopId == _petfolioOfficialShopId ||
            verifiedShopIds.contains(checkoutShopId));
    final isLoading =
        checkoutShopId != null && checkout.isLoadingShop(checkoutShopId);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: const [BoxShadow(color: AppColors.shadowGlassL, blurRadius: 40, offset: Offset(0, -20), spreadRadius: -10)],
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Column(
        children: [
          Container(width: 48, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: pt.line, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your basket', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: ink950)),
                      Text('${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · ships to Brooklyn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink500)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: surface),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      Text('Cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink950)),
                      Text('Tap a paw + to add treats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink500)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    ...items.map((it) => _CartItemRow(item: it)),
                    
                    // Suggested add-on
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.sunnySoft, surface]),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.sunny, width: 2), // dashed in react, solid here for simplicity
                      ),
                      child: Row(
                        children: [
                          const Text('🦴', style: TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add a treat for \$4 more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink950)),
                                Text('Unlock free shipping', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.sunny, borderRadius: BorderRadius.circular(999)),
                            child: Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink950)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
          
          if (items.isNotEmpty && shopGroups.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Items from ${shopGroups.length} shops — each ships separately.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pt.ink700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: pt.line))),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Shipping', value: '\$${shipping.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Total', value: '\$${total.toStringAsFixed(2)}', big: true),
                  
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey<String>('marketplace_cart_checkout'),
                    onPressed: shopGroups.length > 1
                        ? () {
                            Navigator.pop(context);
                            context.push('/marketplace/cart');
                          }
                        : !canCheckout || isLoading
                            ? null
                            : () => ref
                                .read(checkoutProvider.notifier)
                                .startCheckoutForShop(checkoutShopId),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                shopGroups.length > 1
                                    ? 'Checkout by shop'
                                    : 'Checkout · \$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '🐾 Earn '),
                        TextSpan(text: '+${(total * 4).floor()} XP', style: const TextStyle(color: AppColors.tangerine700)),
                        const TextSpan(text: ' when you check out'),
                      ],
                    ),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.big = false});
  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: big ? 16 : 13, fontWeight: big ? FontWeight.w700 : FontWeight.w700, color: big ? pt.ink950 : pt.ink700)),
        Text(value, style: TextStyle(fontSize: big ? 18 : 13, fontWeight: big ? FontWeight.w700 : FontWeight.w700, color: big ? pt.ink950 : pt.ink700)),
      ],
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pt.line),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(item.product.gradientStart, Colors.white, 0.7)!, item.product.gradientStart],
              ),
            ),
            alignment: Alignment.center,
            child: item.product.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.product.imageUrls.first,
                  fit: BoxFit.cover,
                  width: 40,
                  memCacheWidth: networkImageMemCacheWidth(
                    context,
                    40,
                    maxPixels: webNetworkImageMemCacheThumb,
                  ),
                  memCacheHeight: networkImageMemCacheWidth(
                    context,
                    40,
                    maxPixels: webNetworkImageMemCacheThumb,
                  ),
                )
              : const Text('🦴', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: pt.ink950)),
                Text(item.product.brand, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pt.ink500)),
                const SizedBox(height: 2),
                Text(formatCents(item.product.priceCents * item.quantity), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pt.ink950)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: pt.surface2, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                Semantics(
                  label: 'Decrease quantity',
                  button: true,
                  child: GestureDetector(
                    onTap: () => ref.read(cartProvider.notifier).decrement(
                          item.product.id,
                          isSubscribed: item.isSubscribed,
                          variantId: item.variantId,
                        ),
                    child: Container(width: 26, height: 26, decoration: BoxDecoration(color: pt.surface1, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('−', style: TextStyle(fontWeight: FontWeight.w700))),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  alignment: Alignment.center,
                  child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                Semantics(
                  label: 'Increase quantity',
                  button: true,
                  child: GestureDetector(
                    onTap: () => ref.read(cartProvider.notifier).add(
                          item.product,
                          subscribe: item.isSubscribed,
                          frequencyWeeks: item.frequencyWeeks,
                          variantId: item.variantId,
                        ),
                    child: Container(width: 26, height: 26, decoration: BoxDecoration(color: pt.surface1, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('+', style: TextStyle(fontWeight: FontWeight.w700))),
                  ),
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
// Delivery strip
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryStrip extends ConsumerWidget {
  const _DeliveryStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt   = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final pet  = ref.watch(activePetControllerProvider);
    final name = pet?.name ?? 'your pet';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: pt.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pt.line),
        ),
        child: Row(
          children: [
            Icon(Icons.local_shipping_rounded, size: 18, color: pt.ink500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'SHIP TO ${name.toUpperCase()}\'S ADDRESS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pt.ink950, letterSpacing: 0.3),
              ),
            ),
            Semantics(
              label: 'Set delivery address',
              button: true,
              child: GestureDetector(
                onTap: () => AddressSheet.show(context),
                child: const Text(
                  'Set address',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tangerine),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
