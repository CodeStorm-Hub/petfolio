import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_record.freezed.dart';
part 'medical_record.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum MedicalRecordType {
  vaccine,
  medication,
  allergy,
  surgery,
  parasitePrevention,
  other,
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class MedicalRecord with _$MedicalRecord {
  const MedicalRecord._();

  const factory MedicalRecord({
    required String id,
    required String petId,
    required MedicalRecordType recordType,
    required String name,
    String? description,
    String? administeredBy,
    DateTime? administeredAt,
    DateTime? expiresAt,
    DateTime? nextDueAt,
    String? batchNumber,
    String? dosage,
    String? frequency,
    required bool isActive,
    required bool reminderEnabled,
    String? documentUrl,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MedicalRecord;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) =>
      _$MedicalRecordFromJson(json);

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  DateTime? get renewalDate => nextDueAt ?? expiresAt;

  bool get isExpiringSoon {
    final raw = renewalDate;
    if (raw == null) return false;
    final d = DateUtils.dateOnly(raw);
    final today = DateUtils.dateOnly(DateTime.now());
    final limit = today.add(const Duration(days: 30));
    return !d.isBefore(today) && !d.isAfter(limit);
  }

  bool get isVaccine => recordType == MedicalRecordType.vaccine;

  bool isDueSoon({int withinDays = 30}) {
    if (nextDueAt == null) return false;
    final threshold = DateTime.now().add(Duration(days: withinDays));
    return nextDueAt!.isBefore(threshold) &&
        nextDueAt!.isAfter(DateTime.now());
  }

  bool get isOverdue {
    if (nextDueAt == null) return false;
    return nextDueAt!.isBefore(DateTime.now());
  }

  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  int? get daysUntilDue {
    if (nextDueAt == null) return null;
    return nextDueAt!.difference(DateTime.now()).inDays;
  }

  bool get needsReminder =>
      reminderEnabled && isActive && (isDueSoon() || isExpired || isOverdue);
}
