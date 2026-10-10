// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raid_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RaidMember {

 String get raidId; String get userId; String get displayName; String? get skinId; String? get frameId; String? get bodyType; String? get titleId; DateTime get joinedAt; bool get leftRaid; bool get metFairShare; bool get isMvp;
/// Create a copy of RaidMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaidMemberCopyWith<RaidMember> get copyWith => _$RaidMemberCopyWithImpl<RaidMember>(this as RaidMember, _$identity);

  /// Serializes this RaidMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RaidMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaidMember&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.skinId, _this.skinId) || other.skinId == _this.skinId)&&(identical(other.frameId, _this.frameId) || other.frameId == _this.frameId)&&(identical(other.bodyType, _this.bodyType) || other.bodyType == _this.bodyType)&&(identical(other.titleId, _this.titleId) || other.titleId == _this.titleId)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.leftRaid, _this.leftRaid) || other.leftRaid == _this.leftRaid)&&(identical(other.metFairShare, _this.metFairShare) || other.metFairShare == _this.metFairShare)&&(identical(other.isMvp, _this.isMvp) || other.isMvp == _this.isMvp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RaidMember;
  return Object.hash(runtimeType,_this.raidId,_this.userId,_this.displayName,_this.skinId,_this.frameId,_this.bodyType,_this.titleId,_this.joinedAt,_this.leftRaid,_this.metFairShare,_this.isMvp);
}

@override
String toString() {
  final _this = this as RaidMember;
  return 'RaidMember(raidId: ${_this.raidId}, userId: ${_this.userId}, displayName: ${_this.displayName}, skinId: ${_this.skinId}, frameId: ${_this.frameId}, bodyType: ${_this.bodyType}, titleId: ${_this.titleId}, joinedAt: ${_this.joinedAt}, leftRaid: ${_this.leftRaid}, metFairShare: ${_this.metFairShare}, isMvp: ${_this.isMvp})';
}


}

/// @nodoc
abstract mixin class $RaidMemberCopyWith<$Res>  {
  factory $RaidMemberCopyWith(RaidMember value, $Res Function(RaidMember) _then) = _$RaidMemberCopyWithImpl;
@useResult
$Res call({
 String raidId, String userId, String displayName, String? skinId, String? frameId, String? bodyType, String? titleId, DateTime joinedAt, bool leftRaid, bool metFairShare, bool isMvp
});




}
/// @nodoc
class _$RaidMemberCopyWithImpl<$Res>
    implements $RaidMemberCopyWith<$Res> {
  _$RaidMemberCopyWithImpl(this._self, this._then);

  final RaidMember _self;
  final $Res Function(RaidMember) _then;

/// Create a copy of RaidMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? raidId = null,Object? userId = null,Object? displayName = null,Object? skinId = freezed,Object? frameId = freezed,Object? bodyType = freezed,Object? titleId = freezed,Object? joinedAt = null,Object? leftRaid = null,Object? metFairShare = null,Object? isMvp = null,}) {
  return _then(RaidMember(
raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,skinId: freezed == skinId ? _self.skinId : skinId // ignore: cast_nullable_to_non_nullable
as String?,frameId: freezed == frameId ? _self.frameId : frameId // ignore: cast_nullable_to_non_nullable
as String?,bodyType: freezed == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String?,titleId: freezed == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftRaid: null == leftRaid ? _self.leftRaid : leftRaid // ignore: cast_nullable_to_non_nullable
as bool,metFairShare: null == metFairShare ? _self.metFairShare : metFairShare // ignore: cast_nullable_to_non_nullable
as bool,isMvp: null == isMvp ? _self.isMvp : isMvp // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RaidMember].
extension RaidMemberPatterns on RaidMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaidMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaidMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaidMember value)  $default,){
final _that = this;
switch (_that) {
case _RaidMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaidMember value)?  $default,){
final _that = this;
switch (_that) {
case _RaidMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String raidId,  String userId,  String displayName,  String? skinId,  String? frameId,  String? bodyType,  String? titleId,  DateTime joinedAt,  bool leftRaid,  bool metFairShare,  bool isMvp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaidMember() when $default != null:
return $default(_that.raidId,_that.userId,_that.displayName,_that.skinId,_that.frameId,_that.bodyType,_that.titleId,_that.joinedAt,_that.leftRaid,_that.metFairShare,_that.isMvp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String raidId,  String userId,  String displayName,  String? skinId,  String? frameId,  String? bodyType,  String? titleId,  DateTime joinedAt,  bool leftRaid,  bool metFairShare,  bool isMvp)  $default,) {final _that = this;
switch (_that) {
case _RaidMember():
return $default(_that.raidId,_that.userId,_that.displayName,_that.skinId,_that.frameId,_that.bodyType,_that.titleId,_that.joinedAt,_that.leftRaid,_that.metFairShare,_that.isMvp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String raidId,  String userId,  String displayName,  String? skinId,  String? frameId,  String? bodyType,  String? titleId,  DateTime joinedAt,  bool leftRaid,  bool metFairShare,  bool isMvp)?  $default,) {final _that = this;
switch (_that) {
case _RaidMember() when $default != null:
return $default(_that.raidId,_that.userId,_that.displayName,_that.skinId,_that.frameId,_that.bodyType,_that.titleId,_that.joinedAt,_that.leftRaid,_that.metFairShare,_that.isMvp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaidMember implements RaidMember {
  const _RaidMember({required this.raidId, required this.userId, required this.displayName, this.skinId, this.frameId, this.bodyType, this.titleId, required this.joinedAt, required this.leftRaid, required this.metFairShare, required this.isMvp});
  factory _RaidMember.fromJson(Map<String, dynamic> json) => _$RaidMemberFromJson(json);

@override final  String raidId;
@override final  String userId;
@override final  String displayName;
@override final  String? skinId;
@override final  String? frameId;
@override final  String? bodyType;
@override final  String? titleId;
@override final  DateTime joinedAt;
@override final  bool leftRaid;
@override final  bool metFairShare;
@override final  bool isMvp;

/// Create a copy of RaidMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaidMemberCopyWith<_RaidMember> get copyWith => __$RaidMemberCopyWithImpl<_RaidMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaidMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaidMember&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.skinId, skinId) || other.skinId == skinId)&&(identical(other.frameId, frameId) || other.frameId == frameId)&&(identical(other.bodyType, bodyType) || other.bodyType == bodyType)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftRaid, leftRaid) || other.leftRaid == leftRaid)&&(identical(other.metFairShare, metFairShare) || other.metFairShare == metFairShare)&&(identical(other.isMvp, isMvp) || other.isMvp == isMvp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,raidId,userId,displayName,skinId,frameId,bodyType,titleId,joinedAt,leftRaid,metFairShare,isMvp);
}

@override
String toString() {
    return 'RaidMember(raidId: $raidId, userId: $userId, displayName: $displayName, skinId: $skinId, frameId: $frameId, bodyType: $bodyType, titleId: $titleId, joinedAt: $joinedAt, leftRaid: $leftRaid, metFairShare: $metFairShare, isMvp: $isMvp)';
}


}

/// @nodoc
abstract mixin class _$RaidMemberCopyWith<$Res> implements $RaidMemberCopyWith<$Res> {
  factory _$RaidMemberCopyWith(_RaidMember value, $Res Function(_RaidMember) _then) = __$RaidMemberCopyWithImpl;
@override @useResult
$Res call({
 String raidId, String userId, String displayName, String? skinId, String? frameId, String? bodyType, String? titleId, DateTime joinedAt, bool leftRaid, bool metFairShare, bool isMvp
});




}
/// @nodoc
class __$RaidMemberCopyWithImpl<$Res>
    implements _$RaidMemberCopyWith<$Res> {
  __$RaidMemberCopyWithImpl(this._self, this._then);

  final _RaidMember _self;
  final $Res Function(_RaidMember) _then;

/// Create a copy of RaidMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? raidId = null,Object? userId = null,Object? displayName = null,Object? skinId = freezed,Object? frameId = freezed,Object? bodyType = freezed,Object? titleId = freezed,Object? joinedAt = null,Object? leftRaid = null,Object? metFairShare = null,Object? isMvp = null,}) {
  return _then(_RaidMember(
raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,skinId: freezed == skinId ? _self.skinId : skinId // ignore: cast_nullable_to_non_nullable
as String?,frameId: freezed == frameId ? _self.frameId : frameId // ignore: cast_nullable_to_non_nullable
as String?,bodyType: freezed == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String?,titleId: freezed == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftRaid: null == leftRaid ? _self.leftRaid : leftRaid // ignore: cast_nullable_to_non_nullable
as bool,metFairShare: null == metFairShare ? _self.metFairShare : metFairShare // ignore: cast_nullable_to_non_nullable
as bool,isMvp: null == isMvp ? _self.isMvp : isMvp // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
