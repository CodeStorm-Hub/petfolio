import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final pt = Theme.of(sheetContext).extension<PetfolioThemeExtension>()!;
        return Container(
          decoration: BoxDecoration(
            color: pt.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius2xl),
            ),
          ),
          child: builder(sheetContext),
        );
      },
    );
  }
}
