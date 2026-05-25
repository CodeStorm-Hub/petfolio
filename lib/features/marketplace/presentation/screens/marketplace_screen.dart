import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/app_colors.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import 'package:petfolio/features/marketplace/data/models/product.dart';
import 'package:petfolio/features/marketplace/data/models/shop.dart';
import 'package:petfolio/features/admin/presentation/controllers/admin_auth_controller.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/cart_controller.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/product_list_controller.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/shop_list_controller.dart';
import 'package:petfolio/features/marketplace/presentation/widgets/product_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MarketplaceScreen — shop landing
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  ProductCategory _selectedCat = ProductCategory.all;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              pillar: PfPillar.market,
              eyebrow: 'Shop',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              actions: [
                if (isAdmin)
                  AppHeaderAction(
                    iconKey: const ValueKey<String>('market_action_admin'),
                    icon: Icons.admin_panel_settings_outlined,
                    tooltip: 'Admin',
                    onTap: () => context.push('/admin'),
                  ),
                AppHeaderAction(
                  iconKey: const ValueKey<String>('market_action_cart'),
                  icon: Icons.shopping_bag_outlined,
                  tooltip: 'Cart',
                  badge: cart.itemCount > 0 ? cart.itemCount : null,
                  onTap: () => context.push('/marketplace/cart'),
                ),
              ],
            ),
            _SearchBar(),
            _CategoryChips(
              selected: _selectedCat,
              onSelected: (cat) => setState(() => _selectedCat = cat),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _ErrorBody(
                  onRetry: () => ref.invalidate(productListProvider),
                ),
                data: (_) => _ShopBody(
                  selectedCat: _selectedCat,
                  onProductTap: (p) => context.push(
                    '/marketplace/product/${p.id}',
                    extra: p,
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
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = ref.watch(
      marketplaceSearchQueryProvider.select((q) => q.isNotEmpty),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SearchBar(
        controller: _controller,
        onChanged: (v) => ref.read(marketplaceSearchQueryProvider.notifier).set(v),
        hintText: 'Search food, gear, treats…',
        leading: const Icon(Icons.search_rounded),
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128)),
        trailing: [
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                ref.read(marketplaceSearchQueryProvider.notifier).clear();
              },
            )
          else
            const IconButton(
              icon: Icon(Icons.tune_rounded),
              onPressed: null,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chips
// ─────────────────────────────────────────────────────────────────────────────

const _cats = [
  ProductCategory.all,
  ProductCategory.food,
  ProductCategory.gear,
  ProductCategory.toys,
  ProductCategory.treats,
  ProductCategory.health,
  ProductCategory.grooming,
];

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final ProductCategory selected;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final active = cat == selected;
          return FilterChip(
            label: Text(cat.label),
            selected: active,
            onSelected: (_) => onSelected(cat),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop body
// ─────────────────────────────────────────────────────────────────────────────

class _ShopBody extends ConsumerWidget {
  const _ShopBody({
    required this.selectedCat,
    required this.onProductTap,
  });

  final ProductCategory selectedCat;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscribable = ref.watch(subscribableProductsProvider);
    final filtered = ref.watch(filteredProductsProvider(selectedCat));

    return CustomScrollView(
      slivers: [
        if (selectedCat == ProductCategory.all)
          const SliverToBoxAdapter(child: _DiscoverShopsSection()),
        // Reorder strip
        if (selectedCat == ProductCategory.all && subscribable.isNotEmpty)
          SliverToBoxAdapter(
            child: _ReorderStrip(
              product: subscribable.first,
              onTap: () => onProductTap(subscribable.first),
            ),
          ),

        // Subscribe & Save row
        if (selectedCat == ProductCategory.all && subscribable.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Subscribe & Save',
              subtitle: 'Recurring consumables · 12% off',
              accentColor: AppColors.meadow500,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                itemCount: subscribable.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductCardCompact(
                  product: subscribable[i],
                  onTap: () => onProductTap(subscribable[i]),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Top picks',
              subtitle: 'Curated weekly',
            ),
          ),
        ],

        // Category label when filtered
        if (selectedCat != ProductCategory.all)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    selectedCat.label,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.ink950,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${filtered.length} items',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Product grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: PetfolioBreakpoints.marketplaceGridColumns(
                MediaQuery.sizeOf(context).width,
              ),
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
              childAspectRatio: 0.62,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => ProductCard(
              product: filtered[i],
              onTap: () => onProductTap(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discover shops
// ─────────────────────────────────────────────────────────────────────────────

const _discoverShopsRowHeight = 100.0;

class _DiscoverShopsSection extends ConsumerWidget {
  const _DiscoverShopsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopListProvider);

    return shopsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: SizedBox(
          height: _discoverShopsRowHeight,
          child: Row(
            children: [
              SkeletonLoader(
                  width: 88, height: _discoverShopsRowHeight, borderRadius: 16),
              SizedBox(width: 10),
              SkeletonLoader(
                  width: 88, height: _discoverShopsRowHeight, borderRadius: 16),
              SizedBox(width: 10),
              SkeletonLoader(
                  width: 88, height: _discoverShopsRowHeight, borderRadius: 16),
            ],
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (shops) {
        if (shops.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Discover Shops',
              subtitle: 'Independent pet sellers',
            ),
            SizedBox(
              height: _discoverShopsRowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _ShopDiscoverCard(
                  shop: shops[i],
                  onTap: () => context.push('/shop/${shops[i].id}'),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class _ShopDiscoverCard extends StatelessWidget {
  const _ShopDiscoverCard({required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        height: _discoverShopsRowHeight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface0,
            boxShadow: const [
              BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  color: AppColors.surface2,
                  child: shop.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: shop.logoUrl!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          placeholder: (context, url) =>
                              const SizedBox.shrink(),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.ink500,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.ink500,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shop.shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                  color: AppColors.ink950,
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
// Reorder strip
// ─────────────────────────────────────────────────────────────────────────────

class _ReorderStrip extends StatelessWidget {
  const _ReorderStrip({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8FD0B0), AppColors.meadow500],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Icon(Icons.autorenew_rounded,
                    color: AppColors.meadow500, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RUNNING LOW · ARRIVING FRIDAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Subscription · 12% off · next in 5 days',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'Manage',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.meadow500,
                    ),
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
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (accentColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.18,
                  color: AppColors.ink950,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.ink500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load products',
              style: TextStyle(color: AppColors.ink500)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
