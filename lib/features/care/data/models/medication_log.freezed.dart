// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MedicationLog {

 String get id; String get medicalRecordId; String get petId; DateTime get givenAt; String? get notes;
/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationLogCopyWith<MedicationLog> get copyWith => _$MedicationLogCopyWithImpl<MedicationLog>(this as MedicationLog, _$identity);

  /// Serializes this MedicationLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationLog&&(identical(other.id, id) || other.id == id)&&(identical(other.medicalRecordId, medicalRecordId) || other.medicalRecordId == medicalRecordId)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.givenAt, givenAt) || other.givenAt == givenAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicalRecordId,petId,givenAt,notes);

@override
String toString() {
  return 'MedicationLog(id: $id, medicalRecordId: $medicalRecordId, petId: $petId, givenAt: $givenAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MedicationLogCopyWith<$Res>  {
  factory $MedicationLogCopyWith(MedicationLog value, $Res Function(MedicationLog) _then) = _$MedicationLogCopyWithImpl;
@useResult
$Res call({
 String id, String medicalRecordId, String petId, DateTime givenAt, String? notes
});




}
/// @nodoc
class _$MedicationLogCopyWithImpl<$Res>
    implements $MedicationLogCopyWith<$Res> {
  _$MedicationLogCopyWithImpl(this._self, this._then);

  final MedicationLog _self;
  final $Res Function(MedicationLog) _then;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medicalRecordId = null,Object? petId = null,Object? givenAt = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicalRecordId: null == medicalRecordId ? _self.medicalRecordId : medicalRecordId // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationLog].
extension MedicationLogPatterns on MedicationLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationLog value)  $default,){
final _that = this;
switch (_that) {
case _MedicationLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationLog value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String medicalRecordId,  String petId,  DateTime givenAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
return $default(_that.id,_that.medicalRecordId,_that.petId,_that.givenAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String medicalRecordId,  String petId,  DateTime givenAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _MedicationLog():
return $default(_that.id,_that.medicalRecordId,_that.petId,_that.givenAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String medicalRecordId,  String petId,  DateTime givenAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
return $default(_that.id,_that.medicalRecordId,_that.petId,_that.givenAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedicationLog implements MedicationLog {
  const _MedicationLog({required this.id, required this.medicalRecordId, required this.petId, required this.givenAt, this.notes});
  factory _MedicationLog.fromJson(Map<String, dynamic> json) => _$MedicationLogFromJson(json);

@override final  String id;
@override final  String medicalRecordId;
@override final  String petId;
@override final  DateTime givenAt;
@override final  String? notes;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationLogCopyWith<_MedicationLog> get copyWith => __$MedicationLogCopyWithImpl<_MedicationLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicationLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationLog&&(identical(other.id, id) || other.id == id)&&(identical(other.medicalRecordId, medicalRecordId) || other.medicalRecordId == medicalRecordId)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.givenAt, givenAt) || other.givenAt == givenAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicalRecordId,petId,givenAt,notes);

@override
String toString() {
  return 'MedicationLog(id: $id, medicalRecordId: $medicalRecordId, petId: $petId, givenAt: $givenAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$MedicationLogCopyWith<$Res> implements $MedicationLogCopyWith<$Res> {
  factory _$MedicationLogCopyWith(_MedicationLog value, $Res Function(_MedicationLog) _then) = __$MedicationLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String medicalRecordId, String petId, DateTime givenAt, String? notes
});




}
/// @nodoc
class __$MedicationLogCopyWithImpl<$Res>
    implements _$MedicationLogCopyWith<$Res> {
  __$MedicationLogCopyWithImpl(this._self, this._then);

  final _MedicationLog _self;
  final $Res Function(_MedicationLog) _then;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medicalRecordId = null,Object? petId = null,Object? givenAt = null,Object? notes = freezed,}) {
  return _then(_MedicationLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicalRecordId: null == medicalRecordId ? _self.medicalRecordId : medicalRecordId // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,givenAt: null == givenAt ? _self.givenAt : givenAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
