import 'package:freezed_annotation/freezed_annotation.dart';

part 'shipment.freezed.dart';
part 'shipment.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum ShipmentStatus {
  pending,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  failed;

  String get label => switch (this) {
        ShipmentStatus.pending        => 'Pending',
        ShipmentStatus.pickedUp       => 'Picked Up',
        ShipmentStatus.inTransit      => 'In Transit',
        ShipmentStatus.outForDelivery => 'Out for Delivery',
        ShipmentStatus.delivered      => 'Delivered',
        ShipmentStatus.failed         => 'Failed',
      };

  bool get isTerminal =>
      this == ShipmentStatus.delivered || this == ShipmentStatus.failed;
}

@freezed
abstract class Shipment with _$Shipment {
  const factory Shipment({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    String? courier,
    @JsonKey(name: 'tracking_id') String? trackingId,
    @JsonKey(name: 'tracking_url') String? trackingUrl,
    @JsonKey(
      name: 'status',
      unknownEnumValue: ShipmentStatus.pending,
    )
    @Default(ShipmentStatus.pending)
    ShipmentStatus status,
    @JsonKey(name: 'shipped_at') DateTime? shippedAt,
    @JsonKey(name: 'estimated_delivery_at') DateTime? estimatedDeliveryAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Shipment;

  factory Shipment.fromJson(Map<String, dynamic> json) =>
      _$ShipmentFromJson(json);
}
