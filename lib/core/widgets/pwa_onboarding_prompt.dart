import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petfolio/core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/primary_pill_button.dart';
import 'package:petfolio/core/utils/pwa_detector.dart';

class PwaOnboardingPrompt extends StatelessWidget {
  const PwaOnboardingPrompt({super.key});

  /// Checks if the platform is iOS Web (excluding standalone mode) and if the prompt
  /// has not been recently dismissed, and shows the onboarding bottom sheet after a short delay.
  static Future<void> checkAndShow(BuildContext context) async {
    // 1. Check if iOS web and not running as PWA yet
    if (!isIOSWebNotStandalone()) return;

    // 2. Check SharedPreferences dismissal cache (snooze for 7 days)
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedTime = prefs.getInt('pwa_prompt_dismissed_at');
      if (dismissedTime != null) {
        final dismissedDate = DateTime.fromMillisecondsSinceEpoch(dismissedTime);
        final difference = DateTime.now().difference(dismissedDate);
        if (difference.inDays < 7) {
          return;
        }
      }
    } catch (_) {
      // In case SharedPreferences fails, we still proceed with showing
    }

    // 3. Show sheet after a 2-second delay to ensure smooth app boot
    if (!context.mounted) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 500),
        builder: (context) => const PwaOnboardingPrompt(),
      );
    });
  }

  Future<void> _dismissPrompt(BuildContext context, {bool permanent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // If permanent, we set a timestamp far in the future or a custom flag, otherwise standard 7-day snooze
      final timestamp = permanent 
          ? DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('pwa_prompt_dismissed_at', timestamp);
    } catch (_) {}

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface0D : AppColors.surface0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: isDark ? AppColors.lineD : AppColors.line),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.lineD : AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🐾',
                      style: GoogleFonts.inter(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Install PetFolio',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _dismissPrompt(context, permanent: false),
                color: pt.ink500,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description text
          Text(
            'Add PetFolio to your home screen to launch it in full-screen standalone mode and get a complete app experience.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: pt.ink700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Steps list
          _buildStepRow(
            context,
            index: '1',
            text: 'Tap the Share button in Safari\'s bottom toolbar.',
            trailing: const Icon(
              Icons.ios_share_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(height: 14),
          _buildStepRow(
            context,
            index: '2',
            text: 'Scroll down and select Add to Home Screen.',
            trailing: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: pt.ink300, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.add_rounded,
                color: pt.ink950,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildStepRow(
            context,
            index: '3',
            text: 'Tap Add in the top-right corner to install.',
            trailing: Text(
              'Add',
              style: GoogleFonts.inter(
                color: Colors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _dismissPrompt(context, permanent: true),
                  child: Text(
                    'Don\'t show again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: pt.ink500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryPillButton(
                  label: 'Got it',
                  size: PillButtonSize.md,
                  variant: PillButtonVariant.primary,
                  onPressed: () => _dismissPrompt(context, permanent: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required String index,
    required String text,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.tangerine700D : AppColors.tangerine700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pt.ink950,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: trailing,
        ),
      ],
    );
  }
}
