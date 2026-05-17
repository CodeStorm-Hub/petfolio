// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_geo_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PetGeoPoint {

 double get longitude; double get latitude;
/// Create a copy of PetGeoPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetGeoPointCopyWith<PetGeoPoint> get copyWith => _$PetGeoPointCopyWithImpl<PetGeoPoint>(this as PetGeoPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetGeoPoint&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude));
}


@override
int get hashCode => Object.hash(runtimeType,longitude,latitude);

@override
String toString() {
  return 'PetGeoPoint(longitude: $longitude, latitude: $latitude)';
}


}

/// @nodoc
abstract mixin class $PetGeoPointCopyWith<$Res>  {
  factory $PetGeoPointCopyWith(PetGeoPoint value, $Res Function(PetGeoPoint) _then) = _$PetGeoPointCopyWithImpl;
@useResult
$Res call({
 double longitude, double latitude
});




}
/// @nodoc
class _$PetGeoPointCopyWithImpl<$Res>
    implements $PetGeoPointCopyWith<$Res> {
  _$PetGeoPointCopyWithImpl(this._self, this._then);

  final PetGeoPoint _self;
  final $Res Function(PetGeoPoint) _then;

/// Create a copy of PetGeoPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? longitude = null,Object? latitude = null,}) {
  return _then(_self.copyWith(
longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PetGeoPoint].
extension PetGeoPointPatterns on PetGeoPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetGeoPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetGeoPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetGeoPoint value)  $default,){
final _that = this;
switch (_that) {
case _PetGeoPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetGeoPoint value)?  $default,){
final _that = this;
switch (_that) {
case _PetGeoPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double longitude,  double latitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetGeoPoint() when $default != null:
return $default(_that.longitude,_that.latitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double longitude,  double latitude)  $default,) {final _that = this;
switch (_that) {
case _PetGeoPoint():
return $default(_that.longitude,_that.latitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double longitude,  double latitude)?  $default,) {final _that = this;
switch (_that) {
case _PetGeoPoint() when $default != null:
return $default(_that.longitude,_that.latitude);case _:
  return null;

}
}

}

/// @nodoc


class _PetGeoPoint implements PetGeoPoint {
  const _PetGeoPoint({required this.longitude, required this.latitude});
  

@override final  double longitude;
@override final  double latitude;

/// Create a copy of PetGeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetGeoPointCopyWith<_PetGeoPoint> get copyWith => __$PetGeoPointCopyWithImpl<_PetGeoPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetGeoPoint&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude));
}


@override
int get hashCode => Object.hash(runtimeType,longitude,latitude);

@override
String toString() {
  return 'PetGeoPoint(longitude: $longitude, latitude: $latitude)';
}


}

/// @nodoc
abstract mixin class _$PetGeoPointCopyWith<$Res> implements $PetGeoPointCopyWith<$Res> {
  factory _$PetGeoPointCopyWith(_PetGeoPoint value, $Res Function(_PetGeoPoint) _then) = __$PetGeoPointCopyWithImpl;
@override @useResult
$Res call({
 double longitude, double latitude
});




}
/// @nodoc
class __$PetGeoPointCopyWithImpl<$Res>
    implements _$PetGeoPointCopyWith<$Res> {
  __$PetGeoPointCopyWithImpl(this._self, this._then);

  final _PetGeoPoint _self;
  final $Res Function(_PetGeoPoint) _then;

/// Create a copy of PetGeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? longitude = null,Object? latitude = null,}) {
  return _then(_PetGeoPoint(
longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
