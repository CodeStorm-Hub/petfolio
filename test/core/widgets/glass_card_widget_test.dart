import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/glass_card.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('GlassCard', () {
    testWidgets('renders its child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(child: Text('hello glass')),
      ));
      await tester.pump();

      expect(find.text('hello glass'), findsOneWidget);
    });

    testWidgets('uses solid fallback when forceOpaque is true', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(
          forceOpaque: true,
          child: Text('opaque'),
        ),
      ));
      await tester.pump();

      // BackdropFilter is absent in the solid fallback path
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('opaque'), findsOneWidget);
    });

    testWidgets('uses solid fallback when disableAnimations is true', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(child: Text('reduced-motion')),
        disableAnimations: true,
      ));
      await tester.pump();

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('reduced-motion'), findsOneWidget);
    });

    testWidgets('uses glass (BackdropFilter) when animations enabled', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(child: Text('glassy')),
      ));
      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('accepts explicit width and height', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(
          forceOpaque: true,
          width: 200,
          height: 100,
          child: SizedBox.shrink(),
        ),
      ));
      await tester.pump();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.maxWidth, 200);
      expect(container.constraints?.maxHeight, 100);
    });

    testWidgets('applies custom borderRadius', (tester) async {
      const radius = 40.0;
      await tester.pumpWidget(_wrap(
        const GlassCard(
          forceOpaque: true,
          borderRadius: radius,
          child: Text('rounded'),
        ),
      ));
      await tester.pump();

      // Just verify it renders without overflow / layout errors
      expect(tester.takeException(), isNull);
      expect(find.text('rounded'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: GlassCard(child: Text('dark mode')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('dark mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
