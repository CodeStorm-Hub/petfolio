// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserAddress _$UserAddressFromJson(Map<String, dynamic> json) => _UserAddress(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  label: $enumDecode(_$AddressLabelEnumMap, json['label']),
  fullAddress: json['full_address'] as String,
  city: json['city'] as String,
  zone: json['zone'] as String,
  area: json['area'] as String,
  isDefault: json['is_default'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserAddressToJson(_UserAddress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'label': _$AddressLabelEnumMap[instance.label]!,
      'full_address': instance.fullAddress,
      'city': instance.city,
      'zone': instance.zone,
      'area': instance.area,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$AddressLabelEnumMap = {
  AddressLabel.home: 'home',
  AddressLabel.work: 'work',
  AddressLabel.campus: 'campus',
  AddressLabel.other: 'other',
};
