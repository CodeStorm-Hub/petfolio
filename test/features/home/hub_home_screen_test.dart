import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/features/home/presentation/screens/hub_home_screen.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/data/models/pet.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/pet_awards_provider.dart';
import 'package:petfolio/features/care/data/models/care_streak.dart';
import 'package:petfolio/features/care/data/models/pet_awards_summary.dart';

final _testPet = Pet(
  id: 'pet-123',
  ownerId: 'owner-123',
  name: 'Fluffy',
  species: 'dog',
  createdAt: DateTime.utc(2026, 1, 1),
);

class _StubPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => [_testPet];
}

class _StubActivePetController extends ActivePetController {
  @override
  Pet? build() => _testPet;
}

class _StubCareDashboard extends CareDashboard {
  @override
  DailyRoutineState build() {
    return DailyRoutineState(
      selectedDate: DateTime.utc(2026, 6, 28),
      tasks: const AsyncValue.data([]),
      todayTasks: const AsyncValue.data([]),
      streak: const AsyncValue.data(CareStreak(
        petId: 'pet-123',
        currentStreak: 5,
        bestStreak: 10,
      )),
      weekGoalHit: const AsyncValue.data([true, false, true, false, true, false, true]),
      badgeTypes: const {},
    );
  }
}

void main() {
  testWidgets('HubHomeScreen renders components successfully', (tester) async {
    final mockStreak = CareStreak(
      petId: 'pet-123',
      currentStreak: 5,
      bestStreak: 10,
    );

    final mockAwards = const PetAwardsSummary(
      currentStreak: 5,
      bestStreak: 10,
      totalXp: 150,
      logsCount: 15,
      unlockedBadges: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petListProvider.overrideWith(_StubPetListNotifier.new),
          activePetControllerProvider.overrideWith(_StubActivePetController.new),
          careStreakRealtimeProvider('pet-123').overrideWith((ref) => Stream.value(mockStreak)),
          petAwardsSummaryProvider('pet-123').overrideWithValue(AsyncValue.data(mockAwards)),
          careDashboardProvider.overrideWith(_StubCareDashboard.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: HubHomeScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify some elements on the screen.
    // For example, it should have Services and Quick Actions
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
