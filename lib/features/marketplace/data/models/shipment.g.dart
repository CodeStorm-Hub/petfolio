// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shipment _$ShipmentFromJson(Map<String, dynamic> json) => _Shipment(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  courier: json['courier'] as String?,
  trackingId: json['tracking_id'] as String?,
  trackingUrl: json['tracking_url'] as String?,
  status:
      $enumDecodeNullable(
        _$ShipmentStatusEnumMap,
        json['status'],
        unknownValue: ShipmentStatus.pending,
      ) ??
      ShipmentStatus.pending,
  shippedAt: json['shipped_at'] == null
      ? null
      : DateTime.parse(json['shipped_at'] as String),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ShipmentToJson(_Shipment instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'courier': instance.courier,
  'tracking_id': instance.trackingId,
  'tracking_url': instance.trackingUrl,
  'status': _$ShipmentStatusEnumMap[instance.status]!,
  'shipped_at': instance.shippedAt?.toIso8601String(),
  'estimated_delivery_at': instance.estimatedDeliveryAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$ShipmentStatusEnumMap = {
  ShipmentStatus.pending: 'pending',
  ShipmentStatus.pickedUp: 'picked_up',
  ShipmentStatus.inTransit: 'in_transit',
  ShipmentStatus.outForDelivery: 'out_for_delivery',
  ShipmentStatus.delivered: 'delivered',
  ShipmentStatus.failed: 'failed',
};
