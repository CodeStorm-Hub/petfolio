import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(Supabase.instance.client),
);

class PetListNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    try {
      return await ref.read(petRepositoryProvider).fetchPets();
    } on AuthException {
      // JWT from a previous project is invalid — sign out so the user
      // can re-authenticate against the current Supabase project.
      await ref.read(authRepositoryProvider).signOut();
      return [];
    } catch (e) {
      // Re-throw other errors so the UI can show them.
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
  }) async {
    final pet = await ref.read(petRepositoryProvider).createPet(
          name: name,
          species: species,
          breed: breed,
          avatarUrl: avatarUrl,
        );
    state = AsyncData([...state.valueOrNull ?? [], pet]);
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
