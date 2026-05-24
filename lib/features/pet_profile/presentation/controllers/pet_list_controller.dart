import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petfolio/features/pet_profile/data/models/pet.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_gender.dart';
import 'package:petfolio/features/pet_profile/data/repositories/pet_repository.dart';
import 'package:petfolio/features/care/data/repositories/pet_care_repository.dart';
import 'package:petfolio/features/care/domain/services/care_recommendation_service.dart';

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
    state = AsyncData([...state.value ?? [], pet]);
    
    // Auto-generate care tasks in the background without blocking
    _autoGenerateRoutines(pet);
    
    return pet;
  }

  Future<void> _autoGenerateRoutines(Pet pet) async {
    try {
      final service = CareRecommendationService();
      final tasks = await service.generateRecommendations(pet);
      if (tasks.isNotEmpty) {
        await ref.read(careTaskRepositoryProvider).bulkCreateTasks(tasks);
      }
    } catch (e) {
      // Background failure, silently ignore or log
      debugPrint('Auto-generation of routines failed for pet ${pet.id}: $e');
    }
  }

  Future<Pet> editPetProfile({
    required String id,
    required String name,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    required PetGender gender,
    double? weightKg,
    String? activityLevel,
    required bool isPublic,
  }) async {
    final pet = await ref.read(petRepositoryProvider).updatePetProfile(
          id: id,
          name: name,
          breed: breed,
          avatarUrl: avatarUrl,
          bio: bio,
          dateOfBirth: dateOfBirth,
          gender: gender,
          weightKg: weightKg,
          activityLevel: activityLevel,
          isPublic: isPublic,
        );
    updateLocal(pet);
    return pet;
  }

  Future<void> setDiscoverable({
    required String petId,
    required bool discoverable,
  }) async {
    final previous = state.value;
    if (previous == null) return;

    Pet? priorPet;
    for (final p in previous) {
      if (p.id == petId) {
        priorPet = p;
        break;
      }
    }
    if (priorPet == null) return;

    final optimistic = priorPet.copyWith(isDiscoverable: discoverable);
    state = AsyncData([
      for (final p in previous)
        if (p.id == petId) optimistic else p,
    ]);

    try {
      final updated = await ref.read(petRepositoryProvider).updateDiscoverable(
            petId: petId,
            discoverable: discoverable,
          );
      updateLocal(updated);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Updates the in-memory copy of a pet (e.g. after avatar upload).
  void updateLocal(Pet updated) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final p in list)
        if (p.id == updated.id) updated else p,
    ]);
  }

  /// Optimistically reorders the in-memory list, then persists the new
  /// [display_order] values. On failure the original list is restored and the
  /// error is rethrown so the caller can surface it.
  Future<void> reorder(List<Pet> reordered) async {
    final previous = state.value;
    state = AsyncData([
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(displayOrder: i),
    ]);
    try {
      await ref
          .read(petRepositoryProvider)
          .reorderPets(reordered.map((p) => p.id).toList(growable: false));
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }

  /// Soft-archives a pet and removes it from the active list. Returns the
  /// archived pet so callers can offer an Undo affordance.
  Future<Pet> archive(String petId) async {
    final archived = await ref.read(petRepositoryProvider).archivePet(petId);
    final list = state.value ?? const <Pet>[];
    state = AsyncData(list.where((p) => p.id != petId).toList());
    return archived;
  }

  /// Restores a previously-archived pet back into the active list.
  Future<void> unarchive(String petId) async {
    final restored = await ref.read(petRepositoryProvider).unarchivePet(petId);
    final list = state.value ?? const <Pet>[];
    final merged = [...list, restored]..sort(_comparePetsListOrder);
    state = AsyncData(merged);
  }
}

int _comparePetsListOrder(Pet a, Pet b) {
  final byOrder = a.displayOrder.compareTo(b.displayOrder);
  if (byOrder != 0) return byOrder;
  return a.createdAt.compareTo(b.createdAt);
}

final petListProvider =
    AsyncNotifierProvider<PetListNotifier, List<Pet>>(PetListNotifier.new);
