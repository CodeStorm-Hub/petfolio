import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_streak.freezed.dart';
part 'care_streak.g.dart';

DateTime? _lastCompletionFromJson(dynamic raw) {
  if (raw == null) return null;
  final s = raw is String ? raw : raw.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

String? _lastCompletionToJson(DateTime? dt) =>
    dt?.toLocal().toIso8601String().split('T').first;

@freezed
abstract class CareStreak with _$CareStreak {
  const factory CareStreak({
    @JsonKey(name: 'pet_id') required String petId,
    @JsonKey(name: 'current_streak') required int currentStreak,
    @JsonKey(
      name: 'last_completion_date',
      fromJson: _lastCompletionFromJson,
      toJson: _lastCompletionToJson,
    )
    DateTime? lastCompletionDate,
    @JsonKey(name: 'best_streak') required int bestStreak,
  }) = _CareStreak;

  factory CareStreak.fromJson(Map<String, dynamic> json) =>
      _$CareStreakFromJson(json);
}
