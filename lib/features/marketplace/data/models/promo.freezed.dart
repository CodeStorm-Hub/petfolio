// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Promo {

 String get id; String get code; String get description;@JsonKey(name: 'discount_type') PromoDiscountType get discountType;@JsonKey(name: 'discount_value') int get discountValue;@JsonKey(name: 'min_order_cents') int get minOrderCents;@JsonKey(name: 'max_discount_cents') int? get maxDiscountCents; String get category;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'valid_until') DateTime? get validUntil;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of Promo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoCopyWith<Promo> get copyWith => _$PromoCopyWithImpl<Promo>(this as Promo, _$identity);

  /// Serializes this Promo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Promo&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.minOrderCents, minOrderCents) || other.minOrderCents == minOrderCents)&&(identical(other.maxDiscountCents, maxDiscountCents) || other.maxDiscountCents == maxDiscountCents)&&(identical(other.category, category) || other.category == category)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,description,discountType,discountValue,minOrderCents,maxDiscountCents,category,isActive,validUntil,createdAt);

@override
String toString() {
  return 'Promo(id: $id, code: $code, description: $description, discountType: $discountType, discountValue: $discountValue, minOrderCents: $minOrderCents, maxDiscountCents: $maxDiscountCents, category: $category, isActive: $isActive, validUntil: $validUntil, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PromoCopyWith<$Res>  {
  factory $PromoCopyWith(Promo value, $Res Function(Promo) _then) = _$PromoCopyWithImpl;
@useResult
$Res call({
 String id, String code, String description,@JsonKey(name: 'discount_type') PromoDiscountType discountType,@JsonKey(name: 'discount_value') int discountValue,@JsonKey(name: 'min_order_cents') int minOrderCents,@JsonKey(name: 'max_discount_cents') int? maxDiscountCents, String category,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'valid_until') DateTime? validUntil,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$PromoCopyWithImpl<$Res>
    implements $PromoCopyWith<$Res> {
  _$PromoCopyWithImpl(this._self, this._then);

  final Promo _self;
  final $Res Function(Promo) _then;

/// Create a copy of Promo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? description = null,Object? discountType = null,Object? discountValue = null,Object? minOrderCents = null,Object? maxDiscountCents = freezed,Object? category = null,Object? isActive = null,Object? validUntil = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as PromoDiscountType,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as int,minOrderCents: null == minOrderCents ? _self.minOrderCents : minOrderCents // ignore: cast_nullable_to_non_nullable
as int,maxDiscountCents: freezed == maxDiscountCents ? _self.maxDiscountCents : maxDiscountCents // ignore: cast_nullable_to_non_nullable
as int?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Promo].
extension PromoPatterns on Promo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Promo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Promo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Promo value)  $default,){
final _that = this;
switch (_that) {
case _Promo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Promo value)?  $default,){
final _that = this;
switch (_that) {
case _Promo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String description, @JsonKey(name: 'discount_type')  PromoDiscountType discountType, @JsonKey(name: 'discount_value')  int discountValue, @JsonKey(name: 'min_order_cents')  int minOrderCents, @JsonKey(name: 'max_discount_cents')  int? maxDiscountCents,  String category, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'valid_until')  DateTime? validUntil, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Promo() when $default != null:
return $default(_that.id,_that.code,_that.description,_that.discountType,_that.discountValue,_that.minOrderCents,_that.maxDiscountCents,_that.category,_that.isActive,_that.validUntil,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String description, @JsonKey(name: 'discount_type')  PromoDiscountType discountType, @JsonKey(name: 'discount_value')  int discountValue, @JsonKey(name: 'min_order_cents')  int minOrderCents, @JsonKey(name: 'max_discount_cents')  int? maxDiscountCents,  String category, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'valid_until')  DateTime? validUntil, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Promo():
return $default(_that.id,_that.code,_that.description,_that.discountType,_that.discountValue,_that.minOrderCents,_that.maxDiscountCents,_that.category,_that.isActive,_that.validUntil,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String description, @JsonKey(name: 'discount_type')  PromoDiscountType discountType, @JsonKey(name: 'discount_value')  int discountValue, @JsonKey(name: 'min_order_cents')  int minOrderCents, @JsonKey(name: 'max_discount_cents')  int? maxDiscountCents,  String category, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'valid_until')  DateTime? validUntil, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Promo() when $default != null:
return $default(_that.id,_that.code,_that.description,_that.discountType,_that.discountValue,_that.minOrderCents,_that.maxDiscountCents,_that.category,_that.isActive,_that.validUntil,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Promo extends Promo {
  const _Promo({required this.id, required this.code, required this.description, @JsonKey(name: 'discount_type') required this.discountType, @JsonKey(name: 'discount_value') required this.discountValue, @JsonKey(name: 'min_order_cents') required this.minOrderCents, @JsonKey(name: 'max_discount_cents') this.maxDiscountCents, required this.category, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'valid_until') this.validUntil, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _Promo.fromJson(Map<String, dynamic> json) => _$PromoFromJson(json);

@override final  String id;
@override final  String code;
@override final  String description;
@override@JsonKey(name: 'discount_type') final  PromoDiscountType discountType;
@override@JsonKey(name: 'discount_value') final  int discountValue;
@override@JsonKey(name: 'min_order_cents') final  int minOrderCents;
@override@JsonKey(name: 'max_discount_cents') final  int? maxDiscountCents;
@override final  String category;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'valid_until') final  DateTime? validUntil;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of Promo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoCopyWith<_Promo> get copyWith => __$PromoCopyWithImpl<_Promo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Promo&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.minOrderCents, minOrderCents) || other.minOrderCents == minOrderCents)&&(identical(other.maxDiscountCents, maxDiscountCents) || other.maxDiscountCents == maxDiscountCents)&&(identical(other.category, category) || other.category == category)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,description,discountType,discountValue,minOrderCents,maxDiscountCents,category,isActive,validUntil,createdAt);

@override
String toString() {
  return 'Promo(id: $id, code: $code, description: $description, discountType: $discountType, discountValue: $discountValue, minOrderCents: $minOrderCents, maxDiscountCents: $maxDiscountCents, category: $category, isActive: $isActive, validUntil: $validUntil, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PromoCopyWith<$Res> implements $PromoCopyWith<$Res> {
  factory _$PromoCopyWith(_Promo value, $Res Function(_Promo) _then) = __$PromoCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String description,@JsonKey(name: 'discount_type') PromoDiscountType discountType,@JsonKey(name: 'discount_value') int discountValue,@JsonKey(name: 'min_order_cents') int minOrderCents,@JsonKey(name: 'max_discount_cents') int? maxDiscountCents, String category,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'valid_until') DateTime? validUntil,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$PromoCopyWithImpl<$Res>
    implements _$PromoCopyWith<$Res> {
  __$PromoCopyWithImpl(this._self, this._then);

  final _Promo _self;
  final $Res Function(_Promo) _then;

/// Create a copy of Promo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? description = null,Object? discountType = null,Object? discountValue = null,Object? minOrderCents = null,Object? maxDiscountCents = freezed,Object? category = null,Object? isActive = null,Object? validUntil = freezed,Object? createdAt = null,}) {
  return _then(_Promo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as PromoDiscountType,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as int,minOrderCents: null == minOrderCents ? _self.minOrderCents : minOrderCents // ignore: cast_nullable_to_non_nullable
as int,maxDiscountCents: freezed == maxDiscountCents ? _self.maxDiscountCents : maxDiscountCents // ignore: cast_nullable_to_non_nullable
as int?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
