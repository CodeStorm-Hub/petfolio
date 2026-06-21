import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// M3 Expressive connected button group — replaces segmented buttons
/// (deprecated in the May 2025 spec) for single-selection, mutually
/// exclusive choices such as category or filter bars.
///
/// Segments share a single pill-shaped outline; the selected segment morphs
/// to a filled rounded-square shape while idle segments stay flat.
class PfButtonGroup<T> extends StatelessWidget {
  const PfButtonGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.scrollable = true,
  });

  final List<PfButtonGroupOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final row = Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerHigh,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
        ),
      ),
      child: Row(
        mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            scrollable
                ? _Segment(
                    option: options[i],
                    isSelected: options[i].value == selected,
                    onTap: () => onChanged(options[i].value),
                    pt: pt,
                    cs: cs,
                  )
                : Expanded(
                    child: _Segment(
                      option: options[i],
                      isSelected: options[i].value == selected,
                      onTap: () => onChanged(options[i].value),
                      pt: pt,
                      cs: cs,
                    ),
                  ),
          ],
        ],
      ),
    );

    if (!scrollable) return row;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
  }
}

class PfButtonGroupOption<T> {
  const PfButtonGroupOption({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.pt,
    required this.cs,
  });

  final PfButtonGroupOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationMd,
        curve: PetfolioThemeExtension.curveSpring,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: ShapeDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          // Shape-morph: selected segment becomes a rounded-square,
          // idle segments stay fully pill-shaped.
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(
              isSelected
                  ? PetfolioThemeExtension.radiusLg
                  : PetfolioThemeExtension.radiusPill,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 16,
                color: isSelected ? cs.onPrimary : pt.ink500,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? cs.onPrimary : pt.ink500,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
