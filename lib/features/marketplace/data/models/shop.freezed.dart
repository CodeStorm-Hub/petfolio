// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shop {

 String get id; String get ownerId; String get shopName; String get slug; String? get description; String? get logoUrl; String? get bannerUrl; bool get isActive; bool get isVerified; String? get stripeConnectAccountId; bool get stripeOnboardingComplete; int get platformFeePercent; PayoutMethod get payoutMethod; KycStatus get kycStatus; String? get tradeLicenseUrl; String? get nationalIdUrl; String? get rejectionReason; Map<String, dynamic>? get bankAccountDetails; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopCopyWith<Shop> get copyWith => _$ShopCopyWithImpl<Shop>(this as Shop, _$identity);

  /// Serializes this Shop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shop&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.stripeConnectAccountId, stripeConnectAccountId) || other.stripeConnectAccountId == stripeConnectAccountId)&&(identical(other.stripeOnboardingComplete, stripeOnboardingComplete) || other.stripeOnboardingComplete == stripeOnboardingComplete)&&(identical(other.platformFeePercent, platformFeePercent) || other.platformFeePercent == platformFeePercent)&&(identical(other.payoutMethod, payoutMethod) || other.payoutMethod == payoutMethod)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.tradeLicenseUrl, tradeLicenseUrl) || other.tradeLicenseUrl == tradeLicenseUrl)&&(identical(other.nationalIdUrl, nationalIdUrl) || other.nationalIdUrl == nationalIdUrl)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&const DeepCollectionEquality().equals(other.bankAccountDetails, bankAccountDetails)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,shopName,slug,description,logoUrl,bannerUrl,isActive,isVerified,stripeConnectAccountId,stripeOnboardingComplete,platformFeePercent,payoutMethod,kycStatus,tradeLicenseUrl,nationalIdUrl,rejectionReason,const DeepCollectionEquality().hash(bankAccountDetails),createdAt,updatedAt]);

@override
String toString() {
  return 'Shop(id: $id, ownerId: $ownerId, shopName: $shopName, slug: $slug, description: $description, logoUrl: $logoUrl, bannerUrl: $bannerUrl, isActive: $isActive, isVerified: $isVerified, stripeConnectAccountId: $stripeConnectAccountId, stripeOnboardingComplete: $stripeOnboardingComplete, platformFeePercent: $platformFeePercent, payoutMethod: $payoutMethod, kycStatus: $kycStatus, tradeLicenseUrl: $tradeLicenseUrl, nationalIdUrl: $nationalIdUrl, rejectionReason: $rejectionReason, bankAccountDetails: $bankAccountDetails, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShopCopyWith<$Res>  {
  factory $ShopCopyWith(Shop value, $Res Function(Shop) _then) = _$ShopCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String shopName, String slug, String? description, String? logoUrl, String? bannerUrl, bool isActive, bool isVerified, String? stripeConnectAccountId, bool stripeOnboardingComplete, int platformFeePercent, PayoutMethod payoutMethod, KycStatus kycStatus, String? tradeLicenseUrl, String? nationalIdUrl, String? rejectionReason, Map<String, dynamic>? bankAccountDetails, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ShopCopyWithImpl<$Res>
    implements $ShopCopyWith<$Res> {
  _$ShopCopyWithImpl(this._self, this._then);

  final Shop _self;
  final $Res Function(Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? shopName = null,Object? slug = null,Object? description = freezed,Object? logoUrl = freezed,Object? bannerUrl = freezed,Object? isActive = null,Object? isVerified = null,Object? stripeConnectAccountId = freezed,Object? stripeOnboardingComplete = null,Object? platformFeePercent = null,Object? payoutMethod = null,Object? kycStatus = null,Object? tradeLicenseUrl = freezed,Object? nationalIdUrl = freezed,Object? rejectionReason = freezed,Object? bankAccountDetails = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,stripeConnectAccountId: freezed == stripeConnectAccountId ? _self.stripeConnectAccountId : stripeConnectAccountId // ignore: cast_nullable_to_non_nullable
as String?,stripeOnboardingComplete: null == stripeOnboardingComplete ? _self.stripeOnboardingComplete : stripeOnboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,platformFeePercent: null == platformFeePercent ? _self.platformFeePercent : platformFeePercent // ignore: cast_nullable_to_non_nullable
as int,payoutMethod: null == payoutMethod ? _self.payoutMethod : payoutMethod // ignore: cast_nullable_to_non_nullable
as PayoutMethod,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as KycStatus,tradeLicenseUrl: freezed == tradeLicenseUrl ? _self.tradeLicenseUrl : tradeLicenseUrl // ignore: cast_nullable_to_non_nullable
as String?,nationalIdUrl: freezed == nationalIdUrl ? _self.nationalIdUrl : nationalIdUrl // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,bankAccountDetails: freezed == bankAccountDetails ? _self.bankAccountDetails : bankAccountDetails // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Shop].
extension ShopPatterns on Shop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shop value)  $default,){
final _that = this;
switch (_that) {
case _Shop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shop value)?  $default,){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String shopName,  String slug,  String? description,  String? logoUrl,  String? bannerUrl,  bool isActive,  bool isVerified,  String? stripeConnectAccountId,  bool stripeOnboardingComplete,  int platformFeePercent,  PayoutMethod payoutMethod,  KycStatus kycStatus,  String? tradeLicenseUrl,  String? nationalIdUrl,  String? rejectionReason,  Map<String, dynamic>? bankAccountDetails,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.id,_that.ownerId,_that.shopName,_that.slug,_that.description,_that.logoUrl,_that.bannerUrl,_that.isActive,_that.isVerified,_that.stripeConnectAccountId,_that.stripeOnboardingComplete,_that.platformFeePercent,_that.payoutMethod,_that.kycStatus,_that.tradeLicenseUrl,_that.nationalIdUrl,_that.rejectionReason,_that.bankAccountDetails,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String shopName,  String slug,  String? description,  String? logoUrl,  String? bannerUrl,  bool isActive,  bool isVerified,  String? stripeConnectAccountId,  bool stripeOnboardingComplete,  int platformFeePercent,  PayoutMethod payoutMethod,  KycStatus kycStatus,  String? tradeLicenseUrl,  String? nationalIdUrl,  String? rejectionReason,  Map<String, dynamic>? bankAccountDetails,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Shop():
return $default(_that.id,_that.ownerId,_that.shopName,_that.slug,_that.description,_that.logoUrl,_that.bannerUrl,_that.isActive,_that.isVerified,_that.stripeConnectAccountId,_that.stripeOnboardingComplete,_that.platformFeePercent,_that.payoutMethod,_that.kycStatus,_that.tradeLicenseUrl,_that.nationalIdUrl,_that.rejectionReason,_that.bankAccountDetails,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String shopName,  String slug,  String? description,  String? logoUrl,  String? bannerUrl,  bool isActive,  bool isVerified,  String? stripeConnectAccountId,  bool stripeOnboardingComplete,  int platformFeePercent,  PayoutMethod payoutMethod,  KycStatus kycStatus,  String? tradeLicenseUrl,  String? nationalIdUrl,  String? rejectionReason,  Map<String, dynamic>? bankAccountDetails,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.id,_that.ownerId,_that.shopName,_that.slug,_that.description,_that.logoUrl,_that.bannerUrl,_that.isActive,_that.isVerified,_that.stripeConnectAccountId,_that.stripeOnboardingComplete,_that.platformFeePercent,_that.payoutMethod,_that.kycStatus,_that.tradeLicenseUrl,_that.nationalIdUrl,_that.rejectionReason,_that.bankAccountDetails,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shop extends Shop {
  const _Shop({required this.id, required this.ownerId, required this.shopName, required this.slug, this.description, this.logoUrl, this.bannerUrl, required this.isActive, required this.isVerified, this.stripeConnectAccountId, required this.stripeOnboardingComplete, required this.platformFeePercent, required this.payoutMethod, required this.kycStatus, this.tradeLicenseUrl, this.nationalIdUrl, this.rejectionReason, final  Map<String, dynamic>? bankAccountDetails, required this.createdAt, required this.updatedAt}): _bankAccountDetails = bankAccountDetails,super._();
  factory _Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

@override final  String id;
@override final  String ownerId;
@override final  String shopName;
@override final  String slug;
@override final  String? description;
@override final  String? logoUrl;
@override final  String? bannerUrl;
@override final  bool isActive;
@override final  bool isVerified;
@override final  String? stripeConnectAccountId;
@override final  bool stripeOnboardingComplete;
@override final  int platformFeePercent;
@override final  PayoutMethod payoutMethod;
@override final  KycStatus kycStatus;
@override final  String? tradeLicenseUrl;
@override final  String? nationalIdUrl;
@override final  String? rejectionReason;
 final  Map<String, dynamic>? _bankAccountDetails;
@override Map<String, dynamic>? get bankAccountDetails {
  final value = _bankAccountDetails;
  if (value == null) return null;
  if (_bankAccountDetails is EqualUnmodifiableMapView) return _bankAccountDetails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopCopyWith<_Shop> get copyWith => __$ShopCopyWithImpl<_Shop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shop&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.stripeConnectAccountId, stripeConnectAccountId) || other.stripeConnectAccountId == stripeConnectAccountId)&&(identical(other.stripeOnboardingComplete, stripeOnboardingComplete) || other.stripeOnboardingComplete == stripeOnboardingComplete)&&(identical(other.platformFeePercent, platformFeePercent) || other.platformFeePercent == platformFeePercent)&&(identical(other.payoutMethod, payoutMethod) || other.payoutMethod == payoutMethod)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.tradeLicenseUrl, tradeLicenseUrl) || other.tradeLicenseUrl == tradeLicenseUrl)&&(identical(other.nationalIdUrl, nationalIdUrl) || other.nationalIdUrl == nationalIdUrl)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&const DeepCollectionEquality().equals(other._bankAccountDetails, _bankAccountDetails)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,shopName,slug,description,logoUrl,bannerUrl,isActive,isVerified,stripeConnectAccountId,stripeOnboardingComplete,platformFeePercent,payoutMethod,kycStatus,tradeLicenseUrl,nationalIdUrl,rejectionReason,const DeepCollectionEquality().hash(_bankAccountDetails),createdAt,updatedAt]);

@override
String toString() {
  return 'Shop(id: $id, ownerId: $ownerId, shopName: $shopName, slug: $slug, description: $description, logoUrl: $logoUrl, bannerUrl: $bannerUrl, isActive: $isActive, isVerified: $isVerified, stripeConnectAccountId: $stripeConnectAccountId, stripeOnboardingComplete: $stripeOnboardingComplete, platformFeePercent: $platformFeePercent, payoutMethod: $payoutMethod, kycStatus: $kycStatus, tradeLicenseUrl: $tradeLicenseUrl, nationalIdUrl: $nationalIdUrl, rejectionReason: $rejectionReason, bankAccountDetails: $bankAccountDetails, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShopCopyWith<$Res> implements $ShopCopyWith<$Res> {
  factory _$ShopCopyWith(_Shop value, $Res Function(_Shop) _then) = __$ShopCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String shopName, String slug, String? description, String? logoUrl, String? bannerUrl, bool isActive, bool isVerified, String? stripeConnectAccountId, bool stripeOnboardingComplete, int platformFeePercent, PayoutMethod payoutMethod, KycStatus kycStatus, String? tradeLicenseUrl, String? nationalIdUrl, String? rejectionReason, Map<String, dynamic>? bankAccountDetails, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ShopCopyWithImpl<$Res>
    implements _$ShopCopyWith<$Res> {
  __$ShopCopyWithImpl(this._self, this._then);

  final _Shop _self;
  final $Res Function(_Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? shopName = null,Object? slug = null,Object? description = freezed,Object? logoUrl = freezed,Object? bannerUrl = freezed,Object? isActive = null,Object? isVerified = null,Object? stripeConnectAccountId = freezed,Object? stripeOnboardingComplete = null,Object? platformFeePercent = null,Object? payoutMethod = null,Object? kycStatus = null,Object? tradeLicenseUrl = freezed,Object? nationalIdUrl = freezed,Object? rejectionReason = freezed,Object? bankAccountDetails = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Shop(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,stripeConnectAccountId: freezed == stripeConnectAccountId ? _self.stripeConnectAccountId : stripeConnectAccountId // ignore: cast_nullable_to_non_nullable
as String?,stripeOnboardingComplete: null == stripeOnboardingComplete ? _self.stripeOnboardingComplete : stripeOnboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,platformFeePercent: null == platformFeePercent ? _self.platformFeePercent : platformFeePercent // ignore: cast_nullable_to_non_nullable
as int,payoutMethod: null == payoutMethod ? _self.payoutMethod : payoutMethod // ignore: cast_nullable_to_non_nullable
as PayoutMethod,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as KycStatus,tradeLicenseUrl: freezed == tradeLicenseUrl ? _self.tradeLicenseUrl : tradeLicenseUrl // ignore: cast_nullable_to_non_nullable
as String?,nationalIdUrl: freezed == nationalIdUrl ? _self.nationalIdUrl : nationalIdUrl // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,bankAccountDetails: freezed == bankAccountDetails ? _self._bankAccountDetails : bankAccountDetails // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
