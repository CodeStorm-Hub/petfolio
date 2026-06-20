import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class MarketplaceBackButton extends StatelessWidget {
  const MarketplaceBackButton({
    super.key,
    this.fallbackRoute = '/marketplace',
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.backgroundColor,
  });

  final String fallbackRoute;
  final IconData icon;
  final Color? backgroundColor;

  void _handleTap(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Semantics(
      label: 'Back',
      button: true,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? AppColors.surface0,
              boxShadow: [BoxShadow(color: pt.line, spreadRadius: 0.5)],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: pt.ink700),
          ),
        ),
      ),
    );
  }
}
