// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vet_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VetService _$VetServiceFromJson(Map<String, dynamic> json) => _VetService(
  id: json['id'] as String,
  clinicId: json['clinic_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  priceCents: (json['price_cents'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$VetServiceToJson(_VetService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clinic_id': instance.clinicId,
      'name': instance.name,
      'description': instance.description,
      'duration_minutes': instance.durationMinutes,
      'price_cents': instance.priceCents,
      'created_at': instance.createdAt.toIso8601String(),
    };
