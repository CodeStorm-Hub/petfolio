import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('PetAvatar', () {
    testWidgets('renders species emoji when imageUrl is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(species: PetSpecies.dog),
      ));
      await tester.pump();

      expect(find.text('🐶'), findsOneWidget);
    });

    testWidgets('renders cat emoji for cat species', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(species: PetSpecies.cat),
      ));
      await tester.pump();

      expect(find.text('🐱'), findsOneWidget);
    });

    testWidgets('renders initials when provided and no imageUrl', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(
          species: PetSpecies.dog,
          initials: 'Bx',
        ),
      ));
      await tester.pump();

      expect(find.text('BX'), findsOneWidget);
    });

    testWidgets('applies xl size correctly', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(
          species: PetSpecies.dog,
          size: PetAvatarSize.xl,
        ),
      ));
      await tester.pump();

      final disc = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(disc.constraints?.maxWidth, greaterThanOrEqualTo(56));
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        PetAvatar(
          species: PetSpecies.dog,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows online status dot when isOnline is true', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(
          species: PetSpecies.dog,
          isOnline: true,
        ),
      ));
      await tester.pump();

      // The Stack with status dot is rendered when isOnline != null
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('has semantics image label when imageUrl is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const PetAvatar(
          imageUrl: 'https://example.com/pet.jpg',
          species: PetSpecies.dog,
          semanticLabel: 'Rex the dog',
        ),
      ));
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(PetAvatar));
      expect(semantics.label, 'Rex the dog');
    });
  });
}
