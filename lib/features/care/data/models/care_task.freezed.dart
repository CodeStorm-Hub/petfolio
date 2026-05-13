// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CareTask _$CareTaskFromJson(Map<String, dynamic> json) {
  return _CareTask.fromJson(json);
}

/// @nodoc
mixin _$CareTask {
  String get id => throw _privateConstructorUsedError;
  String get petId => throw _privateConstructorUsedError;
  CareTaskType get taskType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  CareFrequency get frequency => throw _privateConstructorUsedError;
  String? get scheduledTime => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  int get gamificationPoints => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CareTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CareTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CareTaskCopyWith<CareTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CareTaskCopyWith<$Res> {
  factory $CareTaskCopyWith(CareTask value, $Res Function(CareTask) then) =
      _$CareTaskCopyWithImpl<$Res, CareTask>;
  @useResult
  $Res call({
    String id,
    String petId,
    CareTaskType taskType,
    String title,
    CareFrequency frequency,
    String? scheduledTime,
    bool isCompleted,
    DateTime? completedAt,
    int gamificationPoints,
    String? notes,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$CareTaskCopyWithImpl<$Res, $Val extends CareTask>
    implements $CareTaskCopyWith<$Res> {
  _$CareTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CareTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? taskType = null,
    Object? title = null,
    Object? frequency = null,
    Object? scheduledTime = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? gamificationPoints = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            petId: null == petId
                ? _value.petId
                : petId // ignore: cast_nullable_to_non_nullable
                      as String,
            taskType: null == taskType
                ? _value.taskType
                : taskType // ignore: cast_nullable_to_non_nullable
                      as CareTaskType,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as CareFrequency,
            scheduledTime: freezed == scheduledTime
                ? _value.scheduledTime
                : scheduledTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            gamificationPoints: null == gamificationPoints
                ? _value.gamificationPoints
                : gamificationPoints // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CareTaskImplCopyWith<$Res>
    implements $CareTaskCopyWith<$Res> {
  factory _$$CareTaskImplCopyWith(
    _$CareTaskImpl value,
    $Res Function(_$CareTaskImpl) then,
  ) = __$$CareTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String petId,
    CareTaskType taskType,
    String title,
    CareFrequency frequency,
    String? scheduledTime,
    bool isCompleted,
    DateTime? completedAt,
    int gamificationPoints,
    String? notes,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$CareTaskImplCopyWithImpl<$Res>
    extends _$CareTaskCopyWithImpl<$Res, _$CareTaskImpl>
    implements _$$CareTaskImplCopyWith<$Res> {
  __$$CareTaskImplCopyWithImpl(
    _$CareTaskImpl _value,
    $Res Function(_$CareTaskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CareTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? taskType = null,
    Object? title = null,
    Object? frequency = null,
    Object? scheduledTime = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? gamificationPoints = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$CareTaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        petId: null == petId
            ? _value.petId
            : petId // ignore: cast_nullable_to_non_nullable
                  as String,
        taskType: null == taskType
            ? _value.taskType
            : taskType // ignore: cast_nullable_to_non_nullable
                  as CareTaskType,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as CareFrequency,
        scheduledTime: freezed == scheduledTime
            ? _value.scheduledTime
            : scheduledTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        gamificationPoints: null == gamificationPoints
            ? _value.gamificationPoints
            : gamificationPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$CareTaskImpl extends _CareTask {
  const _$CareTaskImpl({
    required this.id,
    required this.petId,
    required this.taskType,
    required this.title,
    required this.frequency,
    this.scheduledTime,
    required this.isCompleted,
    this.completedAt,
    required this.gamificationPoints,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$CareTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$CareTaskImplFromJson(json);

  @override
  final String id;
  @override
  final String petId;
  @override
  final CareTaskType taskType;
  @override
  final String title;
  @override
  final CareFrequency frequency;
  @override
  final String? scheduledTime;
  @override
  final bool isCompleted;
  @override
  final DateTime? completedAt;
  @override
  final int gamificationPoints;
  @override
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'CareTask(id: $id, petId: $petId, taskType: $taskType, title: $title, frequency: $frequency, scheduledTime: $scheduledTime, isCompleted: $isCompleted, completedAt: $completedAt, gamificationPoints: $gamificationPoints, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CareTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.petId, petId) || other.petId == petId) &&
            (identical(other.taskType, taskType) ||
                other.taskType == taskType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.gamificationPoints, gamificationPoints) ||
                other.gamificationPoints == gamificationPoints) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    petId,
    taskType,
    title,
    frequency,
    scheduledTime,
    isCompleted,
    completedAt,
    gamificationPoints,
    notes,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CareTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CareTaskImplCopyWith<_$CareTaskImpl> get copyWith =>
      __$$CareTaskImplCopyWithImpl<_$CareTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CareTaskImplToJson(this);
  }
}

abstract class _CareTask extends CareTask {
  const factory _CareTask({
    required final String id,
    required final String petId,
    required final CareTaskType taskType,
    required final String title,
    required final CareFrequency frequency,
    final String? scheduledTime,
    required final bool isCompleted,
    final DateTime? completedAt,
    required final int gamificationPoints,
    final String? notes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$CareTaskImpl;
  const _CareTask._() : super._();

  factory _CareTask.fromJson(Map<String, dynamic> json) =
      _$CareTaskImpl.fromJson;

  @override
  String get id;
  @override
  String get petId;
  @override
  CareTaskType get taskType;
  @override
  String get title;
  @override
  CareFrequency get frequency;
  @override
  String? get scheduledTime;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedAt;
  @override
  int get gamificationPoints;
  @override
  String? get notes;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of CareTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CareTaskImplCopyWith<_$CareTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
