// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLog {

 String get id;@JsonKey(name: 'admin_id') String get adminId; String get action;@JsonKey(name: 'entity_type') String get entityType;@JsonKey(name: 'entity_id') String? get entityId; Map<String, dynamic>? get details;@JsonKey(name: 'created_at') DateTime get createdAt;// Optional joined admin display name
@JsonKey(name: 'admin_name') String? get adminName;
/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditLogCopyWith<AuditLog> get copyWith => _$AuditLogCopyWithImpl<AuditLog>(this as AuditLog, _$identity);

  /// Serializes this AuditLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.adminId, adminId) || other.adminId == adminId)&&(identical(other.action, action) || other.action == action)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&const DeepCollectionEquality().equals(other.details, details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.adminName, adminName) || other.adminName == adminName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adminId,action,entityType,entityId,const DeepCollectionEquality().hash(details),createdAt,adminName);

@override
String toString() {
  return 'AuditLog(id: $id, adminId: $adminId, action: $action, entityType: $entityType, entityId: $entityId, details: $details, createdAt: $createdAt, adminName: $adminName)';
}


}

/// @nodoc
abstract mixin class $AuditLogCopyWith<$Res>  {
  factory $AuditLogCopyWith(AuditLog value, $Res Function(AuditLog) _then) = _$AuditLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'admin_id') String adminId, String action,@JsonKey(name: 'entity_type') String entityType,@JsonKey(name: 'entity_id') String? entityId, Map<String, dynamic>? details,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'admin_name') String? adminName
});




}
/// @nodoc
class _$AuditLogCopyWithImpl<$Res>
    implements $AuditLogCopyWith<$Res> {
  _$AuditLogCopyWithImpl(this._self, this._then);

  final AuditLog _self;
  final $Res Function(AuditLog) _then;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? adminId = null,Object? action = null,Object? entityType = null,Object? entityId = freezed,Object? details = freezed,Object? createdAt = null,Object? adminName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,adminName: freezed == adminName ? _self.adminName : adminName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditLog].
extension AuditLogPatterns on AuditLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditLog value)  $default,){
final _that = this;
switch (_that) {
case _AuditLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditLog value)?  $default,){
final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'admin_id')  String adminId,  String action, @JsonKey(name: 'entity_type')  String entityType, @JsonKey(name: 'entity_id')  String? entityId,  Map<String, dynamic>? details, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'admin_name')  String? adminName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
return $default(_that.id,_that.adminId,_that.action,_that.entityType,_that.entityId,_that.details,_that.createdAt,_that.adminName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'admin_id')  String adminId,  String action, @JsonKey(name: 'entity_type')  String entityType, @JsonKey(name: 'entity_id')  String? entityId,  Map<String, dynamic>? details, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'admin_name')  String? adminName)  $default,) {final _that = this;
switch (_that) {
case _AuditLog():
return $default(_that.id,_that.adminId,_that.action,_that.entityType,_that.entityId,_that.details,_that.createdAt,_that.adminName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'admin_id')  String adminId,  String action, @JsonKey(name: 'entity_type')  String entityType, @JsonKey(name: 'entity_id')  String? entityId,  Map<String, dynamic>? details, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'admin_name')  String? adminName)?  $default,) {final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
return $default(_that.id,_that.adminId,_that.action,_that.entityType,_that.entityId,_that.details,_that.createdAt,_that.adminName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditLog implements AuditLog {
  const _AuditLog({required this.id, @JsonKey(name: 'admin_id') required this.adminId, required this.action, @JsonKey(name: 'entity_type') required this.entityType, @JsonKey(name: 'entity_id') this.entityId, final  Map<String, dynamic>? details, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'admin_name') this.adminName}): _details = details;
  factory _AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'admin_id') final  String adminId;
@override final  String action;
@override@JsonKey(name: 'entity_type') final  String entityType;
@override@JsonKey(name: 'entity_id') final  String? entityId;
 final  Map<String, dynamic>? _details;
@override Map<String, dynamic>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
// Optional joined admin display name
@override@JsonKey(name: 'admin_name') final  String? adminName;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditLogCopyWith<_AuditLog> get copyWith => __$AuditLogCopyWithImpl<_AuditLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.adminId, adminId) || other.adminId == adminId)&&(identical(other.action, action) || other.action == action)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&const DeepCollectionEquality().equals(other._details, _details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.adminName, adminName) || other.adminName == adminName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adminId,action,entityType,entityId,const DeepCollectionEquality().hash(_details),createdAt,adminName);

@override
String toString() {
  return 'AuditLog(id: $id, adminId: $adminId, action: $action, entityType: $entityType, entityId: $entityId, details: $details, createdAt: $createdAt, adminName: $adminName)';
}


}

/// @nodoc
abstract mixin class _$AuditLogCopyWith<$Res> implements $AuditLogCopyWith<$Res> {
  factory _$AuditLogCopyWith(_AuditLog value, $Res Function(_AuditLog) _then) = __$AuditLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'admin_id') String adminId, String action,@JsonKey(name: 'entity_type') String entityType,@JsonKey(name: 'entity_id') String? entityId, Map<String, dynamic>? details,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'admin_name') String? adminName
});




}
/// @nodoc
class __$AuditLogCopyWithImpl<$Res>
    implements _$AuditLogCopyWith<$Res> {
  __$AuditLogCopyWithImpl(this._self, this._then);

  final _AuditLog _self;
  final $Res Function(_AuditLog) _then;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? adminId = null,Object? action = null,Object? entityType = null,Object? entityId = freezed,Object? details = freezed,Object? createdAt = null,Object? adminName = freezed,}) {
  return _then(_AuditLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminId: null == adminId ? _self.adminId : adminId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,adminName: freezed == adminName ? _self.adminName : adminName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
