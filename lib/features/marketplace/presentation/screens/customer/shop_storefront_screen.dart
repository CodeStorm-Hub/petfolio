import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/shop_list_controller.dart';
import '../../controllers/shop_products_controller.dart';
import '../../../data/models/shop.dart';
import '../../widgets/product_card.dart';
import '../../../../../core/widgets/skeleton_loader.dart';

class ShopStorefrontRoute extends ConsumerWidget {
  const ShopStorefrontRoute({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(shopId));

    return shopAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface1,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 40, height: 40, borderRadius: 999),
                SizedBox(height: 16),
                SkeletonLoader(width: double.infinity, height: 120),
                SizedBox(height: 16),
                SkeletonLoader(width: 160, height: 20),
              ],
            ),
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AppColors.surface1,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Shop not found',
                    style: TextStyle(color: AppColors.ink500)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (shop) => ShopStorefrontScreen(shop: shop),
    );
  }
}

class ShopStorefrontScreen extends ConsumerWidget {
  const ShopStorefrontScreen({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shop.id));
    final cart = ref.watch(cartProvider);
    final cartCount = cart.itemsByShop[shop.id]?.fold<int>(
          0, (s, i) => s + i.quantity) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: shop.bannerUrl != null ? 160 : 80,
            backgroundColor: AppColors.surface0,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            actions: [
              if (cartCount > 0)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      _CircleBtn(
                        icon: Icons.shopping_bag_outlined,
                        onTap: () => context.push('/marketplace/cart'),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.coral500,
                          ),
                          child: Center(
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: shop.bannerUrl != null
                  ? Image.network(
                      shop.bannerUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.apricot500, AppColors.coral500],
                        ),
                      ),
                    ),
            ),
          ),

          // Shop header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surface2,
                      border: Border.all(
                          color: AppColors.line, width: 1.5),
                    ),
                    child: shop.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(shop.logoUrl!,
                                fit: BoxFit.cover),
                          )
                        : const Icon(Icons.storefront_outlined,
                            color: AppColors.ink300, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.ink950,
                          ),
                        ),
                        if (shop.description != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            shop.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.ink500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverToBoxAdapter(child: _ContactInfoSection(shop: shop)),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Text(
                'PRODUCTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.88,
                  color: AppColors.ink500,
                ),
              ),
            ),
          ),

          productsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorRetry(
                onRetry: () =>
                    ref.read(shopProductsProvider(shop.id).notifier).refresh(),
              ),
            ),
            data: (products) => products.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text('No products available',
                          style: TextStyle(color: AppColors.ink500)),
                    ),
                  )
                : SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 6, 16, 120),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => ProductCard(
                        product: products[i],
                        onTap: () => context.push(
                          '/marketplace/product/${products[i].id}',
                          extra: products[i],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoSection extends StatelessWidget {
  const _ContactInfoSection({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final hasEmail   = shop.businessEmail != null;
    final hasPhone   = shop.businessPhone != null;
    final hasAddress = shop.addressStreet != null || shop.addressCity != null;
    final hasSocial  = shop.socialLinks != null && shop.socialLinks!.isNotEmpty;

    if (!hasEmail && !hasPhone && !hasAddress && !hasSocial) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.line2, height: 20),
          if (hasEmail)
            _ContactRow(
              icon:  Icons.email_outlined,
              label: shop.businessEmail!,
              onTap: () => launchUrl(Uri.parse('mailto:${shop.businessEmail}')),
            ),
          if (hasPhone)
            _ContactRow(
              icon:  Icons.phone_outlined,
              label: shop.businessPhone!,
              onTap: () => launchUrl(Uri.parse('tel:${shop.businessPhone}')),
            ),
          if (hasAddress)
            _ContactRow(
              icon:  Icons.location_on_outlined,
              label: [
                shop.addressStreet,
                [shop.addressCity, shop.addressState]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join(', '),
                shop.addressZip,
              ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
              onTap: null,
            ),
          if (hasSocial) ...[
            const SizedBox(height: 8),
            _SocialLinksRow(links: shop.socialLinks!),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.ink500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall!.copyWith(color: AppColors.ink700),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}

class _SocialLinksRow extends StatelessWidget {
  const _SocialLinksRow({required this.links});
  final Map<String, dynamic> links;

  static const _meta = <String, IconData>{
    'website':   Icons.language,
    'instagram': Icons.camera_alt_outlined,
    'facebook':  Icons.facebook,
    'tiktok':    Icons.music_note,
    'youtube':   Icons.play_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final buttons = _meta.entries
        .where((e) =>
            links[e.key] is String &&
            (links[e.key] as String).trim().isNotEmpty)
        .map((e) => _SocialBtn(icon: e.value, url: links[e.key] as String))
        .toList();
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(children: buttons);
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.icon, required this.url});
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.blue500.withAlpha(20),
        ),
        child: Icon(icon, size: 18, color: AppColors.blue500),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

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
          PrimaryPillButton(
            label: 'Retry',
            size: PillButtonSize.md,
            variant: PillButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 16, color: AppColors.ink700),
      ),
    );
  }
}
