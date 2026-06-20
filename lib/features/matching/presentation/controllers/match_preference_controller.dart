import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/match_mode.dart';
import 'match_preferences_state.dart';

const String _kMode = 'match_pref_mode';
const String _kSpecies = 'match_pref_species';
const String _kDistance = 'match_pref_distance_meters';
const String _kAgeMin = 'match_pref_age_min';
const String _kAgeMax = 'match_pref_age_max';

final matchPreferenceControllerProvider =
    NotifierProvider<MatchPreferenceController, MatchPreferencesState>(
  MatchPreferenceController.new,
);

class MatchPreferenceController extends Notifier<MatchPreferencesState> {
  @override
  MatchPreferencesState build() {
    _loadFromPrefs();
    return const MatchPreferencesState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = MatchMode.fromDb(prefs.getString(_kMode));
    final species = prefs.getStringList(_kSpecies) ?? const <String>[];
    final distance = prefs.getDouble(_kDistance) ?? kMatchMaxDistanceMeters;
    final ageMin = prefs.getInt(_kAgeMin) ?? 0;
    final ageMax = prefs.getInt(_kAgeMax) ?? kMatchMaxAgeYears;
    if (!ref.mounted) return;
    state = MatchPreferencesState(
      mode: mode,
      selectedSpecies: List<String>.unmodifiable(species),
      maxDistanceMeters: distance,
      ageMinYears: ageMin,
      ageMaxYears: ageMax,
    );
  }

  void setMode(MatchMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kMode, mode.dbValue));
  }

  void setSelectedSpecies(List<String> species) {
    state = state.copyWith(selectedSpecies: List<String>.unmodifiable(species));
    SharedPreferences.getInstance()
        .then((p) => p.setStringList(_kSpecies, species));
  }

  void toggleSpecies(String speciesId) {
    final id = speciesId.toLowerCase();
    final current = List<String>.from(state.selectedSpecies);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    setSelectedSpecies(current);
  }

  void setMaxDistanceMeters(double meters) {
    state = state.copyWith(maxDistanceMeters: meters);
    SharedPreferences.getInstance().then((p) => p.setDouble(_kDistance, meters));
  }

  void setAgeRangeYears({required int minYears, required int maxYears}) {
    final lo = minYears < 0 ? 0 : minYears;
    final hi = maxYears < lo ? lo : maxYears;
    state = state.copyWith(ageMinYears: lo, ageMaxYears: hi);
    SharedPreferences.getInstance()
      ..then((p) => p.setInt(_kAgeMin, lo))
      ..then((p) => p.setInt(_kAgeMax, hi));
  }
}

const double kMatchMinDistanceMeters = 1609;
const double kMatchMaxDistanceMeters = 80467;
const int kMatchMaxAgeYears = 30;
