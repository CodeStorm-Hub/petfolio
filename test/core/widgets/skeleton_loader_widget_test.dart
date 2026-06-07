import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/skeleton_loader.dart';

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
  group('SkeletonLoader', () {
    testWidgets('renders rectangular block', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonLoader(width: 120, height: 16),
      ));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('circle constructor renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonLoader.circle(size: 48),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('listTile factory renders row skeleton', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.listTile()));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses static fill when animations disabled', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonLoader(width: 80, height: 12),
        disableAnimations: true,
      ));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
