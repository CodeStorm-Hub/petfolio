// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_streak.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CareStreak {

@JsonKey(name: 'pet_id') String get petId;@JsonKey(name: 'current_streak') int get currentStreak;@JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson) DateTime? get lastCompletionDate;@JsonKey(name: 'best_streak') int get bestStreak;@JsonKey(name: 'freezes_available') int get freezesAvailable;
/// Create a copy of CareStreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareStreakCopyWith<CareStreak> get copyWith => _$CareStreakCopyWithImpl<CareStreak>(this as CareStreak, _$identity);

  /// Serializes this CareStreak to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareStreak&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.lastCompletionDate, lastCompletionDate) || other.lastCompletionDate == lastCompletionDate)&&(identical(other.bestStreak, bestStreak) || other.bestStreak == bestStreak)&&(identical(other.freezesAvailable, freezesAvailable) || other.freezesAvailable == freezesAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,currentStreak,lastCompletionDate,bestStreak,freezesAvailable);

@override
String toString() {
  return 'CareStreak(petId: $petId, currentStreak: $currentStreak, lastCompletionDate: $lastCompletionDate, bestStreak: $bestStreak, freezesAvailable: $freezesAvailable)';
}


}

/// @nodoc
abstract mixin class $CareStreakCopyWith<$Res>  {
  factory $CareStreakCopyWith(CareStreak value, $Res Function(CareStreak) _then) = _$CareStreakCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'pet_id') String petId,@JsonKey(name: 'current_streak') int currentStreak,@JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson) DateTime? lastCompletionDate,@JsonKey(name: 'best_streak') int bestStreak,@JsonKey(name: 'freezes_available') int freezesAvailable
});




}
/// @nodoc
class _$CareStreakCopyWithImpl<$Res>
    implements $CareStreakCopyWith<$Res> {
  _$CareStreakCopyWithImpl(this._self, this._then);

  final CareStreak _self;
  final $Res Function(CareStreak) _then;

/// Create a copy of CareStreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? petId = null,Object? currentStreak = null,Object? lastCompletionDate = freezed,Object? bestStreak = null,Object? freezesAvailable = null,}) {
  return _then(_self.copyWith(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,lastCompletionDate: freezed == lastCompletionDate ? _self.lastCompletionDate : lastCompletionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,freezesAvailable: null == freezesAvailable ? _self.freezesAvailable : freezesAvailable // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CareStreak].
extension CareStreakPatterns on CareStreak {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareStreak value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareStreak() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareStreak value)  $default,){
final _that = this;
switch (_that) {
case _CareStreak():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareStreak value)?  $default,){
final _that = this;
switch (_that) {
case _CareStreak() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'pet_id')  String petId, @JsonKey(name: 'current_streak')  int currentStreak, @JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson)  DateTime? lastCompletionDate, @JsonKey(name: 'best_streak')  int bestStreak, @JsonKey(name: 'freezes_available')  int freezesAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareStreak() when $default != null:
return $default(_that.petId,_that.currentStreak,_that.lastCompletionDate,_that.bestStreak,_that.freezesAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'pet_id')  String petId, @JsonKey(name: 'current_streak')  int currentStreak, @JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson)  DateTime? lastCompletionDate, @JsonKey(name: 'best_streak')  int bestStreak, @JsonKey(name: 'freezes_available')  int freezesAvailable)  $default,) {final _that = this;
switch (_that) {
case _CareStreak():
return $default(_that.petId,_that.currentStreak,_that.lastCompletionDate,_that.bestStreak,_that.freezesAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'pet_id')  String petId, @JsonKey(name: 'current_streak')  int currentStreak, @JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson)  DateTime? lastCompletionDate, @JsonKey(name: 'best_streak')  int bestStreak, @JsonKey(name: 'freezes_available')  int freezesAvailable)?  $default,) {final _that = this;
switch (_that) {
case _CareStreak() when $default != null:
return $default(_that.petId,_that.currentStreak,_that.lastCompletionDate,_that.bestStreak,_that.freezesAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CareStreak implements CareStreak {
  const _CareStreak({@JsonKey(name: 'pet_id') required this.petId, @JsonKey(name: 'current_streak') required this.currentStreak, @JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson) this.lastCompletionDate, @JsonKey(name: 'best_streak') required this.bestStreak, @JsonKey(name: 'freezes_available') this.freezesAvailable = 2});
  factory _CareStreak.fromJson(Map<String, dynamic> json) => _$CareStreakFromJson(json);

@override@JsonKey(name: 'pet_id') final  String petId;
@override@JsonKey(name: 'current_streak') final  int currentStreak;
@override@JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson) final  DateTime? lastCompletionDate;
@override@JsonKey(name: 'best_streak') final  int bestStreak;
@override@JsonKey(name: 'freezes_available') final  int freezesAvailable;

/// Create a copy of CareStreak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareStreakCopyWith<_CareStreak> get copyWith => __$CareStreakCopyWithImpl<_CareStreak>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CareStreakToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareStreak&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.lastCompletionDate, lastCompletionDate) || other.lastCompletionDate == lastCompletionDate)&&(identical(other.bestStreak, bestStreak) || other.bestStreak == bestStreak)&&(identical(other.freezesAvailable, freezesAvailable) || other.freezesAvailable == freezesAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,currentStreak,lastCompletionDate,bestStreak,freezesAvailable);

@override
String toString() {
  return 'CareStreak(petId: $petId, currentStreak: $currentStreak, lastCompletionDate: $lastCompletionDate, bestStreak: $bestStreak, freezesAvailable: $freezesAvailable)';
}


}

/// @nodoc
abstract mixin class _$CareStreakCopyWith<$Res> implements $CareStreakCopyWith<$Res> {
  factory _$CareStreakCopyWith(_CareStreak value, $Res Function(_CareStreak) _then) = __$CareStreakCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'pet_id') String petId,@JsonKey(name: 'current_streak') int currentStreak,@JsonKey(name: 'last_completion_date', fromJson: _lastCompletionFromJson, toJson: _lastCompletionToJson) DateTime? lastCompletionDate,@JsonKey(name: 'best_streak') int bestStreak,@JsonKey(name: 'freezes_available') int freezesAvailable
});




}
/// @nodoc
class __$CareStreakCopyWithImpl<$Res>
    implements _$CareStreakCopyWith<$Res> {
  __$CareStreakCopyWithImpl(this._self, this._then);

  final _CareStreak _self;
  final $Res Function(_CareStreak) _then;

/// Create a copy of CareStreak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? petId = null,Object? currentStreak = null,Object? lastCompletionDate = freezed,Object? bestStreak = null,Object? freezesAvailable = null,}) {
  return _then(_CareStreak(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,lastCompletionDate: freezed == lastCompletionDate ? _self.lastCompletionDate : lastCompletionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,freezesAvailable: null == freezesAvailable ? _self.freezesAvailable : freezesAvailable // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
