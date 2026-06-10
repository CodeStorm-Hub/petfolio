// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vet_booking_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VetBookingState {

 VetClinic? get clinic; VetService? get service; DateTime? get selectedDate; DateTime? get selectedSlot; String? get petId; String? get notes; VetBookingStatus get status; String? get errorMessage; String get urgency; String? get reason; String? get mediaUrl; XFile? get selectedMedia;
/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VetBookingStateCopyWith<VetBookingState> get copyWith => _$VetBookingStateCopyWithImpl<VetBookingState>(this as VetBookingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VetBookingState&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.service, service) || other.service == service)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedSlot, selectedSlot) || other.selectedSlot == selectedSlot)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.selectedMedia, selectedMedia) || other.selectedMedia == selectedMedia));
}


@override
int get hashCode => Object.hash(runtimeType,clinic,service,selectedDate,selectedSlot,petId,notes,status,errorMessage,urgency,reason,mediaUrl,selectedMedia);

@override
String toString() {
  return 'VetBookingState(clinic: $clinic, service: $service, selectedDate: $selectedDate, selectedSlot: $selectedSlot, petId: $petId, notes: $notes, status: $status, errorMessage: $errorMessage, urgency: $urgency, reason: $reason, mediaUrl: $mediaUrl, selectedMedia: $selectedMedia)';
}


}

/// @nodoc
abstract mixin class $VetBookingStateCopyWith<$Res>  {
  factory $VetBookingStateCopyWith(VetBookingState value, $Res Function(VetBookingState) _then) = _$VetBookingStateCopyWithImpl;
@useResult
$Res call({
 VetClinic? clinic, VetService? service, DateTime? selectedDate, DateTime? selectedSlot, String? petId, String? notes, VetBookingStatus status, String? errorMessage, String urgency, String? reason, String? mediaUrl, XFile? selectedMedia
});


$VetClinicCopyWith<$Res>? get clinic;$VetServiceCopyWith<$Res>? get service;

}
/// @nodoc
class _$VetBookingStateCopyWithImpl<$Res>
    implements $VetBookingStateCopyWith<$Res> {
  _$VetBookingStateCopyWithImpl(this._self, this._then);

  final VetBookingState _self;
  final $Res Function(VetBookingState) _then;

/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clinic = freezed,Object? service = freezed,Object? selectedDate = freezed,Object? selectedSlot = freezed,Object? petId = freezed,Object? notes = freezed,Object? status = null,Object? errorMessage = freezed,Object? urgency = null,Object? reason = freezed,Object? mediaUrl = freezed,Object? selectedMedia = freezed,}) {
  return _then(_self.copyWith(
clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as VetClinic?,service: freezed == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as VetService?,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as DateTime?,petId: freezed == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VetBookingStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,selectedMedia: freezed == selectedMedia ? _self.selectedMedia : selectedMedia // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}
/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VetClinicCopyWith<$Res>? get clinic {
    if (_self.clinic == null) {
    return null;
  }

  return $VetClinicCopyWith<$Res>(_self.clinic!, (value) {
    return _then(_self.copyWith(clinic: value));
  });
}/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VetServiceCopyWith<$Res>? get service {
    if (_self.service == null) {
    return null;
  }

  return $VetServiceCopyWith<$Res>(_self.service!, (value) {
    return _then(_self.copyWith(service: value));
  });
}
}


/// Adds pattern-matching-related methods to [VetBookingState].
extension VetBookingStatePatterns on VetBookingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VetBookingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VetBookingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VetBookingState value)  $default,){
final _that = this;
switch (_that) {
case _VetBookingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VetBookingState value)?  $default,){
final _that = this;
switch (_that) {
case _VetBookingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VetClinic? clinic,  VetService? service,  DateTime? selectedDate,  DateTime? selectedSlot,  String? petId,  String? notes,  VetBookingStatus status,  String? errorMessage,  String urgency,  String? reason,  String? mediaUrl,  XFile? selectedMedia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VetBookingState() when $default != null:
return $default(_that.clinic,_that.service,_that.selectedDate,_that.selectedSlot,_that.petId,_that.notes,_that.status,_that.errorMessage,_that.urgency,_that.reason,_that.mediaUrl,_that.selectedMedia);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VetClinic? clinic,  VetService? service,  DateTime? selectedDate,  DateTime? selectedSlot,  String? petId,  String? notes,  VetBookingStatus status,  String? errorMessage,  String urgency,  String? reason,  String? mediaUrl,  XFile? selectedMedia)  $default,) {final _that = this;
switch (_that) {
case _VetBookingState():
return $default(_that.clinic,_that.service,_that.selectedDate,_that.selectedSlot,_that.petId,_that.notes,_that.status,_that.errorMessage,_that.urgency,_that.reason,_that.mediaUrl,_that.selectedMedia);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VetClinic? clinic,  VetService? service,  DateTime? selectedDate,  DateTime? selectedSlot,  String? petId,  String? notes,  VetBookingStatus status,  String? errorMessage,  String urgency,  String? reason,  String? mediaUrl,  XFile? selectedMedia)?  $default,) {final _that = this;
switch (_that) {
case _VetBookingState() when $default != null:
return $default(_that.clinic,_that.service,_that.selectedDate,_that.selectedSlot,_that.petId,_that.notes,_that.status,_that.errorMessage,_that.urgency,_that.reason,_that.mediaUrl,_that.selectedMedia);case _:
  return null;

}
}

}

/// @nodoc


class _VetBookingState extends VetBookingState {
  const _VetBookingState({this.clinic, this.service, this.selectedDate, this.selectedSlot, this.petId, this.notes, this.status = VetBookingStatus.idle, this.errorMessage, this.urgency = 'Routine', this.reason, this.mediaUrl, this.selectedMedia}): super._();
  

@override final  VetClinic? clinic;
@override final  VetService? service;
@override final  DateTime? selectedDate;
@override final  DateTime? selectedSlot;
@override final  String? petId;
@override final  String? notes;
@override@JsonKey() final  VetBookingStatus status;
@override final  String? errorMessage;
@override@JsonKey() final  String urgency;
@override final  String? reason;
@override final  String? mediaUrl;
@override final  XFile? selectedMedia;

/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VetBookingStateCopyWith<_VetBookingState> get copyWith => __$VetBookingStateCopyWithImpl<_VetBookingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VetBookingState&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.service, service) || other.service == service)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedSlot, selectedSlot) || other.selectedSlot == selectedSlot)&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.selectedMedia, selectedMedia) || other.selectedMedia == selectedMedia));
}


@override
int get hashCode => Object.hash(runtimeType,clinic,service,selectedDate,selectedSlot,petId,notes,status,errorMessage,urgency,reason,mediaUrl,selectedMedia);

@override
String toString() {
  return 'VetBookingState(clinic: $clinic, service: $service, selectedDate: $selectedDate, selectedSlot: $selectedSlot, petId: $petId, notes: $notes, status: $status, errorMessage: $errorMessage, urgency: $urgency, reason: $reason, mediaUrl: $mediaUrl, selectedMedia: $selectedMedia)';
}


}

/// @nodoc
abstract mixin class _$VetBookingStateCopyWith<$Res> implements $VetBookingStateCopyWith<$Res> {
  factory _$VetBookingStateCopyWith(_VetBookingState value, $Res Function(_VetBookingState) _then) = __$VetBookingStateCopyWithImpl;
@override @useResult
$Res call({
 VetClinic? clinic, VetService? service, DateTime? selectedDate, DateTime? selectedSlot, String? petId, String? notes, VetBookingStatus status, String? errorMessage, String urgency, String? reason, String? mediaUrl, XFile? selectedMedia
});


@override $VetClinicCopyWith<$Res>? get clinic;@override $VetServiceCopyWith<$Res>? get service;

}
/// @nodoc
class __$VetBookingStateCopyWithImpl<$Res>
    implements _$VetBookingStateCopyWith<$Res> {
  __$VetBookingStateCopyWithImpl(this._self, this._then);

  final _VetBookingState _self;
  final $Res Function(_VetBookingState) _then;

/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clinic = freezed,Object? service = freezed,Object? selectedDate = freezed,Object? selectedSlot = freezed,Object? petId = freezed,Object? notes = freezed,Object? status = null,Object? errorMessage = freezed,Object? urgency = null,Object? reason = freezed,Object? mediaUrl = freezed,Object? selectedMedia = freezed,}) {
  return _then(_VetBookingState(
clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as VetClinic?,service: freezed == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as VetService?,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as DateTime?,petId: freezed == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VetBookingStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,selectedMedia: freezed == selectedMedia ? _self.selectedMedia : selectedMedia // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}

/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VetClinicCopyWith<$Res>? get clinic {
    if (_self.clinic == null) {
    return null;
  }

  return $VetClinicCopyWith<$Res>(_self.clinic!, (value) {
    return _then(_self.copyWith(clinic: value));
  });
}/// Create a copy of VetBookingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VetServiceCopyWith<$Res>? get service {
    if (_self.service == null) {
    return null;
  }

  return $VetServiceCopyWith<$Res>(_self.service!, (value) {
    return _then(_self.copyWith(service: value));
  });
}
}

// dart format on
