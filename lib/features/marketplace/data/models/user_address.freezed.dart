// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserAddress {

 String get id; String get userId;@JsonKey(name: 'label') AddressLabel get label;@JsonKey(name: 'full_address') String get fullAddress; String get city; String get zone; String get area;@JsonKey(name: 'is_default') bool get isDefault;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of UserAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserAddressCopyWith<UserAddress> get copyWith => _$UserAddressCopyWithImpl<UserAddress>(this as UserAddress, _$identity);

  /// Serializes this UserAddress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.label, label) || other.label == label)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.city, city) || other.city == city)&&(identical(other.zone, zone) || other.zone == zone)&&(identical(other.area, area) || other.area == area)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,label,fullAddress,city,zone,area,isDefault,createdAt);

@override
String toString() {
  return 'UserAddress(id: $id, userId: $userId, label: $label, fullAddress: $fullAddress, city: $city, zone: $zone, area: $area, isDefault: $isDefault, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserAddressCopyWith<$Res>  {
  factory $UserAddressCopyWith(UserAddress value, $Res Function(UserAddress) _then) = _$UserAddressCopyWithImpl;
@useResult
$Res call({
 String id, String userId,@JsonKey(name: 'label') AddressLabel label,@JsonKey(name: 'full_address') String fullAddress, String city, String zone, String area,@JsonKey(name: 'is_default') bool isDefault,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$UserAddressCopyWithImpl<$Res>
    implements $UserAddressCopyWith<$Res> {
  _$UserAddressCopyWithImpl(this._self, this._then);

  final UserAddress _self;
  final $Res Function(UserAddress) _then;

/// Create a copy of UserAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? label = null,Object? fullAddress = null,Object? city = null,Object? zone = null,Object? area = null,Object? isDefault = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as AddressLabel,fullAddress: null == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,zone: null == zone ? _self.zone : zone // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserAddress].
extension UserAddressPatterns on UserAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserAddress value)  $default,){
final _that = this;
switch (_that) {
case _UserAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserAddress value)?  $default,){
final _that = this;
switch (_that) {
case _UserAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId, @JsonKey(name: 'label')  AddressLabel label, @JsonKey(name: 'full_address')  String fullAddress,  String city,  String zone,  String area, @JsonKey(name: 'is_default')  bool isDefault, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserAddress() when $default != null:
return $default(_that.id,_that.userId,_that.label,_that.fullAddress,_that.city,_that.zone,_that.area,_that.isDefault,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId, @JsonKey(name: 'label')  AddressLabel label, @JsonKey(name: 'full_address')  String fullAddress,  String city,  String zone,  String area, @JsonKey(name: 'is_default')  bool isDefault, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserAddress():
return $default(_that.id,_that.userId,_that.label,_that.fullAddress,_that.city,_that.zone,_that.area,_that.isDefault,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId, @JsonKey(name: 'label')  AddressLabel label, @JsonKey(name: 'full_address')  String fullAddress,  String city,  String zone,  String area, @JsonKey(name: 'is_default')  bool isDefault, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserAddress() when $default != null:
return $default(_that.id,_that.userId,_that.label,_that.fullAddress,_that.city,_that.zone,_that.area,_that.isDefault,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserAddress extends UserAddress {
  const _UserAddress({required this.id, required this.userId, @JsonKey(name: 'label') required this.label, @JsonKey(name: 'full_address') required this.fullAddress, required this.city, required this.zone, required this.area, @JsonKey(name: 'is_default') required this.isDefault, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _UserAddress.fromJson(Map<String, dynamic> json) => _$UserAddressFromJson(json);

@override final  String id;
@override final  String userId;
@override@JsonKey(name: 'label') final  AddressLabel label;
@override@JsonKey(name: 'full_address') final  String fullAddress;
@override final  String city;
@override final  String zone;
@override final  String area;
@override@JsonKey(name: 'is_default') final  bool isDefault;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of UserAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserAddressCopyWith<_UserAddress> get copyWith => __$UserAddressCopyWithImpl<_UserAddress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserAddressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.label, label) || other.label == label)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.city, city) || other.city == city)&&(identical(other.zone, zone) || other.zone == zone)&&(identical(other.area, area) || other.area == area)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,label,fullAddress,city,zone,area,isDefault,createdAt);

@override
String toString() {
  return 'UserAddress(id: $id, userId: $userId, label: $label, fullAddress: $fullAddress, city: $city, zone: $zone, area: $area, isDefault: $isDefault, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserAddressCopyWith<$Res> implements $UserAddressCopyWith<$Res> {
  factory _$UserAddressCopyWith(_UserAddress value, $Res Function(_UserAddress) _then) = __$UserAddressCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId,@JsonKey(name: 'label') AddressLabel label,@JsonKey(name: 'full_address') String fullAddress, String city, String zone, String area,@JsonKey(name: 'is_default') bool isDefault,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$UserAddressCopyWithImpl<$Res>
    implements _$UserAddressCopyWith<$Res> {
  __$UserAddressCopyWithImpl(this._self, this._then);

  final _UserAddress _self;
  final $Res Function(_UserAddress) _then;

/// Create a copy of UserAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? label = null,Object? fullAddress = null,Object? city = null,Object? zone = null,Object? area = null,Object? isDefault = null,Object? createdAt = null,}) {
  return _then(_UserAddress(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as AddressLabel,fullAddress: null == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,zone: null == zone ? _self.zone : zone // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
