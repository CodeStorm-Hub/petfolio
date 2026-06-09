import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/petfolio_empty_state.dart';

void main() {
  group('PetfolioEmptyState', () {
    testWidgets('renders title and optional action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PetfolioEmptyState(
              icon: Icons.pets,
              title: 'No pets yet',
              subtitle: 'Add your first pet',
              action: FilledButton(
                onPressed: () {},
                child: const Text('Add pet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pets yet'), findsOneWidget);
      expect(find.text('Add your first pet'), findsOneWidget);
      expect(find.text('Add pet'), findsOneWidget);
    });

    testWidgets('renders title and subtitle together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: PetfolioEmptyState(
              icon: Icons.group,
              title: 'No communities',
              subtitle: 'Be the first to create one',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No communities'), findsOneWidget);
      expect(find.text('Be the first to create one'), findsOneWidget);
    });
  });
}
