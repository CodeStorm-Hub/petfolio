// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vendor_ledger.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VendorLedger {

 String get id; String get shopId; String get orderId; int get orderTotalCents; int get platformFeeCents; int get vendorEarningsCents; LedgerStatus get status; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of VendorLedger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorLedgerCopyWith<VendorLedger> get copyWith => _$VendorLedgerCopyWithImpl<VendorLedger>(this as VendorLedger, _$identity);

  /// Serializes this VendorLedger to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorLedger&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderTotalCents, orderTotalCents) || other.orderTotalCents == orderTotalCents)&&(identical(other.platformFeeCents, platformFeeCents) || other.platformFeeCents == platformFeeCents)&&(identical(other.vendorEarningsCents, vendorEarningsCents) || other.vendorEarningsCents == vendorEarningsCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,orderId,orderTotalCents,platformFeeCents,vendorEarningsCents,status,createdAt,updatedAt);

@override
String toString() {
  return 'VendorLedger(id: $id, shopId: $shopId, orderId: $orderId, orderTotalCents: $orderTotalCents, platformFeeCents: $platformFeeCents, vendorEarningsCents: $vendorEarningsCents, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $VendorLedgerCopyWith<$Res>  {
  factory $VendorLedgerCopyWith(VendorLedger value, $Res Function(VendorLedger) _then) = _$VendorLedgerCopyWithImpl;
@useResult
$Res call({
 String id, String shopId, String orderId, int orderTotalCents, int platformFeeCents, int vendorEarningsCents, LedgerStatus status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$VendorLedgerCopyWithImpl<$Res>
    implements $VendorLedgerCopyWith<$Res> {
  _$VendorLedgerCopyWithImpl(this._self, this._then);

  final VendorLedger _self;
  final $Res Function(VendorLedger) _then;

/// Create a copy of VendorLedger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shopId = null,Object? orderId = null,Object? orderTotalCents = null,Object? platformFeeCents = null,Object? vendorEarningsCents = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderTotalCents: null == orderTotalCents ? _self.orderTotalCents : orderTotalCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,vendorEarningsCents: null == vendorEarningsCents ? _self.vendorEarningsCents : vendorEarningsCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LedgerStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VendorLedger].
extension VendorLedgerPatterns on VendorLedger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VendorLedger value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VendorLedger() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VendorLedger value)  $default,){
final _that = this;
switch (_that) {
case _VendorLedger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VendorLedger value)?  $default,){
final _that = this;
switch (_that) {
case _VendorLedger() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String shopId,  String orderId,  int orderTotalCents,  int platformFeeCents,  int vendorEarningsCents,  LedgerStatus status,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VendorLedger() when $default != null:
return $default(_that.id,_that.shopId,_that.orderId,_that.orderTotalCents,_that.platformFeeCents,_that.vendorEarningsCents,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String shopId,  String orderId,  int orderTotalCents,  int platformFeeCents,  int vendorEarningsCents,  LedgerStatus status,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _VendorLedger():
return $default(_that.id,_that.shopId,_that.orderId,_that.orderTotalCents,_that.platformFeeCents,_that.vendorEarningsCents,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String shopId,  String orderId,  int orderTotalCents,  int platformFeeCents,  int vendorEarningsCents,  LedgerStatus status,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _VendorLedger() when $default != null:
return $default(_that.id,_that.shopId,_that.orderId,_that.orderTotalCents,_that.platformFeeCents,_that.vendorEarningsCents,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VendorLedger extends VendorLedger {
  const _VendorLedger({required this.id, required this.shopId, required this.orderId, required this.orderTotalCents, required this.platformFeeCents, required this.vendorEarningsCents, required this.status, required this.createdAt, required this.updatedAt}): super._();
  factory _VendorLedger.fromJson(Map<String, dynamic> json) => _$VendorLedgerFromJson(json);

@override final  String id;
@override final  String shopId;
@override final  String orderId;
@override final  int orderTotalCents;
@override final  int platformFeeCents;
@override final  int vendorEarningsCents;
@override final  LedgerStatus status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of VendorLedger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VendorLedgerCopyWith<_VendorLedger> get copyWith => __$VendorLedgerCopyWithImpl<_VendorLedger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VendorLedgerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VendorLedger&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderTotalCents, orderTotalCents) || other.orderTotalCents == orderTotalCents)&&(identical(other.platformFeeCents, platformFeeCents) || other.platformFeeCents == platformFeeCents)&&(identical(other.vendorEarningsCents, vendorEarningsCents) || other.vendorEarningsCents == vendorEarningsCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,orderId,orderTotalCents,platformFeeCents,vendorEarningsCents,status,createdAt,updatedAt);

@override
String toString() {
  return 'VendorLedger(id: $id, shopId: $shopId, orderId: $orderId, orderTotalCents: $orderTotalCents, platformFeeCents: $platformFeeCents, vendorEarningsCents: $vendorEarningsCents, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$VendorLedgerCopyWith<$Res> implements $VendorLedgerCopyWith<$Res> {
  factory _$VendorLedgerCopyWith(_VendorLedger value, $Res Function(_VendorLedger) _then) = __$VendorLedgerCopyWithImpl;
@override @useResult
$Res call({
 String id, String shopId, String orderId, int orderTotalCents, int platformFeeCents, int vendorEarningsCents, LedgerStatus status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$VendorLedgerCopyWithImpl<$Res>
    implements _$VendorLedgerCopyWith<$Res> {
  __$VendorLedgerCopyWithImpl(this._self, this._then);

  final _VendorLedger _self;
  final $Res Function(_VendorLedger) _then;

/// Create a copy of VendorLedger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shopId = null,Object? orderId = null,Object? orderTotalCents = null,Object? platformFeeCents = null,Object? vendorEarningsCents = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_VendorLedger(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderTotalCents: null == orderTotalCents ? _self.orderTotalCents : orderTotalCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,vendorEarningsCents: null == vendorEarningsCents ? _self.vendorEarningsCents : vendorEarningsCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LedgerStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
