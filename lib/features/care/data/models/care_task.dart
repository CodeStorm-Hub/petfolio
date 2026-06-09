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
    // Reference date for recurring tasks (weekly / biweekly / monthly).
    // Defaults to createdAt on the server; never null after the first sync.
    DateTime? anchorDate,
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

  /// The effective anchor for recurrence calculations — falls back to createdAt
  /// for tasks saved before anchor_date was introduced.
  DateTime get effectiveAnchor =>
      anchorDate ?? DateUtils.dateOnly(createdAt.toLocal());

  /// True when this task applies on today's local date and is not yet done.
  bool get isDueToday {
    if (isCompleted) return false;
    final today = DateUtils.dateOnly(DateTime.now().toLocal());
    return appliesToDay(today);
  }

  /// True when the task was due on any prior day and was not completed.
  bool get isOverdue {
    if (isCompleted) return false;
    if (frequency == CareFrequency.asNeeded) return false;
    if (frequency == CareFrequency.once) return false;
    // Weekly and biweekly tasks are visible every day within their period window
    // (see appliesToDay below). Checking past days would flag them as overdue
    // every single day — incorrect. Period-level completion tracking is handled
    // via care_logs; the model cannot know about past-window logs here.
    if (frequency == CareFrequency.weekly || frequency == CareFrequency.biweekly) {
      return false;
    }
    final today = DateUtils.dateOnly(DateTime.now().toLocal());
    final start = DateUtils.dateOnly(effectiveAnchor.toLocal());
    // Walk backwards up to 30 days to find a missed daily/monthly occurrence.
    for (var i = 1; i <= 30; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(start)) break;
      if (appliesToDay(day)) return true;
    }
    return false;
  }

  bool appliesToDay(DateTime dayLocal) {
    final start = DateUtils.dateOnly(effectiveAnchor.toLocal());
    if (dayLocal.isBefore(start)) return false;
    switch (frequency) {
      case CareFrequency.daily:
      case CareFrequency.twiceDaily:
      case CareFrequency.asNeeded:
        return true;
      case CareFrequency.once:
        if (isCompleted && completedAt != null) {
          return dayLocal == DateUtils.dateOnly(completedAt!.toLocal());
        }
        return dayLocal == DateUtils.dateOnly(effectiveAnchor.toLocal());
      case CareFrequency.weekly:
        // Show on ANY day within the current 7-day window from the anchor.
        // Previously this was `% 7 == 0` (anchor day-of-week only), which
        // made tasks invisible on days other than the exact anchor weekday.
        // Users should be able to complete weekly tasks on any convenient day.
        return true;
      case CareFrequency.biweekly:
        // Same rationale as weekly — visible any day in the 14-day window.
        return true;
      case CareFrequency.monthly:
        final lastDay = DateTime(dayLocal.year, dayLocal.month + 1, 0).day;
        final anchor = start.day > lastDay ? lastDay : start.day;
        return dayLocal.day == anchor;
    }
  }

  bool get isLogDerived => id.startsWith('log:');

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
