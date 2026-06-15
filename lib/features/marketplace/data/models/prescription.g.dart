// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Prescription _$PrescriptionFromJson(Map<String, dynamic> json) =>
    _Prescription(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      filePath: json['file_path'] as String,
      vetName: json['vet_name'] as String?,
      status: json['status'] == null
          ? PrescriptionStatus.pending
          : _rxStatusFromJson(json['status'] as String),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PrescriptionToJson(_Prescription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'file_path': instance.filePath,
      'vet_name': instance.vetName,
      'status': _rxStatusToJson(instance.status),
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
