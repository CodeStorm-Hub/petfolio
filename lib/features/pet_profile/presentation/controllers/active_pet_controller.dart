import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pet.dart';
import 'pet_list_controller.dart';

/// Single source of truth for which pet is currently active.
///
/// Other features watch this provider to swap their data context instantly:
/// ```dart
/// final pet = ref.watch(activePetControllerProvider);
/// ```
///
/// The selected pet ID is persisted in [SharedPreferences] so the selection
/// survives app restarts. On first launch the first pet in the list is
/// auto-selected.
class ActivePetController extends Notifier<Pet?> {
  static const _prefKey = 'active_pet_id';

  /// Whether we have already attempted to restore from SharedPreferences.
  bool _initialized = false;

  @override
  Pet? build() {
    // Whenever the pet list changes, reconcile the active selection.
    ref.listen<AsyncValue<List<Pet>>>(
      petListProvider,
      (_, next) => next.whenData(_sync),
      fireImmediately: true,
    );
    return null;
  }

  void _sync(List<Pet> pets) {
    if (pets.isEmpty) {
      state = null;
      return;
    }

    if (!_initialized) {
      // First real data — restore persisted selection asynchronously.
      _initialized = true;
      _restoreFromPrefs(pets);
      return;
    }

    // On subsequent updates keep current selection if still valid.
    if (state != null && pets.any((p) => p.id == state!.id)) {
      // Refresh the in-memory reference (e.g. avatar_url may have changed).
      state = pets.firstWhere((p) => p.id == state!.id);
      return;
    }

    // Active pet was removed — fall back to the first in the list.
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

    // Persist the default selection if no saved ID existed.
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

final activePetControllerProvider =
    NotifierProvider<ActivePetController, Pet?>(ActivePetController.new);
