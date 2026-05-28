// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => _AuditLog(
  id: json['id'] as String,
  adminId: json['admin_id'] as String,
  action: json['action'] as String,
  entityType: json['entity_type'] as String,
  entityId: json['entity_id'] as String?,
  details: json['details'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['created_at'] as String),
  adminName: json['admin_name'] as String?,
);

Map<String, dynamic> _$AuditLogToJson(_AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'admin_id': instance.adminId,
  'action': instance.action,
  'entity_type': instance.entityType,
  'entity_id': instance.entityId,
  'details': instance.details,
  'created_at': instance.createdAt.toIso8601String(),
  'admin_name': instance.adminName,
};
