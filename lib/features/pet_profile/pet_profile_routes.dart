import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/controllers/pet_list_controller.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/manage_pets_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

List<RouteBase> petProfileRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    path: '/onboarding',
    builder: (context, state) {
      final mode = state.uri.queryParameters['mode'];
      return OnboardingScreen(addAnotherPet: mode == 'add');
    },
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/pets/manage',
    builder: (context, state) => const ManagePetsScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/pet/:petId/edit',
    builder: (context, state) {
      final petId = state.pathParameters['petId']!;
      return Consumer(
        builder: (context, ref, _) {
          final petsAsync = ref.watch(petListProvider);
          return petsAsync.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const _PetEditMissingScreen(),
            data: (pets) {
              for (final p in pets) {
                if (p.id == petId) return EditProfileScreen(pet: p);
              }
              return const _PetEditMissingScreen();
            },
          );
        },
      );
    },
  ),
];

class _PetEditMissingScreen extends StatelessWidget {
  const _PetEditMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pet not found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Pets'),
            ),
          ],
        ),
      ),
    );
  }
}
