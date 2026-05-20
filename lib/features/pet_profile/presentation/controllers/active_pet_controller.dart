import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/pet.dart';
import 'pet_list_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivePetController
// ─────────────────────────────────────────────────────────────────────────────

class ActivePetController extends Notifier<Pet?> {
  static String _prefKey(String userId) => 'active_pet_id_$userId';

  bool _initialized = false;

  /// Retained across the session so the correct key can be cleared on logout
  /// even after Supabase has already nulled currentUser.
  String? _userId;

  @override
  Pet? build() {
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
      _initialized = false;
      if (_userId != null) {
        SharedPreferences.getInstance()
            .then((p) => p.remove(_prefKey(_userId!)));
        _userId = null;
      }
      return;
    }

    if (!_initialized) {
      _initialized = true;
      _userId = Supabase.instance.client.auth.currentUser?.id;
      _restoreFromPrefs(pets);
      return;
    }

    if (state != null && pets.any((p) => p.id == state!.id)) {
      state = pets.firstWhere((p) => p.id == state!.id);
      return;
    }

    state = pets.first;
  }

  Future<void> _restoreFromPrefs(List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();

    Pet? found;
    if (_userId != null) {
      final savedId = prefs.getString(_prefKey(_userId!));
      if (savedId != null) {
        for (final p in pets) {
          if (p.id == savedId) {
            found = p;
            break;
          }
        }
      }
    }

    state = found ?? pets.first;

    if (found == null && _userId != null) {
      await prefs.setString(_prefKey(_userId!), state!.id);
    }
  }

  Future<void> setActivePet(Pet pet) async {
    state = pet;
    if (_userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(_userId!), pet.id);
    }
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
