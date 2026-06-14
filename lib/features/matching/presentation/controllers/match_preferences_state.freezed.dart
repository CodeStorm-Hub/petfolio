// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_preferences_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchPreferencesState {

 MatchMode get mode; List<String> get selectedSpecies; double get maxDistanceMeters; int get ageMinYears; int get ageMaxYears;
/// Create a copy of MatchPreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPreferencesStateCopyWith<MatchPreferencesState> get copyWith => _$MatchPreferencesStateCopyWithImpl<MatchPreferencesState>(this as MatchPreferencesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPreferencesState&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.selectedSpecies, selectedSpecies)&&(identical(other.maxDistanceMeters, maxDistanceMeters) || other.maxDistanceMeters == maxDistanceMeters)&&(identical(other.ageMinYears, ageMinYears) || other.ageMinYears == ageMinYears)&&(identical(other.ageMaxYears, ageMaxYears) || other.ageMaxYears == ageMaxYears));
}


@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(selectedSpecies),maxDistanceMeters,ageMinYears,ageMaxYears);

@override
String toString() {
  return 'MatchPreferencesState(mode: $mode, selectedSpecies: $selectedSpecies, maxDistanceMeters: $maxDistanceMeters, ageMinYears: $ageMinYears, ageMaxYears: $ageMaxYears)';
}


}

/// @nodoc
abstract mixin class $MatchPreferencesStateCopyWith<$Res>  {
  factory $MatchPreferencesStateCopyWith(MatchPreferencesState value, $Res Function(MatchPreferencesState) _then) = _$MatchPreferencesStateCopyWithImpl;
@useResult
$Res call({
 MatchMode mode, List<String> selectedSpecies, double maxDistanceMeters, int ageMinYears, int ageMaxYears
});




}
/// @nodoc
class _$MatchPreferencesStateCopyWithImpl<$Res>
    implements $MatchPreferencesStateCopyWith<$Res> {
  _$MatchPreferencesStateCopyWithImpl(this._self, this._then);

  final MatchPreferencesState _self;
  final $Res Function(MatchPreferencesState) _then;

/// Create a copy of MatchPreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? selectedSpecies = null,Object? maxDistanceMeters = null,Object? ageMinYears = null,Object? ageMaxYears = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,selectedSpecies: null == selectedSpecies ? _self.selectedSpecies : selectedSpecies // ignore: cast_nullable_to_non_nullable
as List<String>,maxDistanceMeters: null == maxDistanceMeters ? _self.maxDistanceMeters : maxDistanceMeters // ignore: cast_nullable_to_non_nullable
as double,ageMinYears: null == ageMinYears ? _self.ageMinYears : ageMinYears // ignore: cast_nullable_to_non_nullable
as int,ageMaxYears: null == ageMaxYears ? _self.ageMaxYears : ageMaxYears // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchPreferencesState].
extension MatchPreferencesStatePatterns on MatchPreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchPreferencesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchPreferencesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchPreferencesState value)  $default,){
final _that = this;
switch (_that) {
case _MatchPreferencesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchPreferencesState value)?  $default,){
final _that = this;
switch (_that) {
case _MatchPreferencesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MatchMode mode,  List<String> selectedSpecies,  double maxDistanceMeters,  int ageMinYears,  int ageMaxYears)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchPreferencesState() when $default != null:
return $default(_that.mode,_that.selectedSpecies,_that.maxDistanceMeters,_that.ageMinYears,_that.ageMaxYears);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MatchMode mode,  List<String> selectedSpecies,  double maxDistanceMeters,  int ageMinYears,  int ageMaxYears)  $default,) {final _that = this;
switch (_that) {
case _MatchPreferencesState():
return $default(_that.mode,_that.selectedSpecies,_that.maxDistanceMeters,_that.ageMinYears,_that.ageMaxYears);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MatchMode mode,  List<String> selectedSpecies,  double maxDistanceMeters,  int ageMinYears,  int ageMaxYears)?  $default,) {final _that = this;
switch (_that) {
case _MatchPreferencesState() when $default != null:
return $default(_that.mode,_that.selectedSpecies,_that.maxDistanceMeters,_that.ageMinYears,_that.ageMaxYears);case _:
  return null;

}
}

}

/// @nodoc


class _MatchPreferencesState implements MatchPreferencesState {
  const _MatchPreferencesState({this.mode = MatchMode.playdate, final  List<String> selectedSpecies = const <String>[], this.maxDistanceMeters = 80467.0, this.ageMinYears = 0, this.ageMaxYears = 30}): _selectedSpecies = selectedSpecies;
  

@override@JsonKey() final  MatchMode mode;
 final  List<String> _selectedSpecies;
@override@JsonKey() List<String> get selectedSpecies {
  if (_selectedSpecies is EqualUnmodifiableListView) return _selectedSpecies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedSpecies);
}

@override@JsonKey() final  double maxDistanceMeters;
@override@JsonKey() final  int ageMinYears;
@override@JsonKey() final  int ageMaxYears;

/// Create a copy of MatchPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchPreferencesStateCopyWith<_MatchPreferencesState> get copyWith => __$MatchPreferencesStateCopyWithImpl<_MatchPreferencesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchPreferencesState&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other._selectedSpecies, _selectedSpecies)&&(identical(other.maxDistanceMeters, maxDistanceMeters) || other.maxDistanceMeters == maxDistanceMeters)&&(identical(other.ageMinYears, ageMinYears) || other.ageMinYears == ageMinYears)&&(identical(other.ageMaxYears, ageMaxYears) || other.ageMaxYears == ageMaxYears));
}


@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(_selectedSpecies),maxDistanceMeters,ageMinYears,ageMaxYears);

@override
String toString() {
  return 'MatchPreferencesState(mode: $mode, selectedSpecies: $selectedSpecies, maxDistanceMeters: $maxDistanceMeters, ageMinYears: $ageMinYears, ageMaxYears: $ageMaxYears)';
}


}

/// @nodoc
abstract mixin class _$MatchPreferencesStateCopyWith<$Res> implements $MatchPreferencesStateCopyWith<$Res> {
  factory _$MatchPreferencesStateCopyWith(_MatchPreferencesState value, $Res Function(_MatchPreferencesState) _then) = __$MatchPreferencesStateCopyWithImpl;
@override @useResult
$Res call({
 MatchMode mode, List<String> selectedSpecies, double maxDistanceMeters, int ageMinYears, int ageMaxYears
});




}
/// @nodoc
class __$MatchPreferencesStateCopyWithImpl<$Res>
    implements _$MatchPreferencesStateCopyWith<$Res> {
  __$MatchPreferencesStateCopyWithImpl(this._self, this._then);

  final _MatchPreferencesState _self;
  final $Res Function(_MatchPreferencesState) _then;

/// Create a copy of MatchPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? selectedSpecies = null,Object? maxDistanceMeters = null,Object? ageMinYears = null,Object? ageMaxYears = null,}) {
  return _then(_MatchPreferencesState(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,selectedSpecies: null == selectedSpecies ? _self._selectedSpecies : selectedSpecies // ignore: cast_nullable_to_non_nullable
as List<String>,maxDistanceMeters: null == maxDistanceMeters ? _self.maxDistanceMeters : maxDistanceMeters // ignore: cast_nullable_to_non_nullable
as double,ageMinYears: null == ageMinYears ? _self.ageMinYears : ageMinYears // ignore: cast_nullable_to_non_nullable
as int,ageMaxYears: null == ageMaxYears ? _self.ageMaxYears : ageMaxYears // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
