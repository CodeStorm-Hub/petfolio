import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _tutorialSeenKey = 'pf_app_tutorial_seen_v1';

Future<bool> shouldShowAppTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_tutorialSeenKey) ?? false);
}

Future<void> markAppTutorialSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_tutorialSeenKey, true);
}

class AppTutorialOverlay extends StatefulWidget {
  const AppTutorialOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<AppTutorialOverlay> createState() => _AppTutorialOverlayState();
}

class _AppTutorialOverlayState extends State<AppTutorialOverlay> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    (icon: Icons.pets, color: AppColors.tangerine, title: 'Your pets', body: 'Manage profiles, stats, and daily quests from the Pets tab.'),
    (icon: Icons.local_fire_department, color: AppColors.sunny, title: 'Care & health', body: 'Track tasks, streaks, nutrition, and medical records.'),
    (icon: Icons.favorite, color: AppColors.poppy, title: 'Social & stories', body: 'Share posts, watch stories, and join pet communities.'),
    (icon: Icons.auto_awesome, color: AppColors.lilac, title: 'Match & chat', body: 'Swipe to discover playmates and message after a mutual match.'),
    (icon: Icons.storefront, color: AppColors.mint, title: 'Marketplace', body: 'Shop pet products from verified vendors with secure checkout.'),
  ];

  Future<void> _finish() async {
    await markAppTutorialSeen();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final slide = _slides[_page];

    return Material(
      color: Colors.black.withAlpha(191),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('app_tutorial_skip'),
                onPressed: _finish,
                child: const Text('Skip', style: TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: s.color.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 44, color: s.color),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Colors.white.withAlpha(216),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            _slides.length,
                            (idx) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: idx == i ? s.color : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: slide.color,
                    foregroundColor: pt.ink950,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (_page < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(_page < _slides.length - 1 ? 'Next' : 'Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
