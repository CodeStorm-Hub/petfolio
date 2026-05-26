import 'package:flutter/material.dart';
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
abstract class CareTask with _$CareTask {
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
    String? categoryIcon,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CareTask;

  factory CareTask.fromJson(Map<String, dynamic> json) =>
      _$CareTaskFromJson(json);

  String get resolvedCategoryIcon {
    final raw = categoryIcon?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return _defaultCategoryIconKey(taskType);
  }

  IconData get categoryIconData =>
      careTaskCategoryIconData(resolvedCategoryIcon, taskType);

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

  bool get isLogDerived => false;

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

IconData careTaskTypeIconData(CareTaskType t) =>
    careTaskCategoryIconData(_defaultCategoryIconKey(t), t);

String _defaultCategoryIconKey(CareTaskType t) => switch (t) {
      CareTaskType.feeding => 'feeding',
      CareTaskType.walk => 'walk',
      CareTaskType.grooming => 'grooming',
      CareTaskType.medication => 'medication',
      CareTaskType.vetVisit => 'vet_visit',
      CareTaskType.training => 'training',
      CareTaskType.playtime => 'playtime',
      CareTaskType.dental => 'dental',
      CareTaskType.nailTrim => 'nail_trim',
      CareTaskType.bath => 'bath',
      CareTaskType.other => 'other',
    };

IconData careTaskCategoryIconData(String key, CareTaskType fallbackType) {
  switch (key) {
    case 'feeding':
    case 'restaurant_menu':
      return Icons.restaurant_menu_rounded;
    case 'walk':
    case 'directions_walk':
      return Icons.directions_walk_rounded;
    case 'grooming':
    case 'content_cut':
      return Icons.content_cut_rounded;
    case 'medication':
    case 'medication_liquid':
      return Icons.medication_rounded;
    case 'vet_visit':
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'training':
    case 'school':
      return Icons.school_rounded;
    case 'playtime':
    case 'sports_tennis':
      return Icons.sports_tennis_rounded;
    case 'dental':
    case 'medical_services':
      return Icons.medical_services_rounded;
    case 'nail_trim':
    case 'cut':
      return Icons.cut_rounded;
    case 'bath':
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'other':
    case 'star_outline':
      return Icons.star_outline_rounded;
    default:
      return _iconDataForTaskType(fallbackType);
  }
}

IconData _iconDataForTaskType(CareTaskType t) => switch (t) {
      CareTaskType.feeding => Icons.restaurant_menu_rounded,
      CareTaskType.walk => Icons.directions_walk_rounded,
      CareTaskType.grooming => Icons.content_cut_rounded,
      CareTaskType.medication => Icons.medication_rounded,
      CareTaskType.vetVisit => Icons.local_hospital_rounded,
      CareTaskType.training => Icons.school_rounded,
      CareTaskType.playtime => Icons.sports_tennis_rounded,
      CareTaskType.dental => Icons.medical_services_rounded,
      CareTaskType.nailTrim => Icons.cut_rounded,
      CareTaskType.bath => Icons.water_drop_rounded,
      CareTaskType.other => Icons.star_outline_rounded,
    };
