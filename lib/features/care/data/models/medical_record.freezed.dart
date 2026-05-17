// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MedicalRecord {

 String get id; String get petId; MedicalRecordType get recordType; String get name; String? get description; String? get administeredBy; DateTime? get administeredAt; DateTime? get expiresAt; DateTime? get nextDueAt; String? get batchNumber; String? get dosage; String? get frequency; bool get isActive; bool get reminderEnabled; String? get documentUrl; String? get notes; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicalRecordCopyWith<MedicalRecord> get copyWith => _$MedicalRecordCopyWithImpl<MedicalRecord>(this as MedicalRecord, _$identity);

  /// Serializes this MedicalRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.administeredBy, administeredBy) || other.administeredBy == administeredBy)&&(identical(other.administeredAt, administeredAt) || other.administeredAt == administeredAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.nextDueAt, nextDueAt) || other.nextDueAt == nextDueAt)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,recordType,name,description,administeredBy,administeredAt,expiresAt,nextDueAt,batchNumber,dosage,frequency,isActive,reminderEnabled,documentUrl,notes,createdAt,updatedAt);

@override
String toString() {
  return 'MedicalRecord(id: $id, petId: $petId, recordType: $recordType, name: $name, description: $description, administeredBy: $administeredBy, administeredAt: $administeredAt, expiresAt: $expiresAt, nextDueAt: $nextDueAt, batchNumber: $batchNumber, dosage: $dosage, frequency: $frequency, isActive: $isActive, reminderEnabled: $reminderEnabled, documentUrl: $documentUrl, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MedicalRecordCopyWith<$Res>  {
  factory $MedicalRecordCopyWith(MedicalRecord value, $Res Function(MedicalRecord) _then) = _$MedicalRecordCopyWithImpl;
@useResult
$Res call({
 String id, String petId, MedicalRecordType recordType, String name, String? description, String? administeredBy, DateTime? administeredAt, DateTime? expiresAt, DateTime? nextDueAt, String? batchNumber, String? dosage, String? frequency, bool isActive, bool reminderEnabled, String? documentUrl, String? notes, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$MedicalRecordCopyWithImpl<$Res>
    implements $MedicalRecordCopyWith<$Res> {
  _$MedicalRecordCopyWithImpl(this._self, this._then);

  final MedicalRecord _self;
  final $Res Function(MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? petId = null,Object? recordType = null,Object? name = null,Object? description = freezed,Object? administeredBy = freezed,Object? administeredAt = freezed,Object? expiresAt = freezed,Object? nextDueAt = freezed,Object? batchNumber = freezed,Object? dosage = freezed,Object? frequency = freezed,Object? isActive = null,Object? reminderEnabled = null,Object? documentUrl = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as MedicalRecordType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,administeredBy: freezed == administeredBy ? _self.administeredBy : administeredBy // ignore: cast_nullable_to_non_nullable
as String?,administeredAt: freezed == administeredAt ? _self.administeredAt : administeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nextDueAt: freezed == nextDueAt ? _self.nextDueAt : nextDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,batchNumber: freezed == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String?,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicalRecord].
extension MedicalRecordPatterns on MedicalRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicalRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicalRecord value)  $default,){
final _that = this;
switch (_that) {
case _MedicalRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicalRecord value)?  $default,){
final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String petId,  MedicalRecordType recordType,  String name,  String? description,  String? administeredBy,  DateTime? administeredAt,  DateTime? expiresAt,  DateTime? nextDueAt,  String? batchNumber,  String? dosage,  String? frequency,  bool isActive,  bool reminderEnabled,  String? documentUrl,  String? notes,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.petId,_that.recordType,_that.name,_that.description,_that.administeredBy,_that.administeredAt,_that.expiresAt,_that.nextDueAt,_that.batchNumber,_that.dosage,_that.frequency,_that.isActive,_that.reminderEnabled,_that.documentUrl,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String petId,  MedicalRecordType recordType,  String name,  String? description,  String? administeredBy,  DateTime? administeredAt,  DateTime? expiresAt,  DateTime? nextDueAt,  String? batchNumber,  String? dosage,  String? frequency,  bool isActive,  bool reminderEnabled,  String? documentUrl,  String? notes,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord():
return $default(_that.id,_that.petId,_that.recordType,_that.name,_that.description,_that.administeredBy,_that.administeredAt,_that.expiresAt,_that.nextDueAt,_that.batchNumber,_that.dosage,_that.frequency,_that.isActive,_that.reminderEnabled,_that.documentUrl,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String petId,  MedicalRecordType recordType,  String name,  String? description,  String? administeredBy,  DateTime? administeredAt,  DateTime? expiresAt,  DateTime? nextDueAt,  String? batchNumber,  String? dosage,  String? frequency,  bool isActive,  bool reminderEnabled,  String? documentUrl,  String? notes,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MedicalRecord() when $default != null:
return $default(_that.id,_that.petId,_that.recordType,_that.name,_that.description,_that.administeredBy,_that.administeredAt,_that.expiresAt,_that.nextDueAt,_that.batchNumber,_that.dosage,_that.frequency,_that.isActive,_that.reminderEnabled,_that.documentUrl,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedicalRecord extends MedicalRecord {
  const _MedicalRecord({required this.id, required this.petId, required this.recordType, required this.name, this.description, this.administeredBy, this.administeredAt, this.expiresAt, this.nextDueAt, this.batchNumber, this.dosage, this.frequency, required this.isActive, required this.reminderEnabled, this.documentUrl, this.notes, required this.createdAt, required this.updatedAt}): super._();
  factory _MedicalRecord.fromJson(Map<String, dynamic> json) => _$MedicalRecordFromJson(json);

@override final  String id;
@override final  String petId;
@override final  MedicalRecordType recordType;
@override final  String name;
@override final  String? description;
@override final  String? administeredBy;
@override final  DateTime? administeredAt;
@override final  DateTime? expiresAt;
@override final  DateTime? nextDueAt;
@override final  String? batchNumber;
@override final  String? dosage;
@override final  String? frequency;
@override final  bool isActive;
@override final  bool reminderEnabled;
@override final  String? documentUrl;
@override final  String? notes;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicalRecordCopyWith<_MedicalRecord> get copyWith => __$MedicalRecordCopyWithImpl<_MedicalRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicalRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicalRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.administeredBy, administeredBy) || other.administeredBy == administeredBy)&&(identical(other.administeredAt, administeredAt) || other.administeredAt == administeredAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.nextDueAt, nextDueAt) || other.nextDueAt == nextDueAt)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,recordType,name,description,administeredBy,administeredAt,expiresAt,nextDueAt,batchNumber,dosage,frequency,isActive,reminderEnabled,documentUrl,notes,createdAt,updatedAt);

@override
String toString() {
  return 'MedicalRecord(id: $id, petId: $petId, recordType: $recordType, name: $name, description: $description, administeredBy: $administeredBy, administeredAt: $administeredAt, expiresAt: $expiresAt, nextDueAt: $nextDueAt, batchNumber: $batchNumber, dosage: $dosage, frequency: $frequency, isActive: $isActive, reminderEnabled: $reminderEnabled, documentUrl: $documentUrl, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MedicalRecordCopyWith<$Res> implements $MedicalRecordCopyWith<$Res> {
  factory _$MedicalRecordCopyWith(_MedicalRecord value, $Res Function(_MedicalRecord) _then) = __$MedicalRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String petId, MedicalRecordType recordType, String name, String? description, String? administeredBy, DateTime? administeredAt, DateTime? expiresAt, DateTime? nextDueAt, String? batchNumber, String? dosage, String? frequency, bool isActive, bool reminderEnabled, String? documentUrl, String? notes, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$MedicalRecordCopyWithImpl<$Res>
    implements _$MedicalRecordCopyWith<$Res> {
  __$MedicalRecordCopyWithImpl(this._self, this._then);

  final _MedicalRecord _self;
  final $Res Function(_MedicalRecord) _then;

/// Create a copy of MedicalRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? petId = null,Object? recordType = null,Object? name = null,Object? description = freezed,Object? administeredBy = freezed,Object? administeredAt = freezed,Object? expiresAt = freezed,Object? nextDueAt = freezed,Object? batchNumber = freezed,Object? dosage = freezed,Object? frequency = freezed,Object? isActive = null,Object? reminderEnabled = null,Object? documentUrl = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MedicalRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,recordType: null == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as MedicalRecordType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,administeredBy: freezed == administeredBy ? _self.administeredBy : administeredBy // ignore: cast_nullable_to_non_nullable
as String?,administeredAt: freezed == administeredAt ? _self.administeredAt : administeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nextDueAt: freezed == nextDueAt ? _self.nextDueAt : nextDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,batchNumber: freezed == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String?,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
