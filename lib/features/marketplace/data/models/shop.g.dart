// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shop _$ShopFromJson(Map<String, dynamic> json) => _Shop(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  shopName: json['shop_name'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  logoUrl: json['logo_url'] as String?,
  bannerUrl: json['banner_url'] as String?,
  isActive: json['is_active'] as bool,
  isVerified: json['is_verified'] as bool,
  stripeConnectAccountId: json['stripe_connect_account_id'] as String?,
  stripeOnboardingComplete: json['stripe_onboarding_complete'] as bool,
  platformFeePercent: (json['platform_fee_percent'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ShopToJson(_Shop instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'shop_name': instance.shopName,
  'slug': instance.slug,
  'description': instance.description,
  'logo_url': instance.logoUrl,
  'banner_url': instance.bannerUrl,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'stripe_connect_account_id': instance.stripeConnectAccountId,
  'stripe_onboarding_complete': instance.stripeOnboardingComplete,
  'platform_fee_percent': instance.platformFeePercent,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
