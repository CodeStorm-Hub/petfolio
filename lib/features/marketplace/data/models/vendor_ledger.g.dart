// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_ledger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VendorLedger _$VendorLedgerFromJson(Map<String, dynamic> json) =>
    _VendorLedger(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      orderId: json['order_id'] as String,
      orderTotalCents: (json['order_total_cents'] as num).toInt(),
      platformFeeCents: (json['platform_fee_cents'] as num).toInt(),
      vendorEarningsCents: (json['vendor_earnings_cents'] as num).toInt(),
      status: $enumDecode(_$LedgerStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$VendorLedgerToJson(_VendorLedger instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shop_id': instance.shopId,
      'order_id': instance.orderId,
      'order_total_cents': instance.orderTotalCents,
      'platform_fee_cents': instance.platformFeeCents,
      'vendor_earnings_cents': instance.vendorEarningsCents,
      'status': _$LedgerStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$LedgerStatusEnumMap = {
  LedgerStatus.pendingClearance: 'pendingClearance',
  LedgerStatus.available: 'available',
  LedgerStatus.paid: 'paid',
};
