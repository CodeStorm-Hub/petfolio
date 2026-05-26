import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/core/domain/models/pet.dart';
import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petfolio/core/domain/controllers/pet_list_controller.dart';
import 'package:petfolio/main.dart';

class _StubPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => [];
}

void main() {
  testWidgets('login screen renders for unauthenticated user',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWithValue(false),
          petListProvider.overrideWith(_StubPetListNotifier.new),
        ],
        child: const PetfolioApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
