import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../marketplace/data/models/promo.dart';
import '../../../marketplace/presentation/controllers/promo_controller.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promosAsync = ref.watch(promoListProvider);
    final filter = ref.watch(promoFilterProvider);
    final filtered = ref.watch(filteredPromosProvider);

    const chips = [
      ('all', 'All'),
      ('food', 'Food'),
      ('grooming', 'Grooming'),
      ('health', 'Health'),
      ('toys', 'Toys'),
    ];

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : const Color(0xFFF2F3F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: pt.ink950,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offers',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chips.map((c) {
                    final active = filter == c.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(promoFilterProvider.notifier).setFilter(c.$1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.poppy : (isDark ? pt.surface2 : Colors.white),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active
                                  ? AppColors.poppy
                                  : pt.line,
                            ),
                          ),
                          child: Text(
                            c.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : pt.ink950,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: promosAsync.when(
                loading: () => const Center(child: TailWagLoader()),
                error: (e, _) => Center(
                  child: Text('Failed to load promos', style: TextStyle(color: pt.ink500)),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return const PetfolioEmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'No promos available',
                      subtitle: 'Check back soon for exclusive deals\nand discounts.',
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16, 0, 16, MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PromoCard(
                      promo: filtered[i],
                      isDark: isDark,
                      pt: pt,
                    )
                        .animate(delay: Duration(milliseconds: 50 * i))
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.08, end: 0, duration: 280.ms),
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

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.promo,
    required this.isDark,
    required this.pt,
  });

  final Promo promo;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? pt.surface2 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promo.code,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: pt.ink950,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.poppy.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.poppy,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            promo.description,
            style: TextStyle(fontSize: 13, color: pt.ink500, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                promo.validUntilFormatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink500,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.poppy,
                  side: const BorderSide(color: AppColors.poppy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Add promo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
