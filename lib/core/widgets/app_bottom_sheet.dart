import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final pt = Theme.of(sheetContext).extension<PetfolioThemeExtension>()!;
        return Container(
          decoration: BoxDecoration(
            color: pt.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius3xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: pt.ink300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        );
      },
    );
  }
}
