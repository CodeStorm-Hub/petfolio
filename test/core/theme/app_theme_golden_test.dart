import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/glass_card.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';

Widget _panel(ThemeData theme) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Builder(
      builder: (context) {
        final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: cs.surface,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ColorRow(label: 'primary', color: cs.primary, onColor: cs.onPrimary),
                _ColorRow(label: 'secondary', color: cs.secondary, onColor: cs.onSecondary),
                _ColorRow(label: 'surface', color: cs.surface, onColor: cs.onSurface),
                _ColorRow(label: 'error', color: cs.error, onColor: cs.onError),
                const SizedBox(height: 12),
                _SwatchRow(
                  colors: [
                    (AppColors.tangerine, 'tangerine'),
                    (AppColors.sunny, 'sunny'),
                    (AppColors.poppy, 'poppy'),
                    (AppColors.lilac, 'lilac'),
                    (AppColors.mint, 'mint'),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  forceOpaque: true,
                  child: Row(
                    children: [
                      const PetAvatar(species: PetSpecies.dog),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buddy', style: Theme.of(context).textTheme.titleMedium),
                          Text('Golden Retriever', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pt.ink500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final species in [PetSpecies.dog, PetSpecies.cat, PetSpecies.rabbit, PetSpecies.bird])
                      PetAvatar(species: species, size: PetAvatarSize.md),
                  ],
                ),
                const SizedBox(height: 16),
                _PilletsRow(pt: pt),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.color, required this.onColor});
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        height: 32,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(label, style: TextStyle(color: onColor, fontSize: 12, fontFamily: 'monospace')),
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.colors});
  final List<(Color, String)> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (c, label) in colors)
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
            ),
          ),
      ],
    );
  }
}

class _PilletsRow extends StatelessWidget {
  const _PilletsRow({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final pairs = [
      (pt.pillarPets, 'Pets'),
      (pt.pillarCare, 'Care'),
      (pt.pillarSocial, 'Social'),
      (pt.pillarMatch, 'Match'),
      (pt.pillarMarket, 'Market'),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (c, label) in pairs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: c, width: 1)),
            child: Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme goldens', () {
    testWidgets('light theme panel', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_panel(AppTheme.light()));
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/app_theme_light.png'),
      );
    });

    testWidgets('dark theme panel', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_panel(AppTheme.dark()));
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/app_theme_dark.png'),
      );
    });

    testWidgets('color tokens differ between light and dark', (tester) async {
      final light = AppTheme.light().extension<PetfolioThemeExtension>()!;
      final dark = AppTheme.dark().extension<PetfolioThemeExtension>()!;

      expect(light.surface1, isNot(equals(dark.surface1)));
      expect(light.ink950, isNot(equals(dark.ink950)));
      expect(light.cream, isNot(equals(dark.cream)));
    });

    testWidgets('pillar accent colors are fully opaque in both themes', (tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final pt = theme.extension<PetfolioThemeExtension>()!;
        for (final color in [
          pt.pillarPets,
          pt.pillarCare,
          pt.pillarSocial,
          pt.pillarMatch,
          pt.pillarMarket,
        ]) {
          expect(color.a, 1.0, reason: 'Pillar accent must be fully opaque');
        }
      }
    });
  });
}
