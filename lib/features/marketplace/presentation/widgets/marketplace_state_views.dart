import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_pill_button.dart';

class MarketplaceErrorView extends StatelessWidget {
  const MarketplaceErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Something went wrong',
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: pt.ink300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(
              label: 'Retry',
              size: PillButtonSize.md,
              variant: PillButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceEmptyView extends StatelessWidget {
  const MarketplaceEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: pt.ink300),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: pt.ink950,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: pt.ink500),
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
              PrimaryPillButton(
                label: ctaLabel!,
                size: PillButtonSize.md,
                onPressed: onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
