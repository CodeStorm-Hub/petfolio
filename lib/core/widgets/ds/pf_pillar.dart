import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

enum PfPillar {
  home,
  care,
  social,
  match,
  market,
  seller,
  admin,
}

extension PfPillarColors on PfPillar {
  Color color(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return switch (this) {
      PfPillar.home => Theme.of(context).colorScheme.primary,
      PfPillar.care => pt.pillarHealth,
      PfPillar.social => pt.pillarSocial,
      PfPillar.match => pt.pillarMatch,
      PfPillar.market => pt.pillarMarket,
      PfPillar.seller => AppColors.apricot500,
      PfPillar.admin => AppColors.ink700,
    };
  }

  Color tint(BuildContext context) =>
      color(context).withValues(alpha: 0.12);
}
