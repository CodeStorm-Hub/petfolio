// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_swipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PetSwipe {

 String get id; String get actorId; String get targetId; SwipeTableAction get action; DateTime get createdAt;
/// Create a copy of PetSwipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetSwipeCopyWith<PetSwipe> get copyWith => _$PetSwipeCopyWithImpl<PetSwipe>(this as PetSwipe, _$identity);

  /// Serializes this PetSwipe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetSwipe&&(identical(other.id, id) || other.id == id)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,actorId,targetId,action,createdAt);

@override
String toString() {
  return 'PetSwipe(id: $id, actorId: $actorId, targetId: $targetId, action: $action, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PetSwipeCopyWith<$Res>  {
  factory $PetSwipeCopyWith(PetSwipe value, $Res Function(PetSwipe) _then) = _$PetSwipeCopyWithImpl;
@useResult
$Res call({
 String id, String actorId, String targetId, SwipeTableAction action, DateTime createdAt
});




}
/// @nodoc
class _$PetSwipeCopyWithImpl<$Res>
    implements $PetSwipeCopyWith<$Res> {
  _$PetSwipeCopyWithImpl(this._self, this._then);

  final PetSwipe _self;
  final $Res Function(PetSwipe) _then;

/// Create a copy of PetSwipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? actorId = null,Object? targetId = null,Object? action = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as SwipeTableAction,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PetSwipe].
extension PetSwipePatterns on PetSwipe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetSwipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetSwipe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetSwipe value)  $default,){
final _that = this;
switch (_that) {
case _PetSwipe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetSwipe value)?  $default,){
final _that = this;
switch (_that) {
case _PetSwipe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String actorId,  String targetId,  SwipeTableAction action,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetSwipe() when $default != null:
return $default(_that.id,_that.actorId,_that.targetId,_that.action,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String actorId,  String targetId,  SwipeTableAction action,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PetSwipe():
return $default(_that.id,_that.actorId,_that.targetId,_that.action,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String actorId,  String targetId,  SwipeTableAction action,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PetSwipe() when $default != null:
return $default(_that.id,_that.actorId,_that.targetId,_that.action,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PetSwipe implements PetSwipe {
  const _PetSwipe({required this.id, required this.actorId, required this.targetId, required this.action, required this.createdAt});
  factory _PetSwipe.fromJson(Map<String, dynamic> json) => _$PetSwipeFromJson(json);

@override final  String id;
@override final  String actorId;
@override final  String targetId;
@override final  SwipeTableAction action;
@override final  DateTime createdAt;

/// Create a copy of PetSwipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetSwipeCopyWith<_PetSwipe> get copyWith => __$PetSwipeCopyWithImpl<_PetSwipe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PetSwipeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetSwipe&&(identical(other.id, id) || other.id == id)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,actorId,targetId,action,createdAt);

@override
String toString() {
  return 'PetSwipe(id: $id, actorId: $actorId, targetId: $targetId, action: $action, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PetSwipeCopyWith<$Res> implements $PetSwipeCopyWith<$Res> {
  factory _$PetSwipeCopyWith(_PetSwipe value, $Res Function(_PetSwipe) _then) = __$PetSwipeCopyWithImpl;
@override @useResult
$Res call({
 String id, String actorId, String targetId, SwipeTableAction action, DateTime createdAt
});




}
/// @nodoc
class __$PetSwipeCopyWithImpl<$Res>
    implements _$PetSwipeCopyWith<$Res> {
  __$PetSwipeCopyWithImpl(this._self, this._then);

  final _PetSwipe _self;
  final $Res Function(_PetSwipe) _then;

/// Create a copy of PetSwipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? actorId = null,Object? targetId = null,Object? action = null,Object? createdAt = null,}) {
  return _then(_PetSwipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as SwipeTableAction,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
