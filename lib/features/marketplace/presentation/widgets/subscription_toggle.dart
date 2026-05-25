import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubscriptionToggle — animated pill switch matching the design spec
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionToggle extends StatelessWidget {
  const SubscriptionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? AppColors.meadow500 : AppColors.line,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FrequencyChips — row of 2 / 4 / 6 / 8 week chips
// ─────────────────────────────────────────────────────────────────────────────

class FrequencyChips extends StatelessWidget {
  const FrequencyChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  static const _freqs = [2, 4, 6, 8];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final f in _freqs)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: f != _freqs.last ? 6 : 0),
              child: _FreqChip(
                weeks: f,
                selected: f == selected,
                onTap: () => onSelected(f),
              ),
            ),
          ),
      ],
    );
  }
}

class _FreqChip extends StatelessWidget {
  const _FreqChip({
    required this.weeks,
    required this.selected,
    required this.onTap,
  });

  final int weeks;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.ink950 : Colors.white,
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: AppColors.line,
                    blurRadius: 0,
                    spreadRadius: 0.5,
                  ),
                ],
        ),
        child: Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$weeks',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? Colors.white : AppColors.ink700,
                  ),
                ),
                TextSpan(
                  text: 'wk',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: selected ? Colors.white70 : AppColors.ink500,
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
