// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get id; String get username; String get friendCode; String get displayName; String get bodyType; int get level; String? get titleId; String get equippedSkinId; String get equippedBackgroundId; String get equippedFrameId; List<String> get pinnedBadges; String? get guildId; bool get hideRadar; bool get showBossNames; DateTime get createdAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.friendCode, _this.friendCode) || other.friendCode == _this.friendCode)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.bodyType, _this.bodyType) || other.bodyType == _this.bodyType)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.titleId, _this.titleId) || other.titleId == _this.titleId)&&(identical(other.equippedSkinId, _this.equippedSkinId) || other.equippedSkinId == _this.equippedSkinId)&&(identical(other.equippedBackgroundId, _this.equippedBackgroundId) || other.equippedBackgroundId == _this.equippedBackgroundId)&&(identical(other.equippedFrameId, _this.equippedFrameId) || other.equippedFrameId == _this.equippedFrameId)&&const DeepCollectionEquality().equals(other.pinnedBadges, _this.pinnedBadges)&&(identical(other.guildId, _this.guildId) || other.guildId == _this.guildId)&&(identical(other.hideRadar, _this.hideRadar) || other.hideRadar == _this.hideRadar)&&(identical(other.showBossNames, _this.showBossNames) || other.showBossNames == _this.showBossNames)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profile;
  return Object.hash(runtimeType,_this.id,_this.username,_this.friendCode,_this.displayName,_this.bodyType,_this.level,_this.titleId,_this.equippedSkinId,_this.equippedBackgroundId,_this.equippedFrameId,const DeepCollectionEquality().hash(_this.pinnedBadges),_this.guildId,_this.hideRadar,_this.showBossNames,_this.createdAt);
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(id: ${_this.id}, username: ${_this.username}, friendCode: ${_this.friendCode}, displayName: ${_this.displayName}, bodyType: ${_this.bodyType}, level: ${_this.level}, titleId: ${_this.titleId}, equippedSkinId: ${_this.equippedSkinId}, equippedBackgroundId: ${_this.equippedBackgroundId}, equippedFrameId: ${_this.equippedFrameId}, pinnedBadges: ${_this.pinnedBadges}, guildId: ${_this.guildId}, hideRadar: ${_this.hideRadar}, showBossNames: ${_this.showBossNames}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String username, String friendCode, String displayName, String bodyType, int level, String? titleId, String equippedSkinId, String equippedBackgroundId, String equippedFrameId, List<String> pinnedBadges, String? guildId, bool hideRadar, bool showBossNames, DateTime createdAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? friendCode = null,Object? displayName = null,Object? bodyType = null,Object? level = null,Object? titleId = freezed,Object? equippedSkinId = null,Object? equippedBackgroundId = null,Object? equippedFrameId = null,Object? pinnedBadges = null,Object? guildId = freezed,Object? hideRadar = null,Object? showBossNames = null,Object? createdAt = null,}) {
  return _then(Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,friendCode: null == friendCode ? _self.friendCode : friendCode // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bodyType: null == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,titleId: freezed == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as String?,equippedSkinId: null == equippedSkinId ? _self.equippedSkinId : equippedSkinId // ignore: cast_nullable_to_non_nullable
as String,equippedBackgroundId: null == equippedBackgroundId ? _self.equippedBackgroundId : equippedBackgroundId // ignore: cast_nullable_to_non_nullable
as String,equippedFrameId: null == equippedFrameId ? _self.equippedFrameId : equippedFrameId // ignore: cast_nullable_to_non_nullable
as String,pinnedBadges: null == pinnedBadges ? _self.pinnedBadges : pinnedBadges // ignore: cast_nullable_to_non_nullable
as List<String>,guildId: freezed == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String?,hideRadar: null == hideRadar ? _self.hideRadar : hideRadar // ignore: cast_nullable_to_non_nullable
as bool,showBossNames: null == showBossNames ? _self.showBossNames : showBossNames // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String friendCode,  String displayName,  String bodyType,  int level,  String? titleId,  String equippedSkinId,  String equippedBackgroundId,  String equippedFrameId,  List<String> pinnedBadges,  String? guildId,  bool hideRadar,  bool showBossNames,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.friendCode,_that.displayName,_that.bodyType,_that.level,_that.titleId,_that.equippedSkinId,_that.equippedBackgroundId,_that.equippedFrameId,_that.pinnedBadges,_that.guildId,_that.hideRadar,_that.showBossNames,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String friendCode,  String displayName,  String bodyType,  int level,  String? titleId,  String equippedSkinId,  String equippedBackgroundId,  String equippedFrameId,  List<String> pinnedBadges,  String? guildId,  bool hideRadar,  bool showBossNames,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.username,_that.friendCode,_that.displayName,_that.bodyType,_that.level,_that.titleId,_that.equippedSkinId,_that.equippedBackgroundId,_that.equippedFrameId,_that.pinnedBadges,_that.guildId,_that.hideRadar,_that.showBossNames,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String friendCode,  String displayName,  String bodyType,  int level,  String? titleId,  String equippedSkinId,  String equippedBackgroundId,  String equippedFrameId,  List<String> pinnedBadges,  String? guildId,  bool hideRadar,  bool showBossNames,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.friendCode,_that.displayName,_that.bodyType,_that.level,_that.titleId,_that.equippedSkinId,_that.equippedBackgroundId,_that.equippedFrameId,_that.pinnedBadges,_that.guildId,_that.hideRadar,_that.showBossNames,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile implements Profile {
  const _Profile({required this.id, required this.username, required this.friendCode, required this.displayName, required this.bodyType, required this.level, this.titleId, required this.equippedSkinId, required this.equippedBackgroundId, required this.equippedFrameId, required  List<String> pinnedBadges, this.guildId, required this.hideRadar, required this.showBossNames, required this.createdAt}): _pinnedBadges = pinnedBadges;
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override final  String username;
@override final  String friendCode;
@override final  String displayName;
@override final  String bodyType;
@override final  int level;
@override final  String? titleId;
@override final  String equippedSkinId;
@override final  String equippedBackgroundId;
@override final  String equippedFrameId;
 final  List<String> _pinnedBadges;
@override List<String> get pinnedBadges {
  if (_pinnedBadges is EqualUnmodifiableListView) return _pinnedBadges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pinnedBadges);
}

@override final  String? guildId;
@override final  bool hideRadar;
@override final  bool showBossNames;
@override final  DateTime createdAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.friendCode, friendCode) || other.friendCode == friendCode)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bodyType, bodyType) || other.bodyType == bodyType)&&(identical(other.level, level) || other.level == level)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.equippedSkinId, equippedSkinId) || other.equippedSkinId == equippedSkinId)&&(identical(other.equippedBackgroundId, equippedBackgroundId) || other.equippedBackgroundId == equippedBackgroundId)&&(identical(other.equippedFrameId, equippedFrameId) || other.equippedFrameId == equippedFrameId)&&const DeepCollectionEquality().equals(other.pinnedBadges, _pinnedBadges)&&(identical(other.guildId, guildId) || other.guildId == guildId)&&(identical(other.hideRadar, hideRadar) || other.hideRadar == hideRadar)&&(identical(other.showBossNames, showBossNames) || other.showBossNames == showBossNames)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,username,friendCode,displayName,bodyType,level,titleId,equippedSkinId,equippedBackgroundId,equippedFrameId,const DeepCollectionEquality().hash(_pinnedBadges),guildId,hideRadar,showBossNames,createdAt);
}

@override
String toString() {
    return 'Profile(id: $id, username: $username, friendCode: $friendCode, displayName: $displayName, bodyType: $bodyType, level: $level, titleId: $titleId, equippedSkinId: $equippedSkinId, equippedBackgroundId: $equippedBackgroundId, equippedFrameId: $equippedFrameId, pinnedBadges: $pinnedBadges, guildId: $guildId, hideRadar: $hideRadar, showBossNames: $showBossNames, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String friendCode, String displayName, String bodyType, int level, String? titleId, String equippedSkinId, String equippedBackgroundId, String equippedFrameId, List<String> pinnedBadges, String? guildId, bool hideRadar, bool showBossNames, DateTime createdAt
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? friendCode = null,Object? displayName = null,Object? bodyType = null,Object? level = null,Object? titleId = freezed,Object? equippedSkinId = null,Object? equippedBackgroundId = null,Object? equippedFrameId = null,Object? pinnedBadges = null,Object? guildId = freezed,Object? hideRadar = null,Object? showBossNames = null,Object? createdAt = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,friendCode: null == friendCode ? _self.friendCode : friendCode // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bodyType: null == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,titleId: freezed == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as String?,equippedSkinId: null == equippedSkinId ? _self.equippedSkinId : equippedSkinId // ignore: cast_nullable_to_non_nullable
as String,equippedBackgroundId: null == equippedBackgroundId ? _self.equippedBackgroundId : equippedBackgroundId // ignore: cast_nullable_to_non_nullable
as String,equippedFrameId: null == equippedFrameId ? _self.equippedFrameId : equippedFrameId // ignore: cast_nullable_to_non_nullable
as String,pinnedBadges: null == pinnedBadges ? _self._pinnedBadges : pinnedBadges // ignore: cast_nullable_to_non_nullable
as List<String>,guildId: freezed == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String?,hideRadar: null == hideRadar ? _self.hideRadar : hideRadar // ignore: cast_nullable_to_non_nullable
as bool,showBossNames: null == showBossNames ? _self.showBossNames : showBossNames // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
