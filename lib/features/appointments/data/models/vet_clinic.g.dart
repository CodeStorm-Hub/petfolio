// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vet_clinic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VetClinic _$VetClinicFromJson(Map<String, dynamic> json) => _VetClinic(
  id: json['id'] as String,
  name: json['name'] as String,
  tagline: json['tagline'] as String?,
  address: json['address'] as String,
  city: json['city'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  website: json['website'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  rating: _ratingFromJson(json['rating']),
  reviewCount: (json['review_count'] as num).toInt(),
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$VetClinicToJson(_VetClinic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tagline': instance.tagline,
      'address': instance.address,
      'city': instance.city,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'avatar_url': instance.avatarUrl,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
