import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

const _kShopIntroSeenKey = 'pf_shop_intro_seen';

class ShopIntroSheet extends StatelessWidget {
  const ShopIntroSheet({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kShopIntroSeenKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShopIntroSeenKey, true);
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShopIntroSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const features = [
      (emoji: '✅', title: 'Authentic Products', sub: 'Original products from top-rated pet sellers'),
      (emoji: '💳', title: 'Pay Conveniently', sub: 'Use your preferred payment method or pay on delivery'),
      (emoji: '📦', title: 'Track Your Order', sub: 'Find updated status in Activity to track the delivery'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: pt.line, borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.poppy.withAlpha(18)
                            : AppColors.poppySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🛍️', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Introducing\nPetfolio Shop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: pt.ink950,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Everything your pet needs, delivered to your door.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: pt.ink500, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.poppy.withAlpha(22)
                                    : AppColors.poppySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pt.ink950)),
                                  const SizedBox(height: 3),
                                  Text(f.sub, style: TextStyle(fontSize: 12, color: pt.ink500, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ShopIntroSheet.markSeen();
                    if (context.mounted) context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.poppy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: const Text("Let's explore"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Backward-compat alias — call sites that push /marketplace/intro still compile.
typedef ShopIntroScreen = ShopIntroSheet;
