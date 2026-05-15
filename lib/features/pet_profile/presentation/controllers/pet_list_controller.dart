import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(Supabase.instance.client),
);

class PetListNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    // Read the current user directly rather than watching isLoggedInProvider.
    //
    // Watching a derived bool caused petListProvider to rebuild on EVERY auth
    // event (including the automatic tokenRefreshed ping Supabase sends every
    // ~55 minutes), putting the provider back into AsyncLoading and making all
    // screens show a loading spinner.  The router invalidates this provider
    // whenever the logged-in status genuinely changes (sign-in / sign-out).
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      return await ref
          .read(petRepositoryProvider)
          .fetchPets()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Could not reach the server. Check your connection.',
            ),
          );
    } on AuthException {
      // JWT rejected by Supabase — session belongs to a different project or
      // is completely invalid.  Force sign-out so the user can log back in.
      await ref.read(authRepositoryProvider).signOut();
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(petRepositoryProvider).fetchPets());
    } on AuthException {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData([]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Creates a pet in Supabase, appends it to the local list, and returns it.
  Future<Pet> addPet({
    required String name,
    required String species,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    double? weightKg,
    String? activityLevel,
  }) async {
    final pet = await ref.read(petRepositoryProvider).createPet(
          name: name,
          species: species,
          breed: breed,
          avatarUrl: avatarUrl,
          bio: bio,
          dateOfBirth: dateOfBirth,
          weightKg: weightKg,
          activityLevel: activityLevel,
        );
    state = AsyncData([...state.valueOrNull ?? [], pet]);
    return pet;
  }

  /// Updates a pet in Supabase and the local list.
  Future<Pet> editPet({
    required String id,
    String? name,
    String? breed,
    String? avatarUrl,
    String? bio,
  }) async {
    final pet = await ref.read(petRepositoryProvider).updatePet(
          id: id,
          name: name,
          breed: breed,
          avatarUrl: avatarUrl,
          bio: bio,
        );
    updateLocal(pet);
    return pet;
  }

  /// Updates the in-memory copy of a pet (e.g. after avatar upload).
  void updateLocal(Pet updated) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([
      for (final p in list)
        if (p.id == updated.id) updated else p,
    ]);
  }
}

final petListProvider =
    AsyncNotifierProvider<PetListNotifier, List<Pet>>(PetListNotifier.new);
