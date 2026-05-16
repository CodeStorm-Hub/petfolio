// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_mutual_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PetMutualMatch {

 String get id; String get petAId; String get petBId; DateTime get createdAt;
/// Create a copy of PetMutualMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetMutualMatchCopyWith<PetMutualMatch> get copyWith => _$PetMutualMatchCopyWithImpl<PetMutualMatch>(this as PetMutualMatch, _$identity);

  /// Serializes this PetMutualMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetMutualMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.petAId, petAId) || other.petAId == petAId)&&(identical(other.petBId, petBId) || other.petBId == petBId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petAId,petBId,createdAt);

@override
String toString() {
  return 'PetMutualMatch(id: $id, petAId: $petAId, petBId: $petBId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PetMutualMatchCopyWith<$Res>  {
  factory $PetMutualMatchCopyWith(PetMutualMatch value, $Res Function(PetMutualMatch) _then) = _$PetMutualMatchCopyWithImpl;
@useResult
$Res call({
 String id, String petAId, String petBId, DateTime createdAt
});




}
/// @nodoc
class _$PetMutualMatchCopyWithImpl<$Res>
    implements $PetMutualMatchCopyWith<$Res> {
  _$PetMutualMatchCopyWithImpl(this._self, this._then);

  final PetMutualMatch _self;
  final $Res Function(PetMutualMatch) _then;

/// Create a copy of PetMutualMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? petAId = null,Object? petBId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petAId: null == petAId ? _self.petAId : petAId // ignore: cast_nullable_to_non_nullable
as String,petBId: null == petBId ? _self.petBId : petBId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PetMutualMatch].
extension PetMutualMatchPatterns on PetMutualMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetMutualMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetMutualMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetMutualMatch value)  $default,){
final _that = this;
switch (_that) {
case _PetMutualMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetMutualMatch value)?  $default,){
final _that = this;
switch (_that) {
case _PetMutualMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String petAId,  String petBId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetMutualMatch() when $default != null:
return $default(_that.id,_that.petAId,_that.petBId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String petAId,  String petBId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PetMutualMatch():
return $default(_that.id,_that.petAId,_that.petBId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String petAId,  String petBId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PetMutualMatch() when $default != null:
return $default(_that.id,_that.petAId,_that.petBId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PetMutualMatch implements PetMutualMatch {
  const _PetMutualMatch({required this.id, required this.petAId, required this.petBId, required this.createdAt});
  factory _PetMutualMatch.fromJson(Map<String, dynamic> json) => _$PetMutualMatchFromJson(json);

@override final  String id;
@override final  String petAId;
@override final  String petBId;
@override final  DateTime createdAt;

/// Create a copy of PetMutualMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetMutualMatchCopyWith<_PetMutualMatch> get copyWith => __$PetMutualMatchCopyWithImpl<_PetMutualMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PetMutualMatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetMutualMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.petAId, petAId) || other.petAId == petAId)&&(identical(other.petBId, petBId) || other.petBId == petBId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petAId,petBId,createdAt);

@override
String toString() {
  return 'PetMutualMatch(id: $id, petAId: $petAId, petBId: $petBId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PetMutualMatchCopyWith<$Res> implements $PetMutualMatchCopyWith<$Res> {
  factory _$PetMutualMatchCopyWith(_PetMutualMatch value, $Res Function(_PetMutualMatch) _then) = __$PetMutualMatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String petAId, String petBId, DateTime createdAt
});




}
/// @nodoc
class __$PetMutualMatchCopyWithImpl<$Res>
    implements _$PetMutualMatchCopyWith<$Res> {
  __$PetMutualMatchCopyWithImpl(this._self, this._then);

  final _PetMutualMatch _self;
  final $Res Function(_PetMutualMatch) _then;

/// Create a copy of PetMutualMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? petAId = null,Object? petBId = null,Object? createdAt = null,}) {
  return _then(_PetMutualMatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petAId: null == petAId ? _self.petAId : petAId // ignore: cast_nullable_to_non_nullable
as String,petBId: null == petBId ? _self.petBId : petBId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
