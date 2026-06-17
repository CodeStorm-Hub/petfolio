import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AllFeaturesSheet — Pathao-style bottom-sheet catalog of every PetFolio
// feature. Triggered by the "All" bento tile or the "All ›" section link.
// ─────────────────────────────────────────────────────────────────────────────

class AllFeaturesSheet {
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AllFeaturesSheetContent(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _AllFeaturesSheetContent extends StatelessWidget {
  const _AllFeaturesSheetContent();

  static const _features = [
    _FeatureItem(
      icon: Icons.local_fire_department_rounded,
      label: 'Care',
      sub: 'Daily routines & health',
      color: AppColors.sunny,
      soft: AppColors.sunnySoft,
      route: '/care',
    ),
    _FeatureItem(
      icon: Icons.favorite_rounded,
      label: 'PawsFeed',
      sub: 'Social posts & stories',
      color: AppColors.poppy,
      soft: AppColors.poppySoft,
      route: '/social',
    ),
    _FeatureItem(
      icon: Icons.auto_awesome_rounded,
      label: 'Pet Match',
      sub: 'Playdate & breeding',
      color: AppColors.lilac,
      soft: AppColors.lilacSoft,
      route: '/matching',
    ),
    _FeatureItem(
      icon: Icons.storefront_rounded,
      label: 'Marketplace',
      sub: 'Shops & products',
      color: AppColors.mint,
      soft: AppColors.mintSoft,
      route: '/marketplace',
    ),
    _FeatureItem(
      icon: Icons.medical_services_rounded,
      label: 'Appointments',
      sub: 'Vet & grooming visits',
      color: AppColors.sky,
      soft: AppColors.skySoft,
      route: '/appointments',
    ),
    _FeatureItem(
      icon: Icons.directions_walk_rounded,
      label: 'Walk Tracker',
      sub: 'GPS route logging',
      color: AppColors.tangerine,
      soft: AppColors.tangerineSoft,
      route: '/care/walk',
    ),
    _FeatureItem(
      icon: Icons.health_and_safety_rounded,
      label: 'Health Vault',
      sub: 'Medical records',
      color: AppColors.mint,
      soft: AppColors.mintSoft,
      route: '/care/medical-vault',
    ),
    _FeatureItem(
      icon: Icons.groups_rounded,
      label: 'Communities',
      sub: 'Breed groups & clubs',
      color: AppColors.lilac,
      soft: AppColors.lilacSoft,
      route: '/social/communities',
    ),
    _FeatureItem(
      icon: Icons.restaurant_rounded,
      label: 'Nutrition',
      sub: 'Diet & meal tracking',
      color: AppColors.sunny,
      soft: AppColors.sunnySoft,
      route: '/care/nutrition',
    ),
    _FeatureItem(
      icon: Icons.psychology_rounded,
      label: 'AI Routine',
      sub: 'Smart care suggestions',
      color: AppColors.tangerine,
      soft: AppColors.tangerineSoft,
      route: '/care',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: pt.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'All Features',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: pt.ink950,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: 'Close',
                  button: true,
                  child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? pt.surface2 : AppColors.ink300.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.close_rounded, size: 18, color: pt.ink500),
                  ),
                ),
                ),
              ],
            ),
          ),

          // ── Grid ────────────────────────────────────────────────────────
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
              itemCount: _features.length,
              itemBuilder: (context, i) => _FeatureCard(
                item: _features[i],
                isDark: isDark,
                pt: pt,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(_features[i].route);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.item,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final _FeatureItem item;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? widget.item.color.withAlpha(28)
        : widget.item.soft;

    return Semantics(
      label: '${widget.item.label}, ${widget.item.sub}',
      button: true,
      child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? widget.item.color.withAlpha(40)
                  : widget.item.color.withAlpha(30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.item.color.withAlpha(widget.isDark ? 56 : 40),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(widget.item.icon, size: 18, color: widget.item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.pt.ink950,
                      ),
                    ),
                    Text(
                      widget.item.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: widget.pt.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.soft,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Color soft;
  final String route;
}
