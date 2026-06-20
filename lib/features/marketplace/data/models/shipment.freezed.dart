// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shipment {

 String get id;@JsonKey(name: 'order_id') String get orderId; String? get courier;@JsonKey(name: 'tracking_id') String? get trackingId;@JsonKey(name: 'tracking_url') String? get trackingUrl;@JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending) ShipmentStatus get status;@JsonKey(name: 'shipped_at') DateTime? get shippedAt;@JsonKey(name: 'estimated_delivery_at') DateTime? get estimatedDeliveryAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentCopyWith<Shipment> get copyWith => _$ShipmentCopyWithImpl<Shipment>(this as Shipment, _$identity);

  /// Serializes this Shipment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shipment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.courier, courier) || other.courier == courier)&&(identical(other.trackingId, trackingId) || other.trackingId == trackingId)&&(identical(other.trackingUrl, trackingUrl) || other.trackingUrl == trackingUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,courier,trackingId,trackingUrl,status,shippedAt,estimatedDeliveryAt,createdAt);

@override
String toString() {
  return 'Shipment(id: $id, orderId: $orderId, courier: $courier, trackingId: $trackingId, trackingUrl: $trackingUrl, status: $status, shippedAt: $shippedAt, estimatedDeliveryAt: $estimatedDeliveryAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ShipmentCopyWith<$Res>  {
  factory $ShipmentCopyWith(Shipment value, $Res Function(Shipment) _then) = _$ShipmentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'order_id') String orderId, String? courier,@JsonKey(name: 'tracking_id') String? trackingId,@JsonKey(name: 'tracking_url') String? trackingUrl,@JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending) ShipmentStatus status,@JsonKey(name: 'shipped_at') DateTime? shippedAt,@JsonKey(name: 'estimated_delivery_at') DateTime? estimatedDeliveryAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ShipmentCopyWithImpl<$Res>
    implements $ShipmentCopyWith<$Res> {
  _$ShipmentCopyWithImpl(this._self, this._then);

  final Shipment _self;
  final $Res Function(Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? courier = freezed,Object? trackingId = freezed,Object? trackingUrl = freezed,Object? status = null,Object? shippedAt = freezed,Object? estimatedDeliveryAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,courier: freezed == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as String?,trackingId: freezed == trackingId ? _self.trackingId : trackingId // ignore: cast_nullable_to_non_nullable
as String?,trackingUrl: freezed == trackingUrl ? _self.trackingUrl : trackingUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Shipment].
extension ShipmentPatterns on Shipment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shipment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shipment value)  $default,){
final _that = this;
switch (_that) {
case _Shipment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shipment value)?  $default,){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'order_id')  String orderId,  String? courier, @JsonKey(name: 'tracking_id')  String? trackingId, @JsonKey(name: 'tracking_url')  String? trackingUrl, @JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'shipped_at')  DateTime? shippedAt, @JsonKey(name: 'estimated_delivery_at')  DateTime? estimatedDeliveryAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.orderId,_that.courier,_that.trackingId,_that.trackingUrl,_that.status,_that.shippedAt,_that.estimatedDeliveryAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'order_id')  String orderId,  String? courier, @JsonKey(name: 'tracking_id')  String? trackingId, @JsonKey(name: 'tracking_url')  String? trackingUrl, @JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'shipped_at')  DateTime? shippedAt, @JsonKey(name: 'estimated_delivery_at')  DateTime? estimatedDeliveryAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Shipment():
return $default(_that.id,_that.orderId,_that.courier,_that.trackingId,_that.trackingUrl,_that.status,_that.shippedAt,_that.estimatedDeliveryAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'order_id')  String orderId,  String? courier, @JsonKey(name: 'tracking_id')  String? trackingId, @JsonKey(name: 'tracking_url')  String? trackingUrl, @JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'shipped_at')  DateTime? shippedAt, @JsonKey(name: 'estimated_delivery_at')  DateTime? estimatedDeliveryAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.orderId,_that.courier,_that.trackingId,_that.trackingUrl,_that.status,_that.shippedAt,_that.estimatedDeliveryAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shipment implements Shipment {
  const _Shipment({required this.id, @JsonKey(name: 'order_id') required this.orderId, this.courier, @JsonKey(name: 'tracking_id') this.trackingId, @JsonKey(name: 'tracking_url') this.trackingUrl, @JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending) this.status = ShipmentStatus.pending, @JsonKey(name: 'shipped_at') this.shippedAt, @JsonKey(name: 'estimated_delivery_at') this.estimatedDeliveryAt, @JsonKey(name: 'created_at') this.createdAt});
  factory _Shipment.fromJson(Map<String, dynamic> json) => _$ShipmentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'order_id') final  String orderId;
@override final  String? courier;
@override@JsonKey(name: 'tracking_id') final  String? trackingId;
@override@JsonKey(name: 'tracking_url') final  String? trackingUrl;
@override@JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending) final  ShipmentStatus status;
@override@JsonKey(name: 'shipped_at') final  DateTime? shippedAt;
@override@JsonKey(name: 'estimated_delivery_at') final  DateTime? estimatedDeliveryAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentCopyWith<_Shipment> get copyWith => __$ShipmentCopyWithImpl<_Shipment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShipmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shipment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.courier, courier) || other.courier == courier)&&(identical(other.trackingId, trackingId) || other.trackingId == trackingId)&&(identical(other.trackingUrl, trackingUrl) || other.trackingUrl == trackingUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,courier,trackingId,trackingUrl,status,shippedAt,estimatedDeliveryAt,createdAt);

@override
String toString() {
  return 'Shipment(id: $id, orderId: $orderId, courier: $courier, trackingId: $trackingId, trackingUrl: $trackingUrl, status: $status, shippedAt: $shippedAt, estimatedDeliveryAt: $estimatedDeliveryAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShipmentCopyWith<$Res> implements $ShipmentCopyWith<$Res> {
  factory _$ShipmentCopyWith(_Shipment value, $Res Function(_Shipment) _then) = __$ShipmentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'order_id') String orderId, String? courier,@JsonKey(name: 'tracking_id') String? trackingId,@JsonKey(name: 'tracking_url') String? trackingUrl,@JsonKey(name: 'status', unknownEnumValue: ShipmentStatus.pending) ShipmentStatus status,@JsonKey(name: 'shipped_at') DateTime? shippedAt,@JsonKey(name: 'estimated_delivery_at') DateTime? estimatedDeliveryAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ShipmentCopyWithImpl<$Res>
    implements _$ShipmentCopyWith<$Res> {
  __$ShipmentCopyWithImpl(this._self, this._then);

  final _Shipment _self;
  final $Res Function(_Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? courier = freezed,Object? trackingId = freezed,Object? trackingUrl = freezed,Object? status = null,Object? shippedAt = freezed,Object? estimatedDeliveryAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Shipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,courier: freezed == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as String?,trackingId: freezed == trackingId ? _self.trackingId : trackingId // ignore: cast_nullable_to_non_nullable
as String?,trackingUrl: freezed == trackingUrl ? _self.trackingUrl : trackingUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
