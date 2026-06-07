import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/features/marketplace/presentation/widgets/star_rating_widget.dart';

void main() {
  group('StarRatingWidget', () {
    testWidgets('renders five stars for full rating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: StarRatingWidget(rating: 5),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    testWidgets('renders half star for 3.5 rating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: StarRatingWidget(rating: 3.5),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    });

    testWidgets('onRatingChanged fires when star tapped', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StarRatingWidget(
              rating: 0,
              onRatingChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();

      expect(selected, 1);
    });

    testWidgets('exposes semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: StarRatingWidget(
              rating: 4.2,
              semanticLabel: 'Product rating',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Product rating'), findsOneWidget);
    });
  });
}
