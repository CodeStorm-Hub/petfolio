// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_health_cert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PetHealthCert {

 String get id; String get petId; HealthCertType get certType; String get filePath; bool get verified; DateTime? get expiresAt; DateTime? get createdAt;
/// Create a copy of PetHealthCert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetHealthCertCopyWith<PetHealthCert> get copyWith => _$PetHealthCertCopyWithImpl<PetHealthCert>(this as PetHealthCert, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetHealthCert&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.certType, certType) || other.certType == certType)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,petId,certType,filePath,verified,expiresAt,createdAt);

@override
String toString() {
  return 'PetHealthCert(id: $id, petId: $petId, certType: $certType, filePath: $filePath, verified: $verified, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PetHealthCertCopyWith<$Res>  {
  factory $PetHealthCertCopyWith(PetHealthCert value, $Res Function(PetHealthCert) _then) = _$PetHealthCertCopyWithImpl;
@useResult
$Res call({
 String id, String petId, HealthCertType certType, String filePath, bool verified, DateTime? expiresAt, DateTime? createdAt
});




}
/// @nodoc
class _$PetHealthCertCopyWithImpl<$Res>
    implements $PetHealthCertCopyWith<$Res> {
  _$PetHealthCertCopyWithImpl(this._self, this._then);

  final PetHealthCert _self;
  final $Res Function(PetHealthCert) _then;

/// Create a copy of PetHealthCert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? petId = null,Object? certType = null,Object? filePath = null,Object? verified = null,Object? expiresAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,certType: null == certType ? _self.certType : certType // ignore: cast_nullable_to_non_nullable
as HealthCertType,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PetHealthCert].
extension PetHealthCertPatterns on PetHealthCert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetHealthCert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetHealthCert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetHealthCert value)  $default,){
final _that = this;
switch (_that) {
case _PetHealthCert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetHealthCert value)?  $default,){
final _that = this;
switch (_that) {
case _PetHealthCert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String petId,  HealthCertType certType,  String filePath,  bool verified,  DateTime? expiresAt,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetHealthCert() when $default != null:
return $default(_that.id,_that.petId,_that.certType,_that.filePath,_that.verified,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String petId,  HealthCertType certType,  String filePath,  bool verified,  DateTime? expiresAt,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PetHealthCert():
return $default(_that.id,_that.petId,_that.certType,_that.filePath,_that.verified,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String petId,  HealthCertType certType,  String filePath,  bool verified,  DateTime? expiresAt,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PetHealthCert() when $default != null:
return $default(_that.id,_that.petId,_that.certType,_that.filePath,_that.verified,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _PetHealthCert extends PetHealthCert {
  const _PetHealthCert({required this.id, required this.petId, required this.certType, required this.filePath, this.verified = false, this.expiresAt, this.createdAt}): super._();
  

@override final  String id;
@override final  String petId;
@override final  HealthCertType certType;
@override final  String filePath;
@override@JsonKey() final  bool verified;
@override final  DateTime? expiresAt;
@override final  DateTime? createdAt;

/// Create a copy of PetHealthCert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetHealthCertCopyWith<_PetHealthCert> get copyWith => __$PetHealthCertCopyWithImpl<_PetHealthCert>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetHealthCert&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.certType, certType) || other.certType == certType)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,petId,certType,filePath,verified,expiresAt,createdAt);

@override
String toString() {
  return 'PetHealthCert(id: $id, petId: $petId, certType: $certType, filePath: $filePath, verified: $verified, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PetHealthCertCopyWith<$Res> implements $PetHealthCertCopyWith<$Res> {
  factory _$PetHealthCertCopyWith(_PetHealthCert value, $Res Function(_PetHealthCert) _then) = __$PetHealthCertCopyWithImpl;
@override @useResult
$Res call({
 String id, String petId, HealthCertType certType, String filePath, bool verified, DateTime? expiresAt, DateTime? createdAt
});




}
/// @nodoc
class __$PetHealthCertCopyWithImpl<$Res>
    implements _$PetHealthCertCopyWith<$Res> {
  __$PetHealthCertCopyWithImpl(this._self, this._then);

  final _PetHealthCert _self;
  final $Res Function(_PetHealthCert) _then;

/// Create a copy of PetHealthCert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? petId = null,Object? certType = null,Object? filePath = null,Object? verified = null,Object? expiresAt = freezed,Object? createdAt = freezed,}) {
  return _then(_PetHealthCert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,certType: null == certType ? _self.certType : certType // ignore: cast_nullable_to_non_nullable
as HealthCertType,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
