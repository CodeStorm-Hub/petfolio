import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

import '../controllers/match_preference_controller.dart';

class MatchPreferencesSheet extends ConsumerWidget {
  const MatchPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6B0B1220),
        useSafeArea: true,
        builder: (_) => const MatchPreferencesSheet(),
      );

  static const _speciesOptions = <PetSpecies>[
    PetSpecies.dog,
    PetSpecies.cat,
    PetSpecies.rabbit,
    PetSpecies.bird,
    PetSpecies.fish,
    PetSpecies.reptile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(matchPreferenceControllerProvider);
    final notifier = ref.read(matchPreferenceControllerProvider.notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.58, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius2xl),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowE4L,
                blurRadius: 60,
                offset: const Offset(0, -20),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pt.ink300.withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Discovery preferences',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('match_prefs_close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: pt.ink500),
                  ),
                ],
              ),
              Text(
                'Filters apply to your swipe deck. Changes refresh nearby profiles shortly after you adjust them.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: pt.ink500,
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Species'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final species in _speciesOptions)
                    _SpeciesPill(
                      label: species.label,
                      emoji: species.emoji,
                      accent: species.accent,
                      selected: prefs.selectedSpecies.contains(species.name),
                      onTap: () => notifier.toggleSpecies(species.name),
                    ),
                ],
              ),
              if (prefs.selectedSpecies.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'All species — tap to narrow',
                  style: TextStyle(fontSize: 12, color: pt.ink300),
                ),
              ],
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Max distance',
                trailing: _formatDistanceMiles(prefs.maxDistanceMeters),
              ),
              Slider(
                key: const ValueKey<String>('match_prefs_distance_slider'),
                value: prefs.maxDistanceMeters.clamp(
                  kMatchMinDistanceMeters,
                  kMatchMaxDistanceMeters,
                ),
                min: kMatchMinDistanceMeters,
                max: kMatchMaxDistanceMeters,
                onChanged: notifier.setMaxDistanceMeters,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 mi',
                    style: TextStyle(fontSize: 12, color: pt.ink300),
                  ),
                  Text(
                    '50 mi',
                    style: TextStyle(fontSize: 12, color: pt.ink300),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Age',
                trailing:
                    '${prefs.ageMinYears}–${prefs.ageMaxYears} yrs',
              ),
              RangeSlider(
                key: const ValueKey<String>('match_prefs_age_slider'),
                values: RangeValues(
                  prefs.ageMinYears.toDouble(),
                  prefs.ageMaxYears.toDouble(),
                ),
                min: 0,
                max: kMatchMaxAgeYears.toDouble(),
                divisions: kMatchMaxAgeYears,
                labels: RangeLabels(
                  '${prefs.ageMinYears}',
                  '${prefs.ageMaxYears}',
                ),
                onChanged: (range) => notifier.setAgeRangeYears(
                  minYears: range.start.round(),
                  maxYears: range.end.round(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 yrs',
                    style: TextStyle(fontSize: 12, color: pt.ink300),
                  ),
                  Text(
                    '$kMatchMaxAgeYears yrs',
                    style: TextStyle(fontSize: 12, color: pt.ink300),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDistanceMiles(double meters) {
    final miles = meters / 1609.344;
    if (miles >= 10) {
      return '${miles.round()} mi';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.tangerine,
            ),
          ),
      ],
    );
  }
}

class _SpeciesPill extends StatelessWidget {
  const _SpeciesPill({
    required this.label,
    required this.emoji,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final bg = selected ? accent.withValues(alpha: 0.18) : pt.surface2;
    final border = selected ? accent : pt.ink300.withAlpha(90);
    final fg = selected
        ? accent
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
        child: AnimatedContainer(
          duration: PetfolioThemeExtension.durationSm,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.circular(PetfolioThemeExtension.radiusPill),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
