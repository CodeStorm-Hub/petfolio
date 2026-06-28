import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.action});

  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PetfolioThemeExtension.spaceMd,
        PetfolioThemeExtension.spaceLg,
        PetfolioThemeExtension.spaceMd,
        PetfolioThemeExtension.spaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: pt.labelCapsStyle,
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
