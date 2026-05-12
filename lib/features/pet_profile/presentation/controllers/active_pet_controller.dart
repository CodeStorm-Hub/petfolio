import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pet.dart';
import 'pet_list_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivePetController
// ─────────────────────────────────────────────────────────────────────────────

/// Single source of truth for which pet is currently active.
///
/// **Usage — any feature that needs the full pet object:**
/// ```dart
/// final pet = ref.watch(activePetControllerProvider);
/// ```
///
/// **Usage — features that only need the pet ID (preferred, fewer rebuilds):**
/// ```dart
/// final petId = ref.watch(activePetIdProvider);
/// ```
///
/// **Switching the active pet (e.g. from the switcher sheet):**
/// ```dart
/// await ref.read(activePetControllerProvider.notifier).setActivePet(pet);
/// ```
///
/// The selected pet ID is persisted in [SharedPreferences] and restored on
/// the next app launch.  On logout the persisted value is cleared so the next
/// user starts with a clean slate.
class ActivePetController extends Notifier<Pet?> {
  static const _prefKey = 'active_pet_id';

  /// Tracks whether we have already performed the SharedPreferences restore
  /// for the current login session.
  bool _initialized = false;

  @override
  Pet? build() {
    // Whenever the pet list changes (including on login / logout), reconcile
    // the active selection.
    ref.listen<AsyncValue<List<Pet>>>(
      petListProvider,
      (_, next) => next.whenData(_sync),
      fireImmediately: true,
    );
    return null;
  }

  void _sync(List<Pet> pets) {
    if (pets.isEmpty) {
      // User signed out (or has no pets yet).
      // Reset state so the next login triggers a fresh SharedPreferences
      // restore rather than immediately falling back to the first pet.
      state = null;
      _initialized = false;
      // Clear the stored ID so a subsequent user never inherits it.
      SharedPreferences.getInstance().then((p) => p.remove(_prefKey));
      return;
    }

    if (!_initialized) {
      // First real data for this session — restore the persisted selection.
      _initialized = true;
      _restoreFromPrefs(pets);
      return;
    }

    // On subsequent list updates (e.g. avatar uploaded, pet renamed):
    if (state != null && pets.any((p) => p.id == state!.id)) {
      // Refresh the in-memory reference so callers always see fresh metadata.
      state = pets.firstWhere((p) => p.id == state!.id);
      return;
    }

    // Active pet was deleted — fall back to the first in the list.
    state = pets.first;
  }

  Future<void> _restoreFromPrefs(List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);

    Pet? found;
    if (savedId != null) {
      for (final p in pets) {
        if (p.id == savedId) {
          found = p;
          break;
        }
      }
    }

    state = found ?? pets.first;

    // Persist the auto-selected ID if no saved value existed yet.
    if (found == null) {
      await prefs.setString(_prefKey, state!.id);
    }
  }

  /// Switches the active pet and persists the choice immediately.
  Future<void> setActivePet(Pet pet) async {
    state = pet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, pet.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// The full active [Pet] object.  Null until the pet list has loaded.
final activePetControllerProvider =
    NotifierProvider<ActivePetController, Pet?>(ActivePetController.new);

/// Derived provider that exposes **only the active pet's ID**.
///
/// Prefer this over [activePetControllerProvider] in features that need to
/// scope a query to the active pet but don't need the pet's metadata — it
/// avoids unnecessary rebuilds when pet details (avatar, breed) change.
///
/// ```dart
/// final petId = ref.watch(activePetIdProvider); // String? — null until ready
/// ```
final activePetIdProvider = Provider<String?>((ref) {
  return ref.watch(activePetControllerProvider)?.id;
});
