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
  payoutMethod: $enumDecode(_$PayoutMethodEnumMap, json['payout_method']),
  kycStatus: $enumDecode(_$KycStatusEnumMap, json['kyc_status']),
  tradeLicenseUrl: json['trade_license_url'] as String?,
  nationalIdUrl: json['national_id_url'] as String?,
  rejectionReason: json['rejection_reason'] as String?,
  bankAccountDetails: json['bank_account_details'] as Map<String, dynamic>?,
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
  'payout_method': _$PayoutMethodEnumMap[instance.payoutMethod]!,
  'kyc_status': _$KycStatusEnumMap[instance.kycStatus]!,
  'trade_license_url': instance.tradeLicenseUrl,
  'national_id_url': instance.nationalIdUrl,
  'rejection_reason': instance.rejectionReason,
  'bank_account_details': instance.bankAccountDetails,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$PayoutMethodEnumMap = {
  PayoutMethod.stripe: 'stripe',
  PayoutMethod.manual: 'manual',
};

const _$KycStatusEnumMap = {
  KycStatus.pending: 'pending',
  KycStatus.submitted: 'submitted',
  KycStatus.approved: 'approved',
  KycStatus.rejected: 'rejected',
};
