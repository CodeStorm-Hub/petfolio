// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vet_clinic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VetClinic {

 String get id; String get name; String? get tagline; String get address; String get city; String? get phone; String? get email; String? get website;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(fromJson: _ratingFromJson) double get rating;@JsonKey(name: 'review_count') int get reviewCount;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of VetClinic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VetClinicCopyWith<VetClinic> get copyWith => _$VetClinicCopyWithImpl<VetClinic>(this as VetClinic, _$identity);

  /// Serializes this VetClinic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VetClinic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tagline,address,city,phone,email,website,avatarUrl,rating,reviewCount,isActive,createdAt);

@override
String toString() {
  return 'VetClinic(id: $id, name: $name, tagline: $tagline, address: $address, city: $city, phone: $phone, email: $email, website: $website, avatarUrl: $avatarUrl, rating: $rating, reviewCount: $reviewCount, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VetClinicCopyWith<$Res>  {
  factory $VetClinicCopyWith(VetClinic value, $Res Function(VetClinic) _then) = _$VetClinicCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? tagline, String address, String city, String? phone, String? email, String? website,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(fromJson: _ratingFromJson) double rating,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$VetClinicCopyWithImpl<$Res>
    implements $VetClinicCopyWith<$Res> {
  _$VetClinicCopyWithImpl(this._self, this._then);

  final VetClinic _self;
  final $Res Function(VetClinic) _then;

/// Create a copy of VetClinic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = freezed,Object? address = null,Object? city = null,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? avatarUrl = freezed,Object? rating = null,Object? reviewCount = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VetClinic].
extension VetClinicPatterns on VetClinic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VetClinic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VetClinic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VetClinic value)  $default,){
final _that = this;
switch (_that) {
case _VetClinic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VetClinic value)?  $default,){
final _that = this;
switch (_that) {
case _VetClinic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? tagline,  String address,  String city,  String? phone,  String? email,  String? website, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(fromJson: _ratingFromJson)  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VetClinic() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.address,_that.city,_that.phone,_that.email,_that.website,_that.avatarUrl,_that.rating,_that.reviewCount,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? tagline,  String address,  String city,  String? phone,  String? email,  String? website, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(fromJson: _ratingFromJson)  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _VetClinic():
return $default(_that.id,_that.name,_that.tagline,_that.address,_that.city,_that.phone,_that.email,_that.website,_that.avatarUrl,_that.rating,_that.reviewCount,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? tagline,  String address,  String city,  String? phone,  String? email,  String? website, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(fromJson: _ratingFromJson)  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VetClinic() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.address,_that.city,_that.phone,_that.email,_that.website,_that.avatarUrl,_that.rating,_that.reviewCount,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VetClinic implements VetClinic {
  const _VetClinic({required this.id, required this.name, this.tagline, required this.address, required this.city, this.phone, this.email, this.website, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(fromJson: _ratingFromJson) required this.rating, @JsonKey(name: 'review_count') required this.reviewCount, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'created_at') required this.createdAt});
  factory _VetClinic.fromJson(Map<String, dynamic> json) => _$VetClinicFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? tagline;
@override final  String address;
@override final  String city;
@override final  String? phone;
@override final  String? email;
@override final  String? website;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(fromJson: _ratingFromJson) final  double rating;
@override@JsonKey(name: 'review_count') final  int reviewCount;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of VetClinic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VetClinicCopyWith<_VetClinic> get copyWith => __$VetClinicCopyWithImpl<_VetClinic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VetClinicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VetClinic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tagline,address,city,phone,email,website,avatarUrl,rating,reviewCount,isActive,createdAt);

@override
String toString() {
  return 'VetClinic(id: $id, name: $name, tagline: $tagline, address: $address, city: $city, phone: $phone, email: $email, website: $website, avatarUrl: $avatarUrl, rating: $rating, reviewCount: $reviewCount, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VetClinicCopyWith<$Res> implements $VetClinicCopyWith<$Res> {
  factory _$VetClinicCopyWith(_VetClinic value, $Res Function(_VetClinic) _then) = __$VetClinicCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? tagline, String address, String city, String? phone, String? email, String? website,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(fromJson: _ratingFromJson) double rating,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$VetClinicCopyWithImpl<$Res>
    implements _$VetClinicCopyWith<$Res> {
  __$VetClinicCopyWithImpl(this._self, this._then);

  final _VetClinic _self;
  final $Res Function(_VetClinic) _then;

/// Create a copy of VetClinic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = freezed,Object? address = null,Object? city = null,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? avatarUrl = freezed,Object? rating = null,Object? reviewCount = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_VetClinic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
