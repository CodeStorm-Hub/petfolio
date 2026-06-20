// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playdate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Playdate {

 String get id; String get matchId; String get proposedByPetId; DateTime get scheduledAt; String? get locationName; PlaydateStatus get status; DateTime? get createdAt;
/// Create a copy of Playdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaydateCopyWith<Playdate> get copyWith => _$PlaydateCopyWithImpl<Playdate>(this as Playdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Playdate&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.proposedByPetId, proposedByPetId) || other.proposedByPetId == proposedByPetId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,matchId,proposedByPetId,scheduledAt,locationName,status,createdAt);

@override
String toString() {
  return 'Playdate(id: $id, matchId: $matchId, proposedByPetId: $proposedByPetId, scheduledAt: $scheduledAt, locationName: $locationName, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlaydateCopyWith<$Res>  {
  factory $PlaydateCopyWith(Playdate value, $Res Function(Playdate) _then) = _$PlaydateCopyWithImpl;
@useResult
$Res call({
 String id, String matchId, String proposedByPetId, DateTime scheduledAt, String? locationName, PlaydateStatus status, DateTime? createdAt
});




}
/// @nodoc
class _$PlaydateCopyWithImpl<$Res>
    implements $PlaydateCopyWith<$Res> {
  _$PlaydateCopyWithImpl(this._self, this._then);

  final Playdate _self;
  final $Res Function(Playdate) _then;

/// Create a copy of Playdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? proposedByPetId = null,Object? scheduledAt = null,Object? locationName = freezed,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,proposedByPetId: null == proposedByPetId ? _self.proposedByPetId : proposedByPetId // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaydateStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Playdate].
extension PlaydatePatterns on Playdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Playdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Playdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Playdate value)  $default,){
final _that = this;
switch (_that) {
case _Playdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Playdate value)?  $default,){
final _that = this;
switch (_that) {
case _Playdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchId,  String proposedByPetId,  DateTime scheduledAt,  String? locationName,  PlaydateStatus status,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Playdate() when $default != null:
return $default(_that.id,_that.matchId,_that.proposedByPetId,_that.scheduledAt,_that.locationName,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchId,  String proposedByPetId,  DateTime scheduledAt,  String? locationName,  PlaydateStatus status,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Playdate():
return $default(_that.id,_that.matchId,_that.proposedByPetId,_that.scheduledAt,_that.locationName,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchId,  String proposedByPetId,  DateTime scheduledAt,  String? locationName,  PlaydateStatus status,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Playdate() when $default != null:
return $default(_that.id,_that.matchId,_that.proposedByPetId,_that.scheduledAt,_that.locationName,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Playdate extends Playdate {
  const _Playdate({required this.id, required this.matchId, required this.proposedByPetId, required this.scheduledAt, this.locationName, this.status = PlaydateStatus.proposed, this.createdAt}): super._();
  

@override final  String id;
@override final  String matchId;
@override final  String proposedByPetId;
@override final  DateTime scheduledAt;
@override final  String? locationName;
@override@JsonKey() final  PlaydateStatus status;
@override final  DateTime? createdAt;

/// Create a copy of Playdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaydateCopyWith<_Playdate> get copyWith => __$PlaydateCopyWithImpl<_Playdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Playdate&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.proposedByPetId, proposedByPetId) || other.proposedByPetId == proposedByPetId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,matchId,proposedByPetId,scheduledAt,locationName,status,createdAt);

@override
String toString() {
  return 'Playdate(id: $id, matchId: $matchId, proposedByPetId: $proposedByPetId, scheduledAt: $scheduledAt, locationName: $locationName, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlaydateCopyWith<$Res> implements $PlaydateCopyWith<$Res> {
  factory _$PlaydateCopyWith(_Playdate value, $Res Function(_Playdate) _then) = __$PlaydateCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchId, String proposedByPetId, DateTime scheduledAt, String? locationName, PlaydateStatus status, DateTime? createdAt
});




}
/// @nodoc
class __$PlaydateCopyWithImpl<$Res>
    implements _$PlaydateCopyWith<$Res> {
  __$PlaydateCopyWithImpl(this._self, this._then);

  final _Playdate _self;
  final $Res Function(_Playdate) _then;

/// Create a copy of Playdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? proposedByPetId = null,Object? scheduledAt = null,Object? locationName = freezed,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_Playdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,proposedByPetId: null == proposedByPetId ? _self.proposedByPetId : proposedByPetId // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaydateStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
