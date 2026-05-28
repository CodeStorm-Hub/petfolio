// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    @JsonKey(name: 'admin_id') required String adminId,
    required String action,
    @JsonKey(name: 'entity_type') required String entityType,
    @JsonKey(name: 'entity_id') String? entityId,
    Map<String, dynamic>? details,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    // Optional joined admin display name
    @JsonKey(name: 'admin_name') String? adminName,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
