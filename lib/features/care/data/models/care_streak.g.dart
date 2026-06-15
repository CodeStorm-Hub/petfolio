// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_streak.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CareStreak _$CareStreakFromJson(Map<String, dynamic> json) => _CareStreak(
  petId: json['pet_id'] as String,
  currentStreak: (json['current_streak'] as num).toInt(),
  lastCompletionDate: _lastCompletionFromJson(json['last_completion_date']),
  bestStreak: (json['best_streak'] as num).toInt(),
  freezesAvailable: (json['freezes_available'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$CareStreakToJson(
  _CareStreak instance,
) => <String, dynamic>{
  'pet_id': instance.petId,
  'current_streak': instance.currentStreak,
  'last_completion_date': _lastCompletionToJson(instance.lastCompletionDate),
  'best_streak': instance.bestStreak,
  'freezes_available': instance.freezesAvailable,
};
