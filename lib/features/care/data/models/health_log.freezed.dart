// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthLog {

 String get id; String get petId; String get recordedBy; HealthLogType get logType; String get title; String? get description; double? get weightKg; HealthSeverity? get severity; String? get vetName; String? get vetClinic; String? get diagnosis; String? get treatment; DateTime? get followUpDate; DateTime get occurredAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of HealthLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthLogCopyWith<HealthLog> get copyWith => _$HealthLogCopyWithImpl<HealthLog>(this as HealthLog, _$identity);

  /// Serializes this HealthLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthLog&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.logType, logType) || other.logType == logType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.vetName, vetName) || other.vetName == vetName)&&(identical(other.vetClinic, vetClinic) || other.vetClinic == vetClinic)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.treatment, treatment) || other.treatment == treatment)&&(identical(other.followUpDate, followUpDate) || other.followUpDate == followUpDate)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,recordedBy,logType,title,description,weightKg,severity,vetName,vetClinic,diagnosis,treatment,followUpDate,occurredAt,createdAt,updatedAt);

@override
String toString() {
  return 'HealthLog(id: $id, petId: $petId, recordedBy: $recordedBy, logType: $logType, title: $title, description: $description, weightKg: $weightKg, severity: $severity, vetName: $vetName, vetClinic: $vetClinic, diagnosis: $diagnosis, treatment: $treatment, followUpDate: $followUpDate, occurredAt: $occurredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HealthLogCopyWith<$Res>  {
  factory $HealthLogCopyWith(HealthLog value, $Res Function(HealthLog) _then) = _$HealthLogCopyWithImpl;
@useResult
$Res call({
 String id, String petId, String recordedBy, HealthLogType logType, String title, String? description, double? weightKg, HealthSeverity? severity, String? vetName, String? vetClinic, String? diagnosis, String? treatment, DateTime? followUpDate, DateTime occurredAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$HealthLogCopyWithImpl<$Res>
    implements $HealthLogCopyWith<$Res> {
  _$HealthLogCopyWithImpl(this._self, this._then);

  final HealthLog _self;
  final $Res Function(HealthLog) _then;

/// Create a copy of HealthLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? petId = null,Object? recordedBy = null,Object? logType = null,Object? title = null,Object? description = freezed,Object? weightKg = freezed,Object? severity = freezed,Object? vetName = freezed,Object? vetClinic = freezed,Object? diagnosis = freezed,Object? treatment = freezed,Object? followUpDate = freezed,Object? occurredAt = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,logType: null == logType ? _self.logType : logType // ignore: cast_nullable_to_non_nullable
as HealthLogType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as HealthSeverity?,vetName: freezed == vetName ? _self.vetName : vetName // ignore: cast_nullable_to_non_nullable
as String?,vetClinic: freezed == vetClinic ? _self.vetClinic : vetClinic // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,treatment: freezed == treatment ? _self.treatment : treatment // ignore: cast_nullable_to_non_nullable
as String?,followUpDate: freezed == followUpDate ? _self.followUpDate : followUpDate // ignore: cast_nullable_to_non_nullable
as DateTime?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthLog].
extension HealthLogPatterns on HealthLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthLog value)  $default,){
final _that = this;
switch (_that) {
case _HealthLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthLog value)?  $default,){
final _that = this;
switch (_that) {
case _HealthLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String petId,  String recordedBy,  HealthLogType logType,  String title,  String? description,  double? weightKg,  HealthSeverity? severity,  String? vetName,  String? vetClinic,  String? diagnosis,  String? treatment,  DateTime? followUpDate,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthLog() when $default != null:
return $default(_that.id,_that.petId,_that.recordedBy,_that.logType,_that.title,_that.description,_that.weightKg,_that.severity,_that.vetName,_that.vetClinic,_that.diagnosis,_that.treatment,_that.followUpDate,_that.occurredAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String petId,  String recordedBy,  HealthLogType logType,  String title,  String? description,  double? weightKg,  HealthSeverity? severity,  String? vetName,  String? vetClinic,  String? diagnosis,  String? treatment,  DateTime? followUpDate,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HealthLog():
return $default(_that.id,_that.petId,_that.recordedBy,_that.logType,_that.title,_that.description,_that.weightKg,_that.severity,_that.vetName,_that.vetClinic,_that.diagnosis,_that.treatment,_that.followUpDate,_that.occurredAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String petId,  String recordedBy,  HealthLogType logType,  String title,  String? description,  double? weightKg,  HealthSeverity? severity,  String? vetName,  String? vetClinic,  String? diagnosis,  String? treatment,  DateTime? followUpDate,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HealthLog() when $default != null:
return $default(_that.id,_that.petId,_that.recordedBy,_that.logType,_that.title,_that.description,_that.weightKg,_that.severity,_that.vetName,_that.vetClinic,_that.diagnosis,_that.treatment,_that.followUpDate,_that.occurredAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthLog extends HealthLog {
  const _HealthLog({required this.id, required this.petId, required this.recordedBy, required this.logType, required this.title, this.description, this.weightKg, this.severity, this.vetName, this.vetClinic, this.diagnosis, this.treatment, this.followUpDate, required this.occurredAt, required this.createdAt, required this.updatedAt}): super._();
  factory _HealthLog.fromJson(Map<String, dynamic> json) => _$HealthLogFromJson(json);

@override final  String id;
@override final  String petId;
@override final  String recordedBy;
@override final  HealthLogType logType;
@override final  String title;
@override final  String? description;
@override final  double? weightKg;
@override final  HealthSeverity? severity;
@override final  String? vetName;
@override final  String? vetClinic;
@override final  String? diagnosis;
@override final  String? treatment;
@override final  DateTime? followUpDate;
@override final  DateTime occurredAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of HealthLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthLogCopyWith<_HealthLog> get copyWith => __$HealthLogCopyWithImpl<_HealthLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthLog&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.logType, logType) || other.logType == logType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.vetName, vetName) || other.vetName == vetName)&&(identical(other.vetClinic, vetClinic) || other.vetClinic == vetClinic)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.treatment, treatment) || other.treatment == treatment)&&(identical(other.followUpDate, followUpDate) || other.followUpDate == followUpDate)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,recordedBy,logType,title,description,weightKg,severity,vetName,vetClinic,diagnosis,treatment,followUpDate,occurredAt,createdAt,updatedAt);

@override
String toString() {
  return 'HealthLog(id: $id, petId: $petId, recordedBy: $recordedBy, logType: $logType, title: $title, description: $description, weightKg: $weightKg, severity: $severity, vetName: $vetName, vetClinic: $vetClinic, diagnosis: $diagnosis, treatment: $treatment, followUpDate: $followUpDate, occurredAt: $occurredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HealthLogCopyWith<$Res> implements $HealthLogCopyWith<$Res> {
  factory _$HealthLogCopyWith(_HealthLog value, $Res Function(_HealthLog) _then) = __$HealthLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String petId, String recordedBy, HealthLogType logType, String title, String? description, double? weightKg, HealthSeverity? severity, String? vetName, String? vetClinic, String? diagnosis, String? treatment, DateTime? followUpDate, DateTime occurredAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$HealthLogCopyWithImpl<$Res>
    implements _$HealthLogCopyWith<$Res> {
  __$HealthLogCopyWithImpl(this._self, this._then);

  final _HealthLog _self;
  final $Res Function(_HealthLog) _then;

/// Create a copy of HealthLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? petId = null,Object? recordedBy = null,Object? logType = null,Object? title = null,Object? description = freezed,Object? weightKg = freezed,Object? severity = freezed,Object? vetName = freezed,Object? vetClinic = freezed,Object? diagnosis = freezed,Object? treatment = freezed,Object? followUpDate = freezed,Object? occurredAt = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_HealthLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,logType: null == logType ? _self.logType : logType // ignore: cast_nullable_to_non_nullable
as HealthLogType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as HealthSeverity?,vetName: freezed == vetName ? _self.vetName : vetName // ignore: cast_nullable_to_non_nullable
as String?,vetClinic: freezed == vetClinic ? _self.vetClinic : vetClinic // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,treatment: freezed == treatment ? _self.treatment : treatment // ignore: cast_nullable_to_non_nullable
as String?,followUpDate: freezed == followUpDate ? _self.followUpDate : followUpDate // ignore: cast_nullable_to_non_nullable
as DateTime?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
