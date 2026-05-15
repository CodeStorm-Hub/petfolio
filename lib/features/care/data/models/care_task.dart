import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_task.freezed.dart';
part 'care_task.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum CareTaskType {
  feeding,
  walk,
  grooming,
  medication,
  vetVisit,
  training,
  playtime,
  dental,
  nailTrim,
  bath,
  other,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum CareFrequency {
  once,
  daily,
  twiceDaily,
  weekly,
  biweekly,
  monthly,
  asNeeded,
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class CareTask with _$CareTask {
  const CareTask._();

  const factory CareTask({
    required String id,
    required String petId,
    required CareTaskType taskType,
    required String title,
    required CareFrequency frequency,
    String? scheduledTime,
    required bool isCompleted,
    DateTime? completedAt,
    required int gamificationPoints,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CareTask;

  factory CareTask.fromJson(Map<String, dynamic> json) =>
      _$CareTaskFromJson(json);

  bool get isDueToday =>
      !isCompleted &&
      (frequency == CareFrequency.daily ||
          frequency == CareFrequency.twiceDaily ||
          frequency == CareFrequency.once);

  bool get isOverdue {
    if (isCompleted || completedAt != null) return false;
    if (frequency == CareFrequency.once) return false;
    final today = DateTime.now();
    return updatedAt.isBefore(DateTime(today.year, today.month, today.day));
  }

  CareTask markCompleted() => copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  CareTask reset() => copyWith(
        isCompleted: false,
        completedAt: null,
        updatedAt: DateTime.now(),
      );
}
