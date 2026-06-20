// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'matching_discovery_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchingDiscoveryOwner {

 String get id; String? get username; String? get displayName;
/// Create a copy of MatchingDiscoveryOwner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchingDiscoveryOwnerCopyWith<MatchingDiscoveryOwner> get copyWith => _$MatchingDiscoveryOwnerCopyWithImpl<MatchingDiscoveryOwner>(this as MatchingDiscoveryOwner, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchingDiscoveryOwner&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName);

@override
String toString() {
  return 'MatchingDiscoveryOwner(id: $id, username: $username, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $MatchingDiscoveryOwnerCopyWith<$Res>  {
  factory $MatchingDiscoveryOwnerCopyWith(MatchingDiscoveryOwner value, $Res Function(MatchingDiscoveryOwner) _then) = _$MatchingDiscoveryOwnerCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? displayName
});




}
/// @nodoc
class _$MatchingDiscoveryOwnerCopyWithImpl<$Res>
    implements $MatchingDiscoveryOwnerCopyWith<$Res> {
  _$MatchingDiscoveryOwnerCopyWithImpl(this._self, this._then);

  final MatchingDiscoveryOwner _self;
  final $Res Function(MatchingDiscoveryOwner) _then;

/// Create a copy of MatchingDiscoveryOwner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchingDiscoveryOwner].
extension MatchingDiscoveryOwnerPatterns on MatchingDiscoveryOwner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchingDiscoveryOwner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchingDiscoveryOwner value)  $default,){
final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchingDiscoveryOwner value)?  $default,){
final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner() when $default != null:
return $default(_that.id,_that.username,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName)  $default,) {final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner():
return $default(_that.id,_that.username,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? displayName)?  $default,) {final _that = this;
switch (_that) {
case _MatchingDiscoveryOwner() when $default != null:
return $default(_that.id,_that.username,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc


class _MatchingDiscoveryOwner implements MatchingDiscoveryOwner {
  const _MatchingDiscoveryOwner({required this.id, this.username, this.displayName});
  

@override final  String id;
@override final  String? username;
@override final  String? displayName;

/// Create a copy of MatchingDiscoveryOwner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchingDiscoveryOwnerCopyWith<_MatchingDiscoveryOwner> get copyWith => __$MatchingDiscoveryOwnerCopyWithImpl<_MatchingDiscoveryOwner>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchingDiscoveryOwner&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName);

@override
String toString() {
  return 'MatchingDiscoveryOwner(id: $id, username: $username, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$MatchingDiscoveryOwnerCopyWith<$Res> implements $MatchingDiscoveryOwnerCopyWith<$Res> {
  factory _$MatchingDiscoveryOwnerCopyWith(_MatchingDiscoveryOwner value, $Res Function(_MatchingDiscoveryOwner) _then) = __$MatchingDiscoveryOwnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? displayName
});




}
/// @nodoc
class __$MatchingDiscoveryOwnerCopyWithImpl<$Res>
    implements _$MatchingDiscoveryOwnerCopyWith<$Res> {
  __$MatchingDiscoveryOwnerCopyWithImpl(this._self, this._then);

  final _MatchingDiscoveryOwner _self;
  final $Res Function(_MatchingDiscoveryOwner) _then;

/// Create a copy of MatchingDiscoveryOwner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,}) {
  return _then(_MatchingDiscoveryOwner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$MatchingDiscoveryRow {

 String get id; String get ownerId; String get name; String get species; String? get breed; String? get gender; DateTime? get dateOfBirth; String? get avatarUrl; String? get bio; double? get distanceMeters; bool get isDiscoverable; DateTime? get createdAt; MatchingDiscoveryOwner? get owner;
/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchingDiscoveryRowCopyWith<MatchingDiscoveryRow> get copyWith => _$MatchingDiscoveryRowCopyWithImpl<MatchingDiscoveryRow>(this as MatchingDiscoveryRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchingDiscoveryRow&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerId,name,species,breed,gender,dateOfBirth,avatarUrl,bio,distanceMeters,isDiscoverable,createdAt,owner);

@override
String toString() {
  return 'MatchingDiscoveryRow(id: $id, ownerId: $ownerId, name: $name, species: $species, breed: $breed, gender: $gender, dateOfBirth: $dateOfBirth, avatarUrl: $avatarUrl, bio: $bio, distanceMeters: $distanceMeters, isDiscoverable: $isDiscoverable, createdAt: $createdAt, owner: $owner)';
}


}

/// @nodoc
abstract mixin class $MatchingDiscoveryRowCopyWith<$Res>  {
  factory $MatchingDiscoveryRowCopyWith(MatchingDiscoveryRow value, $Res Function(MatchingDiscoveryRow) _then) = _$MatchingDiscoveryRowCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String name, String species, String? breed, String? gender, DateTime? dateOfBirth, String? avatarUrl, String? bio, double? distanceMeters, bool isDiscoverable, DateTime? createdAt, MatchingDiscoveryOwner? owner
});


$MatchingDiscoveryOwnerCopyWith<$Res>? get owner;

}
/// @nodoc
class _$MatchingDiscoveryRowCopyWithImpl<$Res>
    implements $MatchingDiscoveryRowCopyWith<$Res> {
  _$MatchingDiscoveryRowCopyWithImpl(this._self, this._then);

  final MatchingDiscoveryRow _self;
  final $Res Function(MatchingDiscoveryRow) _then;

/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? species = null,Object? breed = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? distanceMeters = freezed,Object? isDiscoverable = null,Object? createdAt = freezed,Object? owner = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as MatchingDiscoveryOwner?,
  ));
}
/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchingDiscoveryOwnerCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $MatchingDiscoveryOwnerCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [MatchingDiscoveryRow].
extension MatchingDiscoveryRowPatterns on MatchingDiscoveryRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchingDiscoveryRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchingDiscoveryRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchingDiscoveryRow value)  $default,){
final _that = this;
switch (_that) {
case _MatchingDiscoveryRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchingDiscoveryRow value)?  $default,){
final _that = this;
switch (_that) {
case _MatchingDiscoveryRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? gender,  DateTime? dateOfBirth,  String? avatarUrl,  String? bio,  double? distanceMeters,  bool isDiscoverable,  DateTime? createdAt,  MatchingDiscoveryOwner? owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchingDiscoveryRow() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.gender,_that.dateOfBirth,_that.avatarUrl,_that.bio,_that.distanceMeters,_that.isDiscoverable,_that.createdAt,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? gender,  DateTime? dateOfBirth,  String? avatarUrl,  String? bio,  double? distanceMeters,  bool isDiscoverable,  DateTime? createdAt,  MatchingDiscoveryOwner? owner)  $default,) {final _that = this;
switch (_that) {
case _MatchingDiscoveryRow():
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.gender,_that.dateOfBirth,_that.avatarUrl,_that.bio,_that.distanceMeters,_that.isDiscoverable,_that.createdAt,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String name,  String species,  String? breed,  String? gender,  DateTime? dateOfBirth,  String? avatarUrl,  String? bio,  double? distanceMeters,  bool isDiscoverable,  DateTime? createdAt,  MatchingDiscoveryOwner? owner)?  $default,) {final _that = this;
switch (_that) {
case _MatchingDiscoveryRow() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.species,_that.breed,_that.gender,_that.dateOfBirth,_that.avatarUrl,_that.bio,_that.distanceMeters,_that.isDiscoverable,_that.createdAt,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _MatchingDiscoveryRow implements MatchingDiscoveryRow {
  const _MatchingDiscoveryRow({required this.id, required this.ownerId, required this.name, required this.species, this.breed, this.gender, this.dateOfBirth, this.avatarUrl, this.bio, this.distanceMeters, this.isDiscoverable = false, this.createdAt, this.owner});
  

@override final  String id;
@override final  String ownerId;
@override final  String name;
@override final  String species;
@override final  String? breed;
@override final  String? gender;
@override final  DateTime? dateOfBirth;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  double? distanceMeters;
@override@JsonKey() final  bool isDiscoverable;
@override final  DateTime? createdAt;
@override final  MatchingDiscoveryOwner? owner;

/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchingDiscoveryRowCopyWith<_MatchingDiscoveryRow> get copyWith => __$MatchingDiscoveryRowCopyWithImpl<_MatchingDiscoveryRow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchingDiscoveryRow&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerId,name,species,breed,gender,dateOfBirth,avatarUrl,bio,distanceMeters,isDiscoverable,createdAt,owner);

@override
String toString() {
  return 'MatchingDiscoveryRow(id: $id, ownerId: $ownerId, name: $name, species: $species, breed: $breed, gender: $gender, dateOfBirth: $dateOfBirth, avatarUrl: $avatarUrl, bio: $bio, distanceMeters: $distanceMeters, isDiscoverable: $isDiscoverable, createdAt: $createdAt, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$MatchingDiscoveryRowCopyWith<$Res> implements $MatchingDiscoveryRowCopyWith<$Res> {
  factory _$MatchingDiscoveryRowCopyWith(_MatchingDiscoveryRow value, $Res Function(_MatchingDiscoveryRow) _then) = __$MatchingDiscoveryRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String name, String species, String? breed, String? gender, DateTime? dateOfBirth, String? avatarUrl, String? bio, double? distanceMeters, bool isDiscoverable, DateTime? createdAt, MatchingDiscoveryOwner? owner
});


@override $MatchingDiscoveryOwnerCopyWith<$Res>? get owner;

}
/// @nodoc
class __$MatchingDiscoveryRowCopyWithImpl<$Res>
    implements _$MatchingDiscoveryRowCopyWith<$Res> {
  __$MatchingDiscoveryRowCopyWithImpl(this._self, this._then);

  final _MatchingDiscoveryRow _self;
  final $Res Function(_MatchingDiscoveryRow) _then;

/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? species = null,Object? breed = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? distanceMeters = freezed,Object? isDiscoverable = null,Object? createdAt = freezed,Object? owner = freezed,}) {
  return _then(_MatchingDiscoveryRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as MatchingDiscoveryOwner?,
  ));
}

/// Create a copy of MatchingDiscoveryRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchingDiscoveryOwnerCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $MatchingDiscoveryOwnerCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

// dart format on
