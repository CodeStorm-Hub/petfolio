import '../../../../core/theme/app_colors.dart';


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';

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

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> with TickerProviderStateMixin {
  ProductCategory _selectedCat = ProductCategory.all;
  final List<FlyToCartItem> _flyingItems = [];


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

  void _openCart() {
    context.push('/marketplace/cart'); // Fallback or we can implement the drawer
    // We can also implement a BottomSheet here instead of pushing route,
    // but PetFolio already has a cart route. The instructions say "CartDrawer modal bottom sheet".
    _showCartDrawer();
  }
  
  void _showCartDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CartDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _MarketHeader(onCart: _openCart),
                _CategoryChips(
                  selected: _selectedCat,
                  onSelected: (cat) => setState(() => _selectedCat = cat),
                ),
                Expanded(
                  child: _ShopBody(
                    selectedCat: _selectedCat,
                    onProductTap: (p) => context.push('/marketplace/product/${p.id}', extra: p),
                    onAdd: _addToCart,
                  ),
                ),
              ],
            ),
          ),
          
          // Fly to cart overlay
          ..._flyingItems.map((item) {
            return _FlyToCartAnim(
              key: ValueKey(item.id),
              item: item,
            );
          }),
        ],
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
  late final Animation<double> _xAnim;
  late final Animation<double> _yAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    // Animate from item rect to top right (approx x: 340, y: 50)
    _xAnim = Tween<double>(begin: widget.item.rect.center.dx - 24, end: 340).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _yAnim = Tween<double>(begin: widget.item.rect.center.dy - 24, end: 50).animate(CurvedAnimation(parent: _ctrl, curve: const Cubic(0.5, -0.2, 0.8, 0.3)));
    
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 30),
    ]).animate(_ctrl);
    
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _ctrl.forward();
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: _xAnim.value,
          top: _yAnim.value,
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
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: widget.item.product.imageUrls.first, fit: BoxFit.cover, width: 48, height: 48))
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
  const _MarketHeader({required this.onCart});
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [AppColors.sunnySoft.withAlpha(40), AppColors.surface1D]
            : [AppColors.sunnySoft, const Color(0xFFFFFFFF)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SHIP TO MOCHI\'S HOUSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.6)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.tangerine),
                      const SizedBox(width: 4),
                      Text('Brooklyn, NY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pt.ink950)),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: pt.ink950),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: onCart,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tangerine,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.tangerine700, offset: Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.poppy,
                              shape: BoxShape.circle,
                              border: Border.all(color: pt.cream, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(cart.itemCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SearchBar(),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final hasText = ref.watch(marketplaceSearchQueryProvider.select((q) => q.isNotEmpty));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) => ref.read(marketplaceSearchQueryProvider.notifier).set(v),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pt.ink950),
              decoration: InputDecoration(
                hintText: 'Search treats, beds, toys…',
                hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(marketplaceSearchQueryProvider.notifier).clear();
              },
              child: Icon(Icons.close_rounded, size: 18, color: const Color(0xFF64748B)),
            ),
        ],
      ),
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

final _cats = [
  _CategoryModel(ProductCategory.food, 'Food', '🍖', AppColors.tangerine),
  _CategoryModel(ProductCategory.treats, 'Treats', '🦴', AppColors.sunny),
  _CategoryModel(ProductCategory.toys, 'Toys', '🎾', AppColors.mint),
  _CategoryModel(ProductCategory.gear, 'Beds', '🛏️', AppColors.poppy),
  _CategoryModel(ProductCategory.all, 'Apparel', '🧶', AppColors.lilac), // Reuse 'all' for Apparel demo
  _CategoryModel(ProductCategory.grooming, 'Grooming', '🛁', AppColors.sky),
];

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});
  final ProductCategory selected;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      height: 112,
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final isActive = cat.id == selected;
          return GestureDetector(
            onTap: () => onSelected(isActive ? ProductCategory.all : cat.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Color.lerp(cat.color, Theme.of(context).colorScheme.surface, 0.82),
                    border: Border.all(color: isActive ? cat.color : const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 6),
                Text(cat.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pt.ink950)),
              ],
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

class _ShopBody extends ConsumerWidget {
  const _ShopBody({
    required this.selectedCat,
    required this.onProductTap,
    required this.onAdd,
  });

  final ProductCategory selectedCat;
  final ValueChanged<Product> onProductTap;
  final Function(Product, Rect?) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return productsAsync.when(
      loading: () => const Center(child: TailWagLoader(label: 'Loading shop…')),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load products', style: TextStyle(color: const Color(0xFF64748B))),
            TextButton(onPressed: () => ref.invalidate(productListProvider), child: const Text('Retry')),
          ],
        ),
      ),
      data: (_) {
        final filtered = ref.watch(filteredProductsProvider(selectedCat));
        
        return CustomScrollView(
          slivers: [
            if (selectedCat == ProductCategory.all)
              const SliverToBoxAdapter(child: _HeroBanner()),
              
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedCat == ProductCategory.all ? 'Trending in your pack' : selectedCat.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950)),
                    Text('${filtered.length}+ items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink500)),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _NewProductTile(
                  product: filtered[i],
                  onTap: () => onProductTap(filtered[i]),
                  onAdd: onAdd,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pc.poppy, pc.tangerine],
          ),
          boxShadow: [BoxShadow(color: pc.poppy.withAlpha(128), blurRadius: 30, spreadRadius: -12, offset: const Offset(0, 14))],
        ),
        padding: const EdgeInsets.all(18),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.18,
                child: Text('🐾', style: TextStyle(fontSize: 50)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FOR MEMBERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      const Text('20% off treats\nthis week 🦴', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(999)),
                        child: Text('Claim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pc.poppy700)),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: Transform.rotate(
                    angle: -0.2, // -12 deg approx
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
                      ),
                      child: const Text('🦴', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(widget.product.gradientStart, Colors.white, 0.7)!,
                    Color.lerp(widget.product.gradientStart, Colors.white, 0.3)!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: AnimatedScale(
                      scale: _popping ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.elasticOut,
                      child: widget.product.imageUrls.isNotEmpty
                        ? CachedNetworkImage(imageUrl: widget.product.imageUrls.first, height: 100, fit: BoxFit.contain)
                        : const Text('🦴', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: pc.sunny),
                          const SizedBox(width: 3),
                          Text('4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pt.ink950)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pt.ink950, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(widget.product.brand, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${(widget.product.priceCents / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pt.ink950)),
                        GestureDetector(
                          key: _btnKey,
                          onTap: _handleAdd,
                          child: AnimatedScale(
                            scale: _popping ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.elasticOut,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: widget.product.gradientStart,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Color.lerp(widget.product.gradientStart, Colors.black, 0.5)!, offset: const Offset(0, 4))],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Drawer
// ─────────────────────────────────────────────────────────────────────────────

class _CartDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ink950 = pt.ink950;
    final ink500 = const Color(0xFF64748B);
    final surface = const Color(0xFFFFFFFF);
    final bg = const Color(0xFFFFFFFF);
    
    final items = cart.items.toList();
    final subtotal = cart.totalCents / 100;
    final shipping = items.isNotEmpty ? 4.50 : 0.0;
    final total = subtotal + shipping;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 40, offset: Offset(0, -20), spreadRadius: -10)],
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Column(
        children: [
          Container(width: 48, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your basket', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink950)),
                    Text('${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · ships to Brooklyn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink500)),
                  ],
                ),
                IconButton(
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
                      Text('Cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink950)),
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
                                Text('Add a treat for \$4 more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink950)),
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
          
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: const Color(0xFFE2E8F0)))),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Shipping', value: '\$${shipping.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Total', value: '\$${total.toStringAsFixed(2)}', big: true),
                  
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Checkout · \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '🐾 Earn '),
                        TextSpan(text: '+${(total * 4).floor()} XP', style: TextStyle(color: AppColors.tangerine700)),
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
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: big ? 16 : 13, fontWeight: big ? FontWeight.w800 : FontWeight.w700, color: big ? pt.ink950 : const Color(0xFF334155))),
        Text(value, style: TextStyle(fontSize: big ? 18 : 13, fontWeight: big ? FontWeight.w900 : FontWeight.w700, color: big ? pt.ink950 : const Color(0xFF334155))),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              ? CachedNetworkImage(imageUrl: item.product.imageUrls.first, fit: BoxFit.cover, width: 40)
              : const Text('🦴', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pt.ink950)),
                Text(item.product.brand, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text('\$${((item.product.priceCents * item.quantity) / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pt.ink950)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: pt.surface2, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).decrement(item.product.id),
                  child: Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFFFFFFFF), shape: BoxShape.circle), alignment: Alignment.center, child: const Text('−', style: TextStyle(fontWeight: FontWeight.w900))),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  alignment: Alignment.center,
                  child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).add(item.product),
                  child: Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFFFFFFFF), shape: BoxShape.circle), alignment: Alignment.center, child: const Text('+', style: TextStyle(fontWeight: FontWeight.w900))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
