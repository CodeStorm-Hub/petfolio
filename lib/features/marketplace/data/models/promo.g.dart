// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Promo _$PromoFromJson(Map<String, dynamic> json) => _Promo(
  id: json['id'] as String,
  code: json['code'] as String,
  description: json['description'] as String,
  discountType: $enumDecode(_$PromoDiscountTypeEnumMap, json['discount_type']),
  discountValue: (json['discount_value'] as num).toInt(),
  minOrderCents: (json['min_order_cents'] as num).toInt(),
  maxDiscountCents: (json['max_discount_cents'] as num?)?.toInt(),
  category: json['category'] as String,
  isActive: json['is_active'] as bool,
  validUntil: json['valid_until'] == null
      ? null
      : DateTime.parse(json['valid_until'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  shopId: json['shop_id'] as String?,
);

Map<String, dynamic> _$PromoToJson(_Promo instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'description': instance.description,
  'discount_type': _$PromoDiscountTypeEnumMap[instance.discountType]!,
  'discount_value': instance.discountValue,
  'min_order_cents': instance.minOrderCents,
  'max_discount_cents': instance.maxDiscountCents,
  'category': instance.category,
  'is_active': instance.isActive,
  'valid_until': instance.validUntil?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'shop_id': instance.shopId,
};

const _$PromoDiscountTypeEnumMap = {
  PromoDiscountType.percent: 'percent',
  PromoDiscountType.flat: 'flat',
};
