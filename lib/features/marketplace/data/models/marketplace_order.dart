import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketplace_order.freezed.dart';
part 'marketplace_order.g.dart';

@JsonEnum()
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.pending    => 'Pending',
        OrderStatus.processing => 'Processing',
        OrderStatus.shipped    => 'Shipped',
        OrderStatus.delivered  => 'Delivered',
        OrderStatus.cancelled  => 'Cancelled',
      };

  bool get isActive =>
      this != OrderStatus.cancelled && this != OrderStatus.delivered;
}

@JsonEnum()
enum PaymentMethod {
  stripe,
  cod,
  bkash,
  nagad,
  sslcommerz;

  bool get isSslcommerz =>
      this == bkash || this == nagad || this == sslcommerz;
}

@JsonEnum()
enum PaymentStatus { pending, paid, collected }

@freezed
abstract class LineItem with _$LineItem {
  const factory LineItem({
    required String productId,
    required String productName,
    required int quantity,
    required int unitCents,
    required int lineTotalCents,
    required bool isSubscribed,
    required int frequencyWeeks,
    String? variantId,
    @Default(false) bool isRx,
  }) = _LineItem;

  factory LineItem.fromJson(Map<String, dynamic> json) =>
      _$LineItemFromJson(json);
}

@freezed
abstract class MarketplaceOrder with _$MarketplaceOrder {
  const MarketplaceOrder._();

  const factory MarketplaceOrder({
    required String id,
    required String buyerId,
    required String shopId,
    required String title,
    required int amountCents,
    required String currency,
    required OrderStatus status,
    @Default(PaymentMethod.stripe) PaymentMethod paymentMethod,
    @Default(PaymentStatus.pending) PaymentStatus paymentStatus,
    String? stripePaymentIntentId,
    String? sslcommerzTransactionId,
    required List<LineItem> lineItems,
    String? shippingTrackingNumber,
    String? shippingTrackingUrl,
    String? shippingCarrier,
    DateTime? shippedAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MarketplaceOrder;

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceOrderFromJson(json);

  String get amountFormatted =>
      '\$${(amountCents / 100).toStringAsFixed(2)}';

  bool get hasTracking =>
      shippingTrackingNumber != null && shippingTrackingNumber!.isNotEmpty;

  bool get isCod => paymentMethod == PaymentMethod.cod;

  bool get isSslcommerz => paymentMethod.isSslcommerz;

  bool get hasRxItems => lineItems.any((i) => i.isRx);
}
