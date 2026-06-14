// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_pedigree.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PetPedigree {

 String get petId; String? get sireRef; String? get damRef; String? get registryName; String? get registryId; String? get titles;
/// Create a copy of PetPedigree
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetPedigreeCopyWith<PetPedigree> get copyWith => _$PetPedigreeCopyWithImpl<PetPedigree>(this as PetPedigree, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetPedigree&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.sireRef, sireRef) || other.sireRef == sireRef)&&(identical(other.damRef, damRef) || other.damRef == damRef)&&(identical(other.registryName, registryName) || other.registryName == registryName)&&(identical(other.registryId, registryId) || other.registryId == registryId)&&(identical(other.titles, titles) || other.titles == titles));
}


@override
int get hashCode => Object.hash(runtimeType,petId,sireRef,damRef,registryName,registryId,titles);

@override
String toString() {
  return 'PetPedigree(petId: $petId, sireRef: $sireRef, damRef: $damRef, registryName: $registryName, registryId: $registryId, titles: $titles)';
}


}

/// @nodoc
abstract mixin class $PetPedigreeCopyWith<$Res>  {
  factory $PetPedigreeCopyWith(PetPedigree value, $Res Function(PetPedigree) _then) = _$PetPedigreeCopyWithImpl;
@useResult
$Res call({
 String petId, String? sireRef, String? damRef, String? registryName, String? registryId, String? titles
});




}
/// @nodoc
class _$PetPedigreeCopyWithImpl<$Res>
    implements $PetPedigreeCopyWith<$Res> {
  _$PetPedigreeCopyWithImpl(this._self, this._then);

  final PetPedigree _self;
  final $Res Function(PetPedigree) _then;

/// Create a copy of PetPedigree
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? petId = null,Object? sireRef = freezed,Object? damRef = freezed,Object? registryName = freezed,Object? registryId = freezed,Object? titles = freezed,}) {
  return _then(_self.copyWith(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,sireRef: freezed == sireRef ? _self.sireRef : sireRef // ignore: cast_nullable_to_non_nullable
as String?,damRef: freezed == damRef ? _self.damRef : damRef // ignore: cast_nullable_to_non_nullable
as String?,registryName: freezed == registryName ? _self.registryName : registryName // ignore: cast_nullable_to_non_nullable
as String?,registryId: freezed == registryId ? _self.registryId : registryId // ignore: cast_nullable_to_non_nullable
as String?,titles: freezed == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PetPedigree].
extension PetPedigreePatterns on PetPedigree {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetPedigree value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetPedigree() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetPedigree value)  $default,){
final _that = this;
switch (_that) {
case _PetPedigree():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetPedigree value)?  $default,){
final _that = this;
switch (_that) {
case _PetPedigree() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String petId,  String? sireRef,  String? damRef,  String? registryName,  String? registryId,  String? titles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetPedigree() when $default != null:
return $default(_that.petId,_that.sireRef,_that.damRef,_that.registryName,_that.registryId,_that.titles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String petId,  String? sireRef,  String? damRef,  String? registryName,  String? registryId,  String? titles)  $default,) {final _that = this;
switch (_that) {
case _PetPedigree():
return $default(_that.petId,_that.sireRef,_that.damRef,_that.registryName,_that.registryId,_that.titles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String petId,  String? sireRef,  String? damRef,  String? registryName,  String? registryId,  String? titles)?  $default,) {final _that = this;
switch (_that) {
case _PetPedigree() when $default != null:
return $default(_that.petId,_that.sireRef,_that.damRef,_that.registryName,_that.registryId,_that.titles);case _:
  return null;

}
}

}

/// @nodoc


class _PetPedigree extends PetPedigree {
  const _PetPedigree({required this.petId, this.sireRef, this.damRef, this.registryName, this.registryId, this.titles}): super._();
  

@override final  String petId;
@override final  String? sireRef;
@override final  String? damRef;
@override final  String? registryName;
@override final  String? registryId;
@override final  String? titles;

/// Create a copy of PetPedigree
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetPedigreeCopyWith<_PetPedigree> get copyWith => __$PetPedigreeCopyWithImpl<_PetPedigree>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetPedigree&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.sireRef, sireRef) || other.sireRef == sireRef)&&(identical(other.damRef, damRef) || other.damRef == damRef)&&(identical(other.registryName, registryName) || other.registryName == registryName)&&(identical(other.registryId, registryId) || other.registryId == registryId)&&(identical(other.titles, titles) || other.titles == titles));
}


@override
int get hashCode => Object.hash(runtimeType,petId,sireRef,damRef,registryName,registryId,titles);

@override
String toString() {
  return 'PetPedigree(petId: $petId, sireRef: $sireRef, damRef: $damRef, registryName: $registryName, registryId: $registryId, titles: $titles)';
}


}

/// @nodoc
abstract mixin class _$PetPedigreeCopyWith<$Res> implements $PetPedigreeCopyWith<$Res> {
  factory _$PetPedigreeCopyWith(_PetPedigree value, $Res Function(_PetPedigree) _then) = __$PetPedigreeCopyWithImpl;
@override @useResult
$Res call({
 String petId, String? sireRef, String? damRef, String? registryName, String? registryId, String? titles
});




}
/// @nodoc
class __$PetPedigreeCopyWithImpl<$Res>
    implements _$PetPedigreeCopyWith<$Res> {
  __$PetPedigreeCopyWithImpl(this._self, this._then);

  final _PetPedigree _self;
  final $Res Function(_PetPedigree) _then;

/// Create a copy of PetPedigree
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? petId = null,Object? sireRef = freezed,Object? damRef = freezed,Object? registryName = freezed,Object? registryId = freezed,Object? titles = freezed,}) {
  return _then(_PetPedigree(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,sireRef: freezed == sireRef ? _self.sireRef : sireRef // ignore: cast_nullable_to_non_nullable
as String?,damRef: freezed == damRef ? _self.damRef : damRef // ignore: cast_nullable_to_non_nullable
as String?,registryName: freezed == registryName ? _self.registryName : registryName // ignore: cast_nullable_to_non_nullable
as String?,registryId: freezed == registryId ? _self.registryId : registryId // ignore: cast_nullable_to_non_nullable
as String?,titles: freezed == titles ? _self.titles : titles // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
