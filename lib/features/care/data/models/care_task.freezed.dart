// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CareTask {

 String get id; String get petId; CareTaskType get taskType; String get title; CareFrequency get frequency; String? get scheduledTime; bool get isCompleted; DateTime? get completedAt; int get gamificationPoints; String? get notes; String? get categoryIcon; DateTime get createdAt; DateTime get updatedAt;// Reference date for recurring tasks (weekly / biweekly / monthly).
// Defaults to createdAt on the server; never null after the first sync.
 DateTime? get anchorDate;
/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareTaskCopyWith<CareTask> get copyWith => _$CareTaskCopyWithImpl<CareTask>(this as CareTask, _$identity);

  /// Serializes this CareTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareTask&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.taskType, taskType) || other.taskType == taskType)&&(identical(other.title, title) || other.title == title)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.gamificationPoints, gamificationPoints) || other.gamificationPoints == gamificationPoints)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,taskType,title,frequency,scheduledTime,isCompleted,completedAt,gamificationPoints,notes,categoryIcon,createdAt,updatedAt,anchorDate);

@override
String toString() {
  return 'CareTask(id: $id, petId: $petId, taskType: $taskType, title: $title, frequency: $frequency, scheduledTime: $scheduledTime, isCompleted: $isCompleted, completedAt: $completedAt, gamificationPoints: $gamificationPoints, notes: $notes, categoryIcon: $categoryIcon, createdAt: $createdAt, updatedAt: $updatedAt, anchorDate: $anchorDate)';
}


}

/// @nodoc
abstract mixin class $CareTaskCopyWith<$Res>  {
  factory $CareTaskCopyWith(CareTask value, $Res Function(CareTask) _then) = _$CareTaskCopyWithImpl;
@useResult
$Res call({
 String id, String petId, CareTaskType taskType, String title, CareFrequency frequency, String? scheduledTime, bool isCompleted, DateTime? completedAt, int gamificationPoints, String? notes, String? categoryIcon, DateTime createdAt, DateTime updatedAt, DateTime? anchorDate
});




}
/// @nodoc
class _$CareTaskCopyWithImpl<$Res>
    implements $CareTaskCopyWith<$Res> {
  _$CareTaskCopyWithImpl(this._self, this._then);

  final CareTask _self;
  final $Res Function(CareTask) _then;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? petId = null,Object? taskType = null,Object? title = null,Object? frequency = null,Object? scheduledTime = freezed,Object? isCompleted = null,Object? completedAt = freezed,Object? gamificationPoints = null,Object? notes = freezed,Object? categoryIcon = freezed,Object? createdAt = null,Object? updatedAt = null,Object? anchorDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,taskType: null == taskType ? _self.taskType : taskType // ignore: cast_nullable_to_non_nullable
as CareTaskType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as CareFrequency,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gamificationPoints: null == gamificationPoints ? _self.gamificationPoints : gamificationPoints // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,anchorDate: freezed == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CareTask].
extension CareTaskPatterns on CareTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareTask value)  $default,){
final _that = this;
switch (_that) {
case _CareTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareTask value)?  $default,){
final _that = this;
switch (_that) {
case _CareTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String petId,  CareTaskType taskType,  String title,  CareFrequency frequency,  String? scheduledTime,  bool isCompleted,  DateTime? completedAt,  int gamificationPoints,  String? notes,  String? categoryIcon,  DateTime createdAt,  DateTime updatedAt,  DateTime? anchorDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareTask() when $default != null:
return $default(_that.id,_that.petId,_that.taskType,_that.title,_that.frequency,_that.scheduledTime,_that.isCompleted,_that.completedAt,_that.gamificationPoints,_that.notes,_that.categoryIcon,_that.createdAt,_that.updatedAt,_that.anchorDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String petId,  CareTaskType taskType,  String title,  CareFrequency frequency,  String? scheduledTime,  bool isCompleted,  DateTime? completedAt,  int gamificationPoints,  String? notes,  String? categoryIcon,  DateTime createdAt,  DateTime updatedAt,  DateTime? anchorDate)  $default,) {final _that = this;
switch (_that) {
case _CareTask():
return $default(_that.id,_that.petId,_that.taskType,_that.title,_that.frequency,_that.scheduledTime,_that.isCompleted,_that.completedAt,_that.gamificationPoints,_that.notes,_that.categoryIcon,_that.createdAt,_that.updatedAt,_that.anchorDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String petId,  CareTaskType taskType,  String title,  CareFrequency frequency,  String? scheduledTime,  bool isCompleted,  DateTime? completedAt,  int gamificationPoints,  String? notes,  String? categoryIcon,  DateTime createdAt,  DateTime updatedAt,  DateTime? anchorDate)?  $default,) {final _that = this;
switch (_that) {
case _CareTask() when $default != null:
return $default(_that.id,_that.petId,_that.taskType,_that.title,_that.frequency,_that.scheduledTime,_that.isCompleted,_that.completedAt,_that.gamificationPoints,_that.notes,_that.categoryIcon,_that.createdAt,_that.updatedAt,_that.anchorDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CareTask extends CareTask {
  const _CareTask({required this.id, required this.petId, required this.taskType, required this.title, required this.frequency, this.scheduledTime, required this.isCompleted, this.completedAt, required this.gamificationPoints, this.notes, this.categoryIcon, required this.createdAt, required this.updatedAt, this.anchorDate}): super._();
  factory _CareTask.fromJson(Map<String, dynamic> json) => _$CareTaskFromJson(json);

@override final  String id;
@override final  String petId;
@override final  CareTaskType taskType;
@override final  String title;
@override final  CareFrequency frequency;
@override final  String? scheduledTime;
@override final  bool isCompleted;
@override final  DateTime? completedAt;
@override final  int gamificationPoints;
@override final  String? notes;
@override final  String? categoryIcon;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
// Reference date for recurring tasks (weekly / biweekly / monthly).
// Defaults to createdAt on the server; never null after the first sync.
@override final  DateTime? anchorDate;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareTaskCopyWith<_CareTask> get copyWith => __$CareTaskCopyWithImpl<_CareTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CareTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareTask&&(identical(other.id, id) || other.id == id)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.taskType, taskType) || other.taskType == taskType)&&(identical(other.title, title) || other.title == title)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.gamificationPoints, gamificationPoints) || other.gamificationPoints == gamificationPoints)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,petId,taskType,title,frequency,scheduledTime,isCompleted,completedAt,gamificationPoints,notes,categoryIcon,createdAt,updatedAt,anchorDate);

@override
String toString() {
  return 'CareTask(id: $id, petId: $petId, taskType: $taskType, title: $title, frequency: $frequency, scheduledTime: $scheduledTime, isCompleted: $isCompleted, completedAt: $completedAt, gamificationPoints: $gamificationPoints, notes: $notes, categoryIcon: $categoryIcon, createdAt: $createdAt, updatedAt: $updatedAt, anchorDate: $anchorDate)';
}


}

/// @nodoc
abstract mixin class _$CareTaskCopyWith<$Res> implements $CareTaskCopyWith<$Res> {
  factory _$CareTaskCopyWith(_CareTask value, $Res Function(_CareTask) _then) = __$CareTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String petId, CareTaskType taskType, String title, CareFrequency frequency, String? scheduledTime, bool isCompleted, DateTime? completedAt, int gamificationPoints, String? notes, String? categoryIcon, DateTime createdAt, DateTime updatedAt, DateTime? anchorDate
});




}
/// @nodoc
class __$CareTaskCopyWithImpl<$Res>
    implements _$CareTaskCopyWith<$Res> {
  __$CareTaskCopyWithImpl(this._self, this._then);

  final _CareTask _self;
  final $Res Function(_CareTask) _then;

/// Create a copy of CareTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? petId = null,Object? taskType = null,Object? title = null,Object? frequency = null,Object? scheduledTime = freezed,Object? isCompleted = null,Object? completedAt = freezed,Object? gamificationPoints = null,Object? notes = freezed,Object? categoryIcon = freezed,Object? createdAt = null,Object? updatedAt = null,Object? anchorDate = freezed,}) {
  return _then(_CareTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,taskType: null == taskType ? _self.taskType : taskType // ignore: cast_nullable_to_non_nullable
as CareTaskType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as CareFrequency,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gamificationPoints: null == gamificationPoints ? _self.gamificationPoints : gamificationPoints // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,anchorDate: freezed == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
