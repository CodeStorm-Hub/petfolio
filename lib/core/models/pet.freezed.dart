// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pet {

 String get id; String get ownerId; String get name; String get species; String? get breed; String? get avatarUrl; String? get bio; DateTime get createdAt; DateTime? get dateOfBirth;@_PetGenderConverter() PetGender get gender; double? get weightKg; String? get activityLevel; bool get isPublic; int get displayOrder; DateTime? get archivedAt; bool get isDiscoverable; String? get handle; String? get accentColor; DateTime? get updatedAt;
/// Create a copy of Pet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetCopyWith<Pet> get copyWith => _$PetCopyWithImpl<Pet>(this as Pet, _$identity);

  /// Serializes this Pet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pet&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,name,species,breed,avatarUrl,bio,createdAt,dateOfBirth,gender,weightKg,activityLevel,isPublic,displayOrder,archivedAt,isDiscoverable,handle,accentColor,updatedAt]);

@override
String toString() {
  return 'Pet(id: $id, ownerId: $ownerId, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, bio: $bio, createdAt: $createdAt, dateOfBirth: $dateOfBirth, gender: $gender, weightKg: $weightKg, activityLevel: $activityLevel, isPublic: $isPublic, displayOrder: $displayOrder, archivedAt: $archivedAt, isDiscoverable: $isDiscoverable, handle: $handle, accentColor: $accentColor, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PetCopyWith<$Res>  {
  factory $PetCopyWith(Pet value, $Res Function(Pet) _then) = _$PetCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String name, String species, String? breed, String? avatarUrl, String? bio, DateTime createdAt, DateTime? dateOfBirth,@_PetGenderConverter() PetGender gender, double? weightKg, String? activityLevel, bool isPublic, int displayOrder, DateTime? archivedAt, bool isDiscoverable, String? handle, String? accentColor, DateTime? updatedAt
});




}
/// @nodoc
class _$PetCopyWithImpl<$Res>
    implements $PetCopyWith<$Res> {
  _$PetCopyWithImpl(this._self, this._then);

  final Pet _self;
  final $Res Function(Pet) _then;

/// Create a copy of Pet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? species = null,Object? breed = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? createdAt = null,Object? dateOfBirth = freezed,Object? gender = null,Object? weightKg = freezed,Object? activityLevel = freezed,Object? isPublic = null,Object? displayOrder = null,Object? archivedAt = freezed,Object? isDiscoverable = null,Object? handle = freezed,Object? accentColor = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PetGender,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityLevel: freezed == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,handle: freezed == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Pet].
extension PetPatterns on Pet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pet value)  $default,){
final _that = this;
switch (_that) {
case _Pet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pet value)?  $default,){
final _that = this;
switch (_that) {
case _Pet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? avatarUrl,  String? bio,  DateTime createdAt,  DateTime? dateOfBirth, @_PetGenderConverter()  PetGender gender,  double? weightKg,  String? activityLevel,  bool isPublic,  int displayOrder,  DateTime? archivedAt,  bool isDiscoverable,  String? handle,  String? accentColor,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pet() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.bio,_that.createdAt,_that.dateOfBirth,_that.gender,_that.weightKg,_that.activityLevel,_that.isPublic,_that.displayOrder,_that.archivedAt,_that.isDiscoverable,_that.handle,_that.accentColor,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? avatarUrl,  String? bio,  DateTime createdAt,  DateTime? dateOfBirth, @_PetGenderConverter()  PetGender gender,  double? weightKg,  String? activityLevel,  bool isPublic,  int displayOrder,  DateTime? archivedAt,  bool isDiscoverable,  String? handle,  String? accentColor,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Pet():
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.bio,_that.createdAt,_that.dateOfBirth,_that.gender,_that.weightKg,_that.activityLevel,_that.isPublic,_that.displayOrder,_that.archivedAt,_that.isDiscoverable,_that.handle,_that.accentColor,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? avatarUrl,  String? bio,  DateTime createdAt,  DateTime? dateOfBirth, @_PetGenderConverter()  PetGender gender,  double? weightKg,  String? activityLevel,  bool isPublic,  int displayOrder,  DateTime? archivedAt,  bool isDiscoverable,  String? handle,  String? accentColor,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Pet() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.bio,_that.createdAt,_that.dateOfBirth,_that.gender,_that.weightKg,_that.activityLevel,_that.isPublic,_that.displayOrder,_that.archivedAt,_that.isDiscoverable,_that.handle,_that.accentColor,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pet extends Pet {
  const _Pet({required this.id, required this.ownerId, required this.name, required this.species, this.breed, this.avatarUrl, this.bio, required this.createdAt, this.dateOfBirth, @_PetGenderConverter() this.gender = PetGender.unknown, this.weightKg, this.activityLevel, this.isPublic = true, this.displayOrder = 0, this.archivedAt, this.isDiscoverable = false, this.handle, this.accentColor, this.updatedAt}): super._();
  factory _Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);

@override final  String id;
@override final  String ownerId;
@override final  String name;
@override final  String species;
@override final  String? breed;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  DateTime createdAt;
@override final  DateTime? dateOfBirth;
@override@JsonKey()@_PetGenderConverter() final  PetGender gender;
@override final  double? weightKg;
@override final  String? activityLevel;
@override@JsonKey() final  bool isPublic;
@override@JsonKey() final  int displayOrder;
@override final  DateTime? archivedAt;
@override@JsonKey() final  bool isDiscoverable;
@override final  String? handle;
@override final  String? accentColor;
@override final  DateTime? updatedAt;

/// Create a copy of Pet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetCopyWith<_Pet> get copyWith => __$PetCopyWithImpl<_Pet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pet&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,name,species,breed,avatarUrl,bio,createdAt,dateOfBirth,gender,weightKg,activityLevel,isPublic,displayOrder,archivedAt,isDiscoverable,handle,accentColor,updatedAt]);

@override
String toString() {
  return 'Pet(id: $id, ownerId: $ownerId, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, bio: $bio, createdAt: $createdAt, dateOfBirth: $dateOfBirth, gender: $gender, weightKg: $weightKg, activityLevel: $activityLevel, isPublic: $isPublic, displayOrder: $displayOrder, archivedAt: $archivedAt, isDiscoverable: $isDiscoverable, handle: $handle, accentColor: $accentColor, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PetCopyWith<$Res> implements $PetCopyWith<$Res> {
  factory _$PetCopyWith(_Pet value, $Res Function(_Pet) _then) = __$PetCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String name, String species, String? breed, String? avatarUrl, String? bio, DateTime createdAt, DateTime? dateOfBirth,@_PetGenderConverter() PetGender gender, double? weightKg, String? activityLevel, bool isPublic, int displayOrder, DateTime? archivedAt, bool isDiscoverable, String? handle, String? accentColor, DateTime? updatedAt
});




}
/// @nodoc
class __$PetCopyWithImpl<$Res>
    implements _$PetCopyWith<$Res> {
  __$PetCopyWithImpl(this._self, this._then);

  final _Pet _self;
  final $Res Function(_Pet) _then;

/// Create a copy of Pet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? species = null,Object? breed = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? createdAt = null,Object? dateOfBirth = freezed,Object? gender = null,Object? weightKg = freezed,Object? activityLevel = freezed,Object? isPublic = null,Object? displayOrder = null,Object? archivedAt = freezed,Object? isDiscoverable = null,Object? handle = freezed,Object? accentColor = freezed,Object? updatedAt = freezed,}) {
  return _then(_Pet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PetGender,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityLevel: freezed == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,handle: freezed == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
