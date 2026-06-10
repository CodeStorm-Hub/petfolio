// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vet_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VetService {

 String get id;@JsonKey(name: 'clinic_id') String get clinicId; String get name; String? get description;@JsonKey(name: 'duration_minutes') int get durationMinutes;@JsonKey(name: 'price_cents') int get priceCents;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of VetService
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VetServiceCopyWith<VetService> get copyWith => _$VetServiceCopyWithImpl<VetService>(this as VetService, _$identity);

  /// Serializes this VetService to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VetService&&(identical(other.id, id) || other.id == id)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,clinicId,name,description,durationMinutes,priceCents,createdAt);

@override
String toString() {
  return 'VetService(id: $id, clinicId: $clinicId, name: $name, description: $description, durationMinutes: $durationMinutes, priceCents: $priceCents, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VetServiceCopyWith<$Res>  {
  factory $VetServiceCopyWith(VetService value, $Res Function(VetService) _then) = _$VetServiceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'clinic_id') String clinicId, String name, String? description,@JsonKey(name: 'duration_minutes') int durationMinutes,@JsonKey(name: 'price_cents') int priceCents,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$VetServiceCopyWithImpl<$Res>
    implements $VetServiceCopyWith<$Res> {
  _$VetServiceCopyWithImpl(this._self, this._then);

  final VetService _self;
  final $Res Function(VetService) _then;

/// Create a copy of VetService
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clinicId = null,Object? name = null,Object? description = freezed,Object? durationMinutes = null,Object? priceCents = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clinicId: null == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VetService].
extension VetServicePatterns on VetService {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VetService value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VetService() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VetService value)  $default,){
final _that = this;
switch (_that) {
case _VetService():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VetService value)?  $default,){
final _that = this;
switch (_that) {
case _VetService() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'clinic_id')  String clinicId,  String name,  String? description, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'price_cents')  int priceCents, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VetService() when $default != null:
return $default(_that.id,_that.clinicId,_that.name,_that.description,_that.durationMinutes,_that.priceCents,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'clinic_id')  String clinicId,  String name,  String? description, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'price_cents')  int priceCents, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _VetService():
return $default(_that.id,_that.clinicId,_that.name,_that.description,_that.durationMinutes,_that.priceCents,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'clinic_id')  String clinicId,  String name,  String? description, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'price_cents')  int priceCents, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VetService() when $default != null:
return $default(_that.id,_that.clinicId,_that.name,_that.description,_that.durationMinutes,_that.priceCents,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VetService extends VetService {
  const _VetService({required this.id, @JsonKey(name: 'clinic_id') required this.clinicId, required this.name, this.description, @JsonKey(name: 'duration_minutes') required this.durationMinutes, @JsonKey(name: 'price_cents') required this.priceCents, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _VetService.fromJson(Map<String, dynamic> json) => _$VetServiceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'clinic_id') final  String clinicId;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'duration_minutes') final  int durationMinutes;
@override@JsonKey(name: 'price_cents') final  int priceCents;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of VetService
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VetServiceCopyWith<_VetService> get copyWith => __$VetServiceCopyWithImpl<_VetService>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VetServiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VetService&&(identical(other.id, id) || other.id == id)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,clinicId,name,description,durationMinutes,priceCents,createdAt);

@override
String toString() {
  return 'VetService(id: $id, clinicId: $clinicId, name: $name, description: $description, durationMinutes: $durationMinutes, priceCents: $priceCents, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VetServiceCopyWith<$Res> implements $VetServiceCopyWith<$Res> {
  factory _$VetServiceCopyWith(_VetService value, $Res Function(_VetService) _then) = __$VetServiceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'clinic_id') String clinicId, String name, String? description,@JsonKey(name: 'duration_minutes') int durationMinutes,@JsonKey(name: 'price_cents') int priceCents,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$VetServiceCopyWithImpl<$Res>
    implements _$VetServiceCopyWith<$Res> {
  __$VetServiceCopyWithImpl(this._self, this._then);

  final _VetService _self;
  final $Res Function(_VetService) _then;

/// Create a copy of VetService
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clinicId = null,Object? name = null,Object? description = freezed,Object? durationMinutes = null,Object? priceCents = null,Object? createdAt = null,}) {
  return _then(_VetService(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clinicId: null == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
