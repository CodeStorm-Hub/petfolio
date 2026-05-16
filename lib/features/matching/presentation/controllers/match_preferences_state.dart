import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_preferences_state.freezed.dart';

@freezed
abstract class MatchPreferencesState with _$MatchPreferencesState {
  const factory MatchPreferencesState({
    @Default(<String>[]) List<String> selectedSpecies,
    @Default(80467.0) double maxDistanceMeters,
    @Default(0) int ageMinYears,
    @Default(30) int ageMaxYears,
  }) = _MatchPreferencesState;
}
