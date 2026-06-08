import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../controllers/product_list_controller.dart';

const _allCats = [
  _CatMeta(ProductCategory.food,     'Food',     '🍖', AppColors.tangerine),
  _CatMeta(ProductCategory.treats,   'Treats',   '🦴', AppColors.sunny),
  _CatMeta(ProductCategory.toys,     'Toys',     '🎾', AppColors.mint),
  _CatMeta(ProductCategory.beds,     'Beds',     '🛏️', AppColors.poppy),
  _CatMeta(ProductCategory.apparel,  'Apparel',  '🧶', AppColors.lilac),
  _CatMeta(ProductCategory.grooming, 'Grooming', '🛁', AppColors.sky),
  _CatMeta(ProductCategory.gear,     'Gear',     '🎒', AppColors.tangerine),
  _CatMeta(ProductCategory.health,   'Health',   '💊', AppColors.mint),
];

class _CatMeta {
  const _CatMeta(this.id, this.label, this.emoji, this.color);
  final ProductCategory id;
  final String label;
  final String emoji;
  final Color color;
}

class MarketplaceCategoriesScreen extends ConsumerWidget {
  const MarketplaceCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = ref.watch(selectedCategoryProvider);
    final allProducts = ref.watch(productListProvider).value ?? [];

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : const Color(0xFFF2F3F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: pt.ink950,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Browse Categories',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemCount: _allCats.length,
                itemBuilder: (_, i) {
                  final cat = _allCats[i];
                  final count = allProducts
                      .where((p) => p.category == cat.id)
                      .length;
                  final isActive = selected == cat.id;

                  return _CategoryTile(
                    cat: cat,
                    count: count,
                    isActive: isActive,
                    isDark: isDark,
                    pt: pt,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(selectedCategoryProvider.notifier)
                          .select(isActive ? ProductCategory.all : cat.id);
                      context.pop();
                    },
                  )
                      .animate(delay: Duration(milliseconds: 40 * i))
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 320.ms,
                        curve: Curves.easeOutCubic,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.count,
    required this.isActive,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final _CatMeta cat;
  final int count;
  final bool isActive;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? Color.lerp(cat.color, Colors.white, isDark ? 0.15 : 0.85)
              : (isDark ? pt.surface2 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cat.color : pt.line,
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: cat.color.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  )
                ]
              : const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color.lerp(cat.color, Colors.white, isDark ? 0.2 : 0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(cat.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isActive ? cat.color : pt.ink950,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    count > 0 ? '$count items' : 'Browse',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pt.ink500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isActive
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: isActive ? cat.color : pt.ink500,
            ),
          ],
        ),
      ),
    );
  }
}
