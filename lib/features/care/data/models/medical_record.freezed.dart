// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) {
  return _MedicalRecord.fromJson(json);
}

/// @nodoc
mixin _$MedicalRecord {
  String get id => throw _privateConstructorUsedError;
  String get petId => throw _privateConstructorUsedError;
  MedicalRecordType get recordType => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get administeredBy => throw _privateConstructorUsedError;
  DateTime? get administeredAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime? get nextDueAt => throw _privateConstructorUsedError;
  String? get batchNumber => throw _privateConstructorUsedError;
  String? get dosage => throw _privateConstructorUsedError;
  String? get frequency => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get reminderEnabled => throw _privateConstructorUsedError;
  String? get documentUrl => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MedicalRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicalRecordCopyWith<MedicalRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicalRecordCopyWith<$Res> {
  factory $MedicalRecordCopyWith(
    MedicalRecord value,
    $Res Function(MedicalRecord) then,
  ) = _$MedicalRecordCopyWithImpl<$Res, MedicalRecord>;
  @useResult
  $Res call({
    String id,
    String petId,
    MedicalRecordType recordType,
    String name,
    String? description,
    String? administeredBy,
    DateTime? administeredAt,
    DateTime? expiresAt,
    DateTime? nextDueAt,
    String? batchNumber,
    String? dosage,
    String? frequency,
    bool isActive,
    bool reminderEnabled,
    String? documentUrl,
    String? notes,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$MedicalRecordCopyWithImpl<$Res, $Val extends MedicalRecord>
    implements $MedicalRecordCopyWith<$Res> {
  _$MedicalRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? recordType = null,
    Object? name = null,
    Object? description = freezed,
    Object? administeredBy = freezed,
    Object? administeredAt = freezed,
    Object? expiresAt = freezed,
    Object? nextDueAt = freezed,
    Object? batchNumber = freezed,
    Object? dosage = freezed,
    Object? frequency = freezed,
    Object? isActive = null,
    Object? reminderEnabled = null,
    Object? documentUrl = freezed,
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
            recordType: null == recordType
                ? _value.recordType
                : recordType // ignore: cast_nullable_to_non_nullable
                      as MedicalRecordType,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            administeredBy: freezed == administeredBy
                ? _value.administeredBy
                : administeredBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            administeredAt: freezed == administeredAt
                ? _value.administeredAt
                : administeredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            nextDueAt: freezed == nextDueAt
                ? _value.nextDueAt
                : nextDueAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            batchNumber: freezed == batchNumber
                ? _value.batchNumber
                : batchNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            dosage: freezed == dosage
                ? _value.dosage
                : dosage // ignore: cast_nullable_to_non_nullable
                      as String?,
            frequency: freezed == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            reminderEnabled: null == reminderEnabled
                ? _value.reminderEnabled
                : reminderEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            documentUrl: freezed == documentUrl
                ? _value.documentUrl
                : documentUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$MedicalRecordImplCopyWith<$Res>
    implements $MedicalRecordCopyWith<$Res> {
  factory _$$MedicalRecordImplCopyWith(
    _$MedicalRecordImpl value,
    $Res Function(_$MedicalRecordImpl) then,
  ) = __$$MedicalRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String petId,
    MedicalRecordType recordType,
    String name,
    String? description,
    String? administeredBy,
    DateTime? administeredAt,
    DateTime? expiresAt,
    DateTime? nextDueAt,
    String? batchNumber,
    String? dosage,
    String? frequency,
    bool isActive,
    bool reminderEnabled,
    String? documentUrl,
    String? notes,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$MedicalRecordImplCopyWithImpl<$Res>
    extends _$MedicalRecordCopyWithImpl<$Res, _$MedicalRecordImpl>
    implements _$$MedicalRecordImplCopyWith<$Res> {
  __$$MedicalRecordImplCopyWithImpl(
    _$MedicalRecordImpl _value,
    $Res Function(_$MedicalRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? recordType = null,
    Object? name = null,
    Object? description = freezed,
    Object? administeredBy = freezed,
    Object? administeredAt = freezed,
    Object? expiresAt = freezed,
    Object? nextDueAt = freezed,
    Object? batchNumber = freezed,
    Object? dosage = freezed,
    Object? frequency = freezed,
    Object? isActive = null,
    Object? reminderEnabled = null,
    Object? documentUrl = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$MedicalRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        petId: null == petId
            ? _value.petId
            : petId // ignore: cast_nullable_to_non_nullable
                  as String,
        recordType: null == recordType
            ? _value.recordType
            : recordType // ignore: cast_nullable_to_non_nullable
                  as MedicalRecordType,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        administeredBy: freezed == administeredBy
            ? _value.administeredBy
            : administeredBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        administeredAt: freezed == administeredAt
            ? _value.administeredAt
            : administeredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        nextDueAt: freezed == nextDueAt
            ? _value.nextDueAt
            : nextDueAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        batchNumber: freezed == batchNumber
            ? _value.batchNumber
            : batchNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        dosage: freezed == dosage
            ? _value.dosage
            : dosage // ignore: cast_nullable_to_non_nullable
                  as String?,
        frequency: freezed == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        reminderEnabled: null == reminderEnabled
            ? _value.reminderEnabled
            : reminderEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        documentUrl: freezed == documentUrl
            ? _value.documentUrl
            : documentUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$MedicalRecordImpl extends _MedicalRecord {
  const _$MedicalRecordImpl({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.name,
    this.description,
    this.administeredBy,
    this.administeredAt,
    this.expiresAt,
    this.nextDueAt,
    this.batchNumber,
    this.dosage,
    this.frequency,
    required this.isActive,
    required this.reminderEnabled,
    this.documentUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$MedicalRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicalRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String petId;
  @override
  final MedicalRecordType recordType;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? administeredBy;
  @override
  final DateTime? administeredAt;
  @override
  final DateTime? expiresAt;
  @override
  final DateTime? nextDueAt;
  @override
  final String? batchNumber;
  @override
  final String? dosage;
  @override
  final String? frequency;
  @override
  final bool isActive;
  @override
  final bool reminderEnabled;
  @override
  final String? documentUrl;
  @override
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MedicalRecord(id: $id, petId: $petId, recordType: $recordType, name: $name, description: $description, administeredBy: $administeredBy, administeredAt: $administeredAt, expiresAt: $expiresAt, nextDueAt: $nextDueAt, batchNumber: $batchNumber, dosage: $dosage, frequency: $frequency, isActive: $isActive, reminderEnabled: $reminderEnabled, documentUrl: $documentUrl, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicalRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.petId, petId) || other.petId == petId) &&
            (identical(other.recordType, recordType) ||
                other.recordType == recordType) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.administeredBy, administeredBy) ||
                other.administeredBy == administeredBy) &&
            (identical(other.administeredAt, administeredAt) ||
                other.administeredAt == administeredAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.nextDueAt, nextDueAt) ||
                other.nextDueAt == nextDueAt) &&
            (identical(other.batchNumber, batchNumber) ||
                other.batchNumber == batchNumber) &&
            (identical(other.dosage, dosage) || other.dosage == dosage) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.reminderEnabled, reminderEnabled) ||
                other.reminderEnabled == reminderEnabled) &&
            (identical(other.documentUrl, documentUrl) ||
                other.documentUrl == documentUrl) &&
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
    recordType,
    name,
    description,
    administeredBy,
    administeredAt,
    expiresAt,
    nextDueAt,
    batchNumber,
    dosage,
    frequency,
    isActive,
    reminderEnabled,
    documentUrl,
    notes,
    createdAt,
    updatedAt,
  );

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicalRecordImplCopyWith<_$MedicalRecordImpl> get copyWith =>
      __$$MedicalRecordImplCopyWithImpl<_$MedicalRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicalRecordImplToJson(this);
  }
}

abstract class _MedicalRecord extends MedicalRecord {
  const factory _MedicalRecord({
    required final String id,
    required final String petId,
    required final MedicalRecordType recordType,
    required final String name,
    final String? description,
    final String? administeredBy,
    final DateTime? administeredAt,
    final DateTime? expiresAt,
    final DateTime? nextDueAt,
    final String? batchNumber,
    final String? dosage,
    final String? frequency,
    required final bool isActive,
    required final bool reminderEnabled,
    final String? documentUrl,
    final String? notes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$MedicalRecordImpl;
  const _MedicalRecord._() : super._();

  factory _MedicalRecord.fromJson(Map<String, dynamic> json) =
      _$MedicalRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get petId;
  @override
  MedicalRecordType get recordType;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get administeredBy;
  @override
  DateTime? get administeredAt;
  @override
  DateTime? get expiresAt;
  @override
  DateTime? get nextDueAt;
  @override
  String? get batchNumber;
  @override
  String? get dosage;
  @override
  String? get frequency;
  @override
  bool get isActive;
  @override
  bool get reminderEnabled;
  @override
  String? get documentUrl;
  @override
  String? get notes;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicalRecordImplCopyWith<_$MedicalRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
