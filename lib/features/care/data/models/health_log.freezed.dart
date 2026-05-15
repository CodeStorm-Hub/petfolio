// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HealthLog _$HealthLogFromJson(Map<String, dynamic> json) {
  return _HealthLog.fromJson(json);
}

/// @nodoc
mixin _$HealthLog {
  String get id => throw _privateConstructorUsedError;
  String get petId => throw _privateConstructorUsedError;
  String get recordedBy => throw _privateConstructorUsedError;
  HealthLogType get logType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  HealthSeverity? get severity => throw _privateConstructorUsedError;
  String? get vetName => throw _privateConstructorUsedError;
  String? get vetClinic => throw _privateConstructorUsedError;
  String? get diagnosis => throw _privateConstructorUsedError;
  String? get treatment => throw _privateConstructorUsedError;
  DateTime? get followUpDate => throw _privateConstructorUsedError;
  DateTime get occurredAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this HealthLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthLogCopyWith<HealthLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthLogCopyWith<$Res> {
  factory $HealthLogCopyWith(HealthLog value, $Res Function(HealthLog) then) =
      _$HealthLogCopyWithImpl<$Res, HealthLog>;
  @useResult
  $Res call({
    String id,
    String petId,
    String recordedBy,
    HealthLogType logType,
    String title,
    String? description,
    double? weightKg,
    HealthSeverity? severity,
    String? vetName,
    String? vetClinic,
    String? diagnosis,
    String? treatment,
    DateTime? followUpDate,
    DateTime occurredAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$HealthLogCopyWithImpl<$Res, $Val extends HealthLog>
    implements $HealthLogCopyWith<$Res> {
  _$HealthLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? recordedBy = null,
    Object? logType = null,
    Object? title = null,
    Object? description = freezed,
    Object? weightKg = freezed,
    Object? severity = freezed,
    Object? vetName = freezed,
    Object? vetClinic = freezed,
    Object? diagnosis = freezed,
    Object? treatment = freezed,
    Object? followUpDate = freezed,
    Object? occurredAt = null,
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
            recordedBy: null == recordedBy
                ? _value.recordedBy
                : recordedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            logType: null == logType
                ? _value.logType
                : logType // ignore: cast_nullable_to_non_nullable
                      as HealthLogType,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            severity: freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as HealthSeverity?,
            vetName: freezed == vetName
                ? _value.vetName
                : vetName // ignore: cast_nullable_to_non_nullable
                      as String?,
            vetClinic: freezed == vetClinic
                ? _value.vetClinic
                : vetClinic // ignore: cast_nullable_to_non_nullable
                      as String?,
            diagnosis: freezed == diagnosis
                ? _value.diagnosis
                : diagnosis // ignore: cast_nullable_to_non_nullable
                      as String?,
            treatment: freezed == treatment
                ? _value.treatment
                : treatment // ignore: cast_nullable_to_non_nullable
                      as String?,
            followUpDate: freezed == followUpDate
                ? _value.followUpDate
                : followUpDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            occurredAt: null == occurredAt
                ? _value.occurredAt
                : occurredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$HealthLogImplCopyWith<$Res>
    implements $HealthLogCopyWith<$Res> {
  factory _$$HealthLogImplCopyWith(
    _$HealthLogImpl value,
    $Res Function(_$HealthLogImpl) then,
  ) = __$$HealthLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String petId,
    String recordedBy,
    HealthLogType logType,
    String title,
    String? description,
    double? weightKg,
    HealthSeverity? severity,
    String? vetName,
    String? vetClinic,
    String? diagnosis,
    String? treatment,
    DateTime? followUpDate,
    DateTime occurredAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$HealthLogImplCopyWithImpl<$Res>
    extends _$HealthLogCopyWithImpl<$Res, _$HealthLogImpl>
    implements _$$HealthLogImplCopyWith<$Res> {
  __$$HealthLogImplCopyWithImpl(
    _$HealthLogImpl _value,
    $Res Function(_$HealthLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HealthLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? recordedBy = null,
    Object? logType = null,
    Object? title = null,
    Object? description = freezed,
    Object? weightKg = freezed,
    Object? severity = freezed,
    Object? vetName = freezed,
    Object? vetClinic = freezed,
    Object? diagnosis = freezed,
    Object? treatment = freezed,
    Object? followUpDate = freezed,
    Object? occurredAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$HealthLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        petId: null == petId
            ? _value.petId
            : petId // ignore: cast_nullable_to_non_nullable
                  as String,
        recordedBy: null == recordedBy
            ? _value.recordedBy
            : recordedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        logType: null == logType
            ? _value.logType
            : logType // ignore: cast_nullable_to_non_nullable
                  as HealthLogType,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        severity: freezed == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as HealthSeverity?,
        vetName: freezed == vetName
            ? _value.vetName
            : vetName // ignore: cast_nullable_to_non_nullable
                  as String?,
        vetClinic: freezed == vetClinic
            ? _value.vetClinic
            : vetClinic // ignore: cast_nullable_to_non_nullable
                  as String?,
        diagnosis: freezed == diagnosis
            ? _value.diagnosis
            : diagnosis // ignore: cast_nullable_to_non_nullable
                  as String?,
        treatment: freezed == treatment
            ? _value.treatment
            : treatment // ignore: cast_nullable_to_non_nullable
                  as String?,
        followUpDate: freezed == followUpDate
            ? _value.followUpDate
            : followUpDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        occurredAt: null == occurredAt
            ? _value.occurredAt
            : occurredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
@JsonSerializable()
class _$HealthLogImpl extends _HealthLog {
  const _$HealthLogImpl({
    required this.id,
    required this.petId,
    required this.recordedBy,
    required this.logType,
    required this.title,
    this.description,
    this.weightKg,
    this.severity,
    this.vetName,
    this.vetClinic,
    this.diagnosis,
    this.treatment,
    this.followUpDate,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$HealthLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthLogImplFromJson(json);

  @override
  final String id;
  @override
  final String petId;
  @override
  final String recordedBy;
  @override
  final HealthLogType logType;
  @override
  final String title;
  @override
  final String? description;
  @override
  final double? weightKg;
  @override
  final HealthSeverity? severity;
  @override
  final String? vetName;
  @override
  final String? vetClinic;
  @override
  final String? diagnosis;
  @override
  final String? treatment;
  @override
  final DateTime? followUpDate;
  @override
  final DateTime occurredAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'HealthLog(id: $id, petId: $petId, recordedBy: $recordedBy, logType: $logType, title: $title, description: $description, weightKg: $weightKg, severity: $severity, vetName: $vetName, vetClinic: $vetClinic, diagnosis: $diagnosis, treatment: $treatment, followUpDate: $followUpDate, occurredAt: $occurredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.petId, petId) || other.petId == petId) &&
            (identical(other.recordedBy, recordedBy) ||
                other.recordedBy == recordedBy) &&
            (identical(other.logType, logType) || other.logType == logType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.vetName, vetName) || other.vetName == vetName) &&
            (identical(other.vetClinic, vetClinic) ||
                other.vetClinic == vetClinic) &&
            (identical(other.diagnosis, diagnosis) ||
                other.diagnosis == diagnosis) &&
            (identical(other.treatment, treatment) ||
                other.treatment == treatment) &&
            (identical(other.followUpDate, followUpDate) ||
                other.followUpDate == followUpDate) &&
            (identical(other.occurredAt, occurredAt) ||
                other.occurredAt == occurredAt) &&
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
    recordedBy,
    logType,
    title,
    description,
    weightKg,
    severity,
    vetName,
    vetClinic,
    diagnosis,
    treatment,
    followUpDate,
    occurredAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of HealthLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthLogImplCopyWith<_$HealthLogImpl> get copyWith =>
      __$$HealthLogImplCopyWithImpl<_$HealthLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthLogImplToJson(this);
  }
}

abstract class _HealthLog extends HealthLog {
  const factory _HealthLog({
    required final String id,
    required final String petId,
    required final String recordedBy,
    required final HealthLogType logType,
    required final String title,
    final String? description,
    final double? weightKg,
    final HealthSeverity? severity,
    final String? vetName,
    final String? vetClinic,
    final String? diagnosis,
    final String? treatment,
    final DateTime? followUpDate,
    required final DateTime occurredAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$HealthLogImpl;
  const _HealthLog._() : super._();

  factory _HealthLog.fromJson(Map<String, dynamic> json) =
      _$HealthLogImpl.fromJson;

  @override
  String get id;
  @override
  String get petId;
  @override
  String get recordedBy;
  @override
  HealthLogType get logType;
  @override
  String get title;
  @override
  String? get description;
  @override
  double? get weightKg;
  @override
  HealthSeverity? get severity;
  @override
  String? get vetName;
  @override
  String? get vetClinic;
  @override
  String? get diagnosis;
  @override
  String? get treatment;
  @override
  DateTime? get followUpDate;
  @override
  DateTime get occurredAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of HealthLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthLogImplCopyWith<_$HealthLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
