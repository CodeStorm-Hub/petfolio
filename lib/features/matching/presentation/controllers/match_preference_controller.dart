import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_preferences_state.dart';

final matchPreferenceControllerProvider =
    NotifierProvider<MatchPreferenceController, MatchPreferencesState>(
  MatchPreferenceController.new,
);

class MatchPreferenceController extends Notifier<MatchPreferencesState> {
  @override
  MatchPreferencesState build() => const MatchPreferencesState();

  void setSelectedSpecies(List<String> species) {
    state = state.copyWith(selectedSpecies: List<String>.unmodifiable(species));
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
  }

  void setAgeRangeYears({required int minYears, required int maxYears}) {
    final lo = minYears < 0 ? 0 : minYears;
    final hi = maxYears < lo ? lo : maxYears;
    state = state.copyWith(ageMinYears: lo, ageMaxYears: hi);
  }
}

const double kMatchMinDistanceMeters = 1609;
const double kMatchMaxDistanceMeters = 80467;
const int kMatchMaxAgeYears = 30;
