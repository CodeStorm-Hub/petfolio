import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/pet.dart';
import '../../data/repositories/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(Supabase.instance.client),
);

class PetListNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() =>
      ref.read(petRepositoryProvider).fetchPets();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(petRepositoryProvider).fetchPets(),
    );
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
