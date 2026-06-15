// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marketplace_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LineItem {

 String get productId; String get productName; int get quantity; int get unitCents; int get lineTotalCents; bool get isSubscribed; int get frequencyWeeks; String? get variantId; bool get isRx;
/// Create a copy of LineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineItemCopyWith<LineItem> get copyWith => _$LineItemCopyWithImpl<LineItem>(this as LineItem, _$identity);

  /// Serializes this LineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCents, unitCents) || other.unitCents == unitCents)&&(identical(other.lineTotalCents, lineTotalCents) || other.lineTotalCents == lineTotalCents)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.frequencyWeeks, frequencyWeeks) || other.frequencyWeeks == frequencyWeeks)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.isRx, isRx) || other.isRx == isRx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitCents,lineTotalCents,isSubscribed,frequencyWeeks,variantId,isRx);

@override
String toString() {
  return 'LineItem(productId: $productId, productName: $productName, quantity: $quantity, unitCents: $unitCents, lineTotalCents: $lineTotalCents, isSubscribed: $isSubscribed, frequencyWeeks: $frequencyWeeks, variantId: $variantId, isRx: $isRx)';
}


}

/// @nodoc
abstract mixin class $LineItemCopyWith<$Res>  {
  factory $LineItemCopyWith(LineItem value, $Res Function(LineItem) _then) = _$LineItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity, int unitCents, int lineTotalCents, bool isSubscribed, int frequencyWeeks, String? variantId, bool isRx
});




}
/// @nodoc
class _$LineItemCopyWithImpl<$Res>
    implements $LineItemCopyWith<$Res> {
  _$LineItemCopyWithImpl(this._self, this._then);

  final LineItem _self;
  final $Res Function(LineItem) _then;

/// Create a copy of LineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitCents = null,Object? lineTotalCents = null,Object? isSubscribed = null,Object? frequencyWeeks = null,Object? variantId = freezed,Object? isRx = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitCents: null == unitCents ? _self.unitCents : unitCents // ignore: cast_nullable_to_non_nullable
as int,lineTotalCents: null == lineTotalCents ? _self.lineTotalCents : lineTotalCents // ignore: cast_nullable_to_non_nullable
as int,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,frequencyWeeks: null == frequencyWeeks ? _self.frequencyWeeks : frequencyWeeks // ignore: cast_nullable_to_non_nullable
as int,variantId: freezed == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String?,isRx: null == isRx ? _self.isRx : isRx // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LineItem].
extension LineItemPatterns on LineItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineItem value)  $default,){
final _that = this;
switch (_that) {
case _LineItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineItem value)?  $default,){
final _that = this;
switch (_that) {
case _LineItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitCents,  int lineTotalCents,  bool isSubscribed,  int frequencyWeeks,  String? variantId,  bool isRx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCents,_that.lineTotalCents,_that.isSubscribed,_that.frequencyWeeks,_that.variantId,_that.isRx);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitCents,  int lineTotalCents,  bool isSubscribed,  int frequencyWeeks,  String? variantId,  bool isRx)  $default,) {final _that = this;
switch (_that) {
case _LineItem():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCents,_that.lineTotalCents,_that.isSubscribed,_that.frequencyWeeks,_that.variantId,_that.isRx);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  int quantity,  int unitCents,  int lineTotalCents,  bool isSubscribed,  int frequencyWeeks,  String? variantId,  bool isRx)?  $default,) {final _that = this;
switch (_that) {
case _LineItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCents,_that.lineTotalCents,_that.isSubscribed,_that.frequencyWeeks,_that.variantId,_that.isRx);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LineItem implements LineItem {
  const _LineItem({required this.productId, required this.productName, required this.quantity, required this.unitCents, required this.lineTotalCents, required this.isSubscribed, required this.frequencyWeeks, this.variantId, this.isRx = false});
  factory _LineItem.fromJson(Map<String, dynamic> json) => _$LineItemFromJson(json);

@override final  String productId;
@override final  String productName;
@override final  int quantity;
@override final  int unitCents;
@override final  int lineTotalCents;
@override final  bool isSubscribed;
@override final  int frequencyWeeks;
@override final  String? variantId;
@override@JsonKey() final  bool isRx;

/// Create a copy of LineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineItemCopyWith<_LineItem> get copyWith => __$LineItemCopyWithImpl<_LineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LineItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCents, unitCents) || other.unitCents == unitCents)&&(identical(other.lineTotalCents, lineTotalCents) || other.lineTotalCents == lineTotalCents)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.frequencyWeeks, frequencyWeeks) || other.frequencyWeeks == frequencyWeeks)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.isRx, isRx) || other.isRx == isRx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitCents,lineTotalCents,isSubscribed,frequencyWeeks,variantId,isRx);

@override
String toString() {
  return 'LineItem(productId: $productId, productName: $productName, quantity: $quantity, unitCents: $unitCents, lineTotalCents: $lineTotalCents, isSubscribed: $isSubscribed, frequencyWeeks: $frequencyWeeks, variantId: $variantId, isRx: $isRx)';
}


}

/// @nodoc
abstract mixin class _$LineItemCopyWith<$Res> implements $LineItemCopyWith<$Res> {
  factory _$LineItemCopyWith(_LineItem value, $Res Function(_LineItem) _then) = __$LineItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity, int unitCents, int lineTotalCents, bool isSubscribed, int frequencyWeeks, String? variantId, bool isRx
});




}
/// @nodoc
class __$LineItemCopyWithImpl<$Res>
    implements _$LineItemCopyWith<$Res> {
  __$LineItemCopyWithImpl(this._self, this._then);

  final _LineItem _self;
  final $Res Function(_LineItem) _then;

/// Create a copy of LineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitCents = null,Object? lineTotalCents = null,Object? isSubscribed = null,Object? frequencyWeeks = null,Object? variantId = freezed,Object? isRx = null,}) {
  return _then(_LineItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitCents: null == unitCents ? _self.unitCents : unitCents // ignore: cast_nullable_to_non_nullable
as int,lineTotalCents: null == lineTotalCents ? _self.lineTotalCents : lineTotalCents // ignore: cast_nullable_to_non_nullable
as int,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,frequencyWeeks: null == frequencyWeeks ? _self.frequencyWeeks : frequencyWeeks // ignore: cast_nullable_to_non_nullable
as int,variantId: freezed == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String?,isRx: null == isRx ? _self.isRx : isRx // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MarketplaceOrder {

 String get id; String get buyerId; String get shopId; String get title; int get amountCents; String get currency; OrderStatus get status; PaymentMethod get paymentMethod; PaymentStatus get paymentStatus; String? get stripePaymentIntentId; List<LineItem> get lineItems; String? get shippingTrackingNumber; String? get shippingTrackingUrl; String? get shippingCarrier; DateTime? get shippedAt; DateTime get createdAt; DateTime? get updatedAt;
/// Create a copy of MarketplaceOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketplaceOrderCopyWith<MarketplaceOrder> get copyWith => _$MarketplaceOrderCopyWithImpl<MarketplaceOrder>(this as MarketplaceOrder, _$identity);

  /// Serializes this MarketplaceOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketplaceOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&const DeepCollectionEquality().equals(other.lineItems, lineItems)&&(identical(other.shippingTrackingNumber, shippingTrackingNumber) || other.shippingTrackingNumber == shippingTrackingNumber)&&(identical(other.shippingTrackingUrl, shippingTrackingUrl) || other.shippingTrackingUrl == shippingTrackingUrl)&&(identical(other.shippingCarrier, shippingCarrier) || other.shippingCarrier == shippingCarrier)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buyerId,shopId,title,amountCents,currency,status,paymentMethod,paymentStatus,stripePaymentIntentId,const DeepCollectionEquality().hash(lineItems),shippingTrackingNumber,shippingTrackingUrl,shippingCarrier,shippedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MarketplaceOrder(id: $id, buyerId: $buyerId, shopId: $shopId, title: $title, amountCents: $amountCents, currency: $currency, status: $status, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, stripePaymentIntentId: $stripePaymentIntentId, lineItems: $lineItems, shippingTrackingNumber: $shippingTrackingNumber, shippingTrackingUrl: $shippingTrackingUrl, shippingCarrier: $shippingCarrier, shippedAt: $shippedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MarketplaceOrderCopyWith<$Res>  {
  factory $MarketplaceOrderCopyWith(MarketplaceOrder value, $Res Function(MarketplaceOrder) _then) = _$MarketplaceOrderCopyWithImpl;
@useResult
$Res call({
 String id, String buyerId, String shopId, String title, int amountCents, String currency, OrderStatus status, PaymentMethod paymentMethod, PaymentStatus paymentStatus, String? stripePaymentIntentId, List<LineItem> lineItems, String? shippingTrackingNumber, String? shippingTrackingUrl, String? shippingCarrier, DateTime? shippedAt, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$MarketplaceOrderCopyWithImpl<$Res>
    implements $MarketplaceOrderCopyWith<$Res> {
  _$MarketplaceOrderCopyWithImpl(this._self, this._then);

  final MarketplaceOrder _self;
  final $Res Function(MarketplaceOrder) _then;

/// Create a copy of MarketplaceOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buyerId = null,Object? shopId = null,Object? title = null,Object? amountCents = null,Object? currency = null,Object? status = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? stripePaymentIntentId = freezed,Object? lineItems = null,Object? shippingTrackingNumber = freezed,Object? shippingTrackingUrl = freezed,Object? shippingCarrier = freezed,Object? shippedAt = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,stripePaymentIntentId: freezed == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,lineItems: null == lineItems ? _self.lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<LineItem>,shippingTrackingNumber: freezed == shippingTrackingNumber ? _self.shippingTrackingNumber : shippingTrackingNumber // ignore: cast_nullable_to_non_nullable
as String?,shippingTrackingUrl: freezed == shippingTrackingUrl ? _self.shippingTrackingUrl : shippingTrackingUrl // ignore: cast_nullable_to_non_nullable
as String?,shippingCarrier: freezed == shippingCarrier ? _self.shippingCarrier : shippingCarrier // ignore: cast_nullable_to_non_nullable
as String?,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketplaceOrder].
extension MarketplaceOrderPatterns on MarketplaceOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketplaceOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketplaceOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketplaceOrder value)  $default,){
final _that = this;
switch (_that) {
case _MarketplaceOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketplaceOrder value)?  $default,){
final _that = this;
switch (_that) {
case _MarketplaceOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buyerId,  String shopId,  String title,  int amountCents,  String currency,  OrderStatus status,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentIntentId,  List<LineItem> lineItems,  String? shippingTrackingNumber,  String? shippingTrackingUrl,  String? shippingCarrier,  DateTime? shippedAt,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketplaceOrder() when $default != null:
return $default(_that.id,_that.buyerId,_that.shopId,_that.title,_that.amountCents,_that.currency,_that.status,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentIntentId,_that.lineItems,_that.shippingTrackingNumber,_that.shippingTrackingUrl,_that.shippingCarrier,_that.shippedAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buyerId,  String shopId,  String title,  int amountCents,  String currency,  OrderStatus status,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentIntentId,  List<LineItem> lineItems,  String? shippingTrackingNumber,  String? shippingTrackingUrl,  String? shippingCarrier,  DateTime? shippedAt,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MarketplaceOrder():
return $default(_that.id,_that.buyerId,_that.shopId,_that.title,_that.amountCents,_that.currency,_that.status,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentIntentId,_that.lineItems,_that.shippingTrackingNumber,_that.shippingTrackingUrl,_that.shippingCarrier,_that.shippedAt,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buyerId,  String shopId,  String title,  int amountCents,  String currency,  OrderStatus status,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentIntentId,  List<LineItem> lineItems,  String? shippingTrackingNumber,  String? shippingTrackingUrl,  String? shippingCarrier,  DateTime? shippedAt,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MarketplaceOrder() when $default != null:
return $default(_that.id,_that.buyerId,_that.shopId,_that.title,_that.amountCents,_that.currency,_that.status,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentIntentId,_that.lineItems,_that.shippingTrackingNumber,_that.shippingTrackingUrl,_that.shippingCarrier,_that.shippedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarketplaceOrder extends MarketplaceOrder {
  const _MarketplaceOrder({required this.id, required this.buyerId, required this.shopId, required this.title, required this.amountCents, required this.currency, required this.status, this.paymentMethod = PaymentMethod.stripe, this.paymentStatus = PaymentStatus.pending, this.stripePaymentIntentId, required final  List<LineItem> lineItems, this.shippingTrackingNumber, this.shippingTrackingUrl, this.shippingCarrier, this.shippedAt, required this.createdAt, this.updatedAt}): _lineItems = lineItems,super._();
  factory _MarketplaceOrder.fromJson(Map<String, dynamic> json) => _$MarketplaceOrderFromJson(json);

@override final  String id;
@override final  String buyerId;
@override final  String shopId;
@override final  String title;
@override final  int amountCents;
@override final  String currency;
@override final  OrderStatus status;
@override@JsonKey() final  PaymentMethod paymentMethod;
@override@JsonKey() final  PaymentStatus paymentStatus;
@override final  String? stripePaymentIntentId;
 final  List<LineItem> _lineItems;
@override List<LineItem> get lineItems {
  if (_lineItems is EqualUnmodifiableListView) return _lineItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineItems);
}

@override final  String? shippingTrackingNumber;
@override final  String? shippingTrackingUrl;
@override final  String? shippingCarrier;
@override final  DateTime? shippedAt;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of MarketplaceOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketplaceOrderCopyWith<_MarketplaceOrder> get copyWith => __$MarketplaceOrderCopyWithImpl<_MarketplaceOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarketplaceOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketplaceOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&const DeepCollectionEquality().equals(other._lineItems, _lineItems)&&(identical(other.shippingTrackingNumber, shippingTrackingNumber) || other.shippingTrackingNumber == shippingTrackingNumber)&&(identical(other.shippingTrackingUrl, shippingTrackingUrl) || other.shippingTrackingUrl == shippingTrackingUrl)&&(identical(other.shippingCarrier, shippingCarrier) || other.shippingCarrier == shippingCarrier)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buyerId,shopId,title,amountCents,currency,status,paymentMethod,paymentStatus,stripePaymentIntentId,const DeepCollectionEquality().hash(_lineItems),shippingTrackingNumber,shippingTrackingUrl,shippingCarrier,shippedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MarketplaceOrder(id: $id, buyerId: $buyerId, shopId: $shopId, title: $title, amountCents: $amountCents, currency: $currency, status: $status, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, stripePaymentIntentId: $stripePaymentIntentId, lineItems: $lineItems, shippingTrackingNumber: $shippingTrackingNumber, shippingTrackingUrl: $shippingTrackingUrl, shippingCarrier: $shippingCarrier, shippedAt: $shippedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MarketplaceOrderCopyWith<$Res> implements $MarketplaceOrderCopyWith<$Res> {
  factory _$MarketplaceOrderCopyWith(_MarketplaceOrder value, $Res Function(_MarketplaceOrder) _then) = __$MarketplaceOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String buyerId, String shopId, String title, int amountCents, String currency, OrderStatus status, PaymentMethod paymentMethod, PaymentStatus paymentStatus, String? stripePaymentIntentId, List<LineItem> lineItems, String? shippingTrackingNumber, String? shippingTrackingUrl, String? shippingCarrier, DateTime? shippedAt, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$MarketplaceOrderCopyWithImpl<$Res>
    implements _$MarketplaceOrderCopyWith<$Res> {
  __$MarketplaceOrderCopyWithImpl(this._self, this._then);

  final _MarketplaceOrder _self;
  final $Res Function(_MarketplaceOrder) _then;

/// Create a copy of MarketplaceOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buyerId = null,Object? shopId = null,Object? title = null,Object? amountCents = null,Object? currency = null,Object? status = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? stripePaymentIntentId = freezed,Object? lineItems = null,Object? shippingTrackingNumber = freezed,Object? shippingTrackingUrl = freezed,Object? shippingCarrier = freezed,Object? shippedAt = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_MarketplaceOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,stripePaymentIntentId: freezed == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,lineItems: null == lineItems ? _self._lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<LineItem>,shippingTrackingNumber: freezed == shippingTrackingNumber ? _self.shippingTrackingNumber : shippingTrackingNumber // ignore: cast_nullable_to_non_nullable
as String?,shippingTrackingUrl: freezed == shippingTrackingUrl ? _self.shippingTrackingUrl : shippingTrackingUrl // ignore: cast_nullable_to_non_nullable
as String?,shippingCarrier: freezed == shippingCarrier ? _self.shippingCarrier : shippingCarrier // ignore: cast_nullable_to_non_nullable
as String?,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
