// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LineItem _$LineItemFromJson(Map<String, dynamic> json) => _LineItem(
  productId: json['product_id'] as String,
  productName: json['product_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitCents: (json['unit_cents'] as num).toInt(),
  lineTotalCents: (json['line_total_cents'] as num).toInt(),
  isSubscribed: json['is_subscribed'] as bool,
  frequencyWeeks: (json['frequency_weeks'] as num).toInt(),
  variantId: json['variant_id'] as String?,
  isRx: json['is_rx'] as bool? ?? false,
);

Map<String, dynamic> _$LineItemToJson(_LineItem instance) => <String, dynamic>{
  'product_id': instance.productId,
  'product_name': instance.productName,
  'quantity': instance.quantity,
  'unit_cents': instance.unitCents,
  'line_total_cents': instance.lineTotalCents,
  'is_subscribed': instance.isSubscribed,
  'frequency_weeks': instance.frequencyWeeks,
  'variant_id': instance.variantId,
  'is_rx': instance.isRx,
};

_MarketplaceOrder _$MarketplaceOrderFromJson(Map<String, dynamic> json) =>
    _MarketplaceOrder(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      shopId: json['shop_id'] as String,
      title: json['title'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      currency: json['currency'] as String,
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['payment_method']) ??
          PaymentMethod.stripe,
      paymentStatus:
          $enumDecodeNullable(_$PaymentStatusEnumMap, json['payment_status']) ??
          PaymentStatus.pending,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      lineItems: (json['line_items'] as List<dynamic>)
          .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingTrackingNumber: json['shipping_tracking_number'] as String?,
      shippingTrackingUrl: json['shipping_tracking_url'] as String?,
      shippingCarrier: json['shipping_carrier'] as String?,
      shippedAt: json['shipped_at'] == null
          ? null
          : DateTime.parse(json['shipped_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MarketplaceOrderToJson(_MarketplaceOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'buyer_id': instance.buyerId,
      'shop_id': instance.shopId,
      'title': instance.title,
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'payment_method': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'stripe_payment_intent_id': instance.stripePaymentIntentId,
      'line_items': instance.lineItems,
      'shipping_tracking_number': instance.shippingTrackingNumber,
      'shipping_tracking_url': instance.shippingTrackingUrl,
      'shipping_carrier': instance.shippingCarrier,
      'shipped_at': instance.shippedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.processing: 'processing',
  OrderStatus.shipped: 'shipped',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.stripe: 'stripe',
  PaymentMethod.cod: 'cod',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.collected: 'collected',
};
