import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

const _kShopIntroSeenKey = 'pf_shop_intro_seen';

class ShopIntroScreen extends StatelessWidget {
  const ShopIntroScreen({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kShopIntroSeenKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShopIntroSeenKey, true);
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

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.poppy.withAlpha(18)
                            : AppColors.poppySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🛍️', style: TextStyle(fontSize: 96)),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Introducing\nPetfolio Shop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: pt.ink950,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Everything your pet needs, delivered to your door.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: pt.ink500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.poppy.withAlpha(22)
                                    : AppColors.poppySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(f.emoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: pt.ink950,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    f.sub,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: pt.ink500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ShopIntroScreen.markSeen();
                    if (context.mounted) context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.poppy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
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
