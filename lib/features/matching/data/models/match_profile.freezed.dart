// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchProfile {

 String get petId; MatchMode get mode; bool get isActive; String? get playStyle; String? get energyLevel; String? get preferredSize; String? get availability;
/// Create a copy of MatchProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchProfileCopyWith<MatchProfile> get copyWith => _$MatchProfileCopyWithImpl<MatchProfile>(this as MatchProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchProfile&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.playStyle, playStyle) || other.playStyle == playStyle)&&(identical(other.energyLevel, energyLevel) || other.energyLevel == energyLevel)&&(identical(other.preferredSize, preferredSize) || other.preferredSize == preferredSize)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,petId,mode,isActive,playStyle,energyLevel,preferredSize,availability);

@override
String toString() {
  return 'MatchProfile(petId: $petId, mode: $mode, isActive: $isActive, playStyle: $playStyle, energyLevel: $energyLevel, preferredSize: $preferredSize, availability: $availability)';
}


}

/// @nodoc
abstract mixin class $MatchProfileCopyWith<$Res>  {
  factory $MatchProfileCopyWith(MatchProfile value, $Res Function(MatchProfile) _then) = _$MatchProfileCopyWithImpl;
@useResult
$Res call({
 String petId, MatchMode mode, bool isActive, String? playStyle, String? energyLevel, String? preferredSize, String? availability
});




}
/// @nodoc
class _$MatchProfileCopyWithImpl<$Res>
    implements $MatchProfileCopyWith<$Res> {
  _$MatchProfileCopyWithImpl(this._self, this._then);

  final MatchProfile _self;
  final $Res Function(MatchProfile) _then;

/// Create a copy of MatchProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? petId = null,Object? mode = null,Object? isActive = null,Object? playStyle = freezed,Object? energyLevel = freezed,Object? preferredSize = freezed,Object? availability = freezed,}) {
  return _then(_self.copyWith(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,playStyle: freezed == playStyle ? _self.playStyle : playStyle // ignore: cast_nullable_to_non_nullable
as String?,energyLevel: freezed == energyLevel ? _self.energyLevel : energyLevel // ignore: cast_nullable_to_non_nullable
as String?,preferredSize: freezed == preferredSize ? _self.preferredSize : preferredSize // ignore: cast_nullable_to_non_nullable
as String?,availability: freezed == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchProfile].
extension MatchProfilePatterns on MatchProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchProfile value)  $default,){
final _that = this;
switch (_that) {
case _MatchProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchProfile value)?  $default,){
final _that = this;
switch (_that) {
case _MatchProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String petId,  MatchMode mode,  bool isActive,  String? playStyle,  String? energyLevel,  String? preferredSize,  String? availability)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchProfile() when $default != null:
return $default(_that.petId,_that.mode,_that.isActive,_that.playStyle,_that.energyLevel,_that.preferredSize,_that.availability);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String petId,  MatchMode mode,  bool isActive,  String? playStyle,  String? energyLevel,  String? preferredSize,  String? availability)  $default,) {final _that = this;
switch (_that) {
case _MatchProfile():
return $default(_that.petId,_that.mode,_that.isActive,_that.playStyle,_that.energyLevel,_that.preferredSize,_that.availability);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String petId,  MatchMode mode,  bool isActive,  String? playStyle,  String? energyLevel,  String? preferredSize,  String? availability)?  $default,) {final _that = this;
switch (_that) {
case _MatchProfile() when $default != null:
return $default(_that.petId,_that.mode,_that.isActive,_that.playStyle,_that.energyLevel,_that.preferredSize,_that.availability);case _:
  return null;

}
}

}

/// @nodoc


class _MatchProfile extends MatchProfile {
  const _MatchProfile({required this.petId, required this.mode, this.isActive = true, this.playStyle, this.energyLevel, this.preferredSize, this.availability}): super._();
  

@override final  String petId;
@override final  MatchMode mode;
@override@JsonKey() final  bool isActive;
@override final  String? playStyle;
@override final  String? energyLevel;
@override final  String? preferredSize;
@override final  String? availability;

/// Create a copy of MatchProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchProfileCopyWith<_MatchProfile> get copyWith => __$MatchProfileCopyWithImpl<_MatchProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchProfile&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.playStyle, playStyle) || other.playStyle == playStyle)&&(identical(other.energyLevel, energyLevel) || other.energyLevel == energyLevel)&&(identical(other.preferredSize, preferredSize) || other.preferredSize == preferredSize)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,petId,mode,isActive,playStyle,energyLevel,preferredSize,availability);

@override
String toString() {
  return 'MatchProfile(petId: $petId, mode: $mode, isActive: $isActive, playStyle: $playStyle, energyLevel: $energyLevel, preferredSize: $preferredSize, availability: $availability)';
}


}

/// @nodoc
abstract mixin class _$MatchProfileCopyWith<$Res> implements $MatchProfileCopyWith<$Res> {
  factory _$MatchProfileCopyWith(_MatchProfile value, $Res Function(_MatchProfile) _then) = __$MatchProfileCopyWithImpl;
@override @useResult
$Res call({
 String petId, MatchMode mode, bool isActive, String? playStyle, String? energyLevel, String? preferredSize, String? availability
});




}
/// @nodoc
class __$MatchProfileCopyWithImpl<$Res>
    implements _$MatchProfileCopyWith<$Res> {
  __$MatchProfileCopyWithImpl(this._self, this._then);

  final _MatchProfile _self;
  final $Res Function(_MatchProfile) _then;

/// Create a copy of MatchProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? petId = null,Object? mode = null,Object? isActive = null,Object? playStyle = freezed,Object? energyLevel = freezed,Object? preferredSize = freezed,Object? availability = freezed,}) {
  return _then(_MatchProfile(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,playStyle: freezed == playStyle ? _self.playStyle : playStyle // ignore: cast_nullable_to_non_nullable
as String?,energyLevel: freezed == energyLevel ? _self.energyLevel : energyLevel // ignore: cast_nullable_to_non_nullable
as String?,preferredSize: freezed == preferredSize ? _self.preferredSize : preferredSize // ignore: cast_nullable_to_non_nullable
as String?,availability: freezed == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
