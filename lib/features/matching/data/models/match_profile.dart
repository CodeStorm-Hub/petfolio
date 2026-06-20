import 'package:freezed_annotation/freezed_annotation.dart';

import 'match_mode.dart';

part 'match_profile.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class MatchProfile with _$MatchProfile {
  const factory MatchProfile({
    required String petId,
    required MatchMode mode,
    @Default(true) bool isActive,
    String? playStyle,
    String? energyLevel,
    String? preferredSize,
    String? availability,
  }) = _MatchProfile;

  const MatchProfile._();

  factory MatchProfile.fromJson(Map<String, dynamic> json) => MatchProfile(
        petId: json['pet_id'] as String,
        mode: MatchMode.fromDb(json['mode'] as String?),
        isActive: json['is_active'] as bool? ?? true,
        playStyle: json['play_style'] as String?,
        energyLevel: json['energy_level'] as String?,
        preferredSize: json['preferred_size'] as String?,
        availability: json['availability'] as String?,
      );

  Map<String, dynamic> toUpsert() => {
        'pet_id': petId,
        'mode': mode.dbValue,
        'is_active': isActive,
        'play_style': playStyle,
        'energy_level': energyLevel,
        'preferred_size': preferredSize,
        'availability': availability,
      };
}
