// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSettings {

 String get userId; bool get notifBosses; bool get notifStreak; bool get notifRaids; bool get notifWeekly; bool get notifLeaderboardNudge; String get quietStart; String get quietEnd; bool get appearOffline; String? get studyContext; bool get demoMode;
/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<UserSettings> get copyWith => _$UserSettingsCopyWithImpl<UserSettings>(this as UserSettings, _$identity);

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettings&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.notifBosses, _this.notifBosses) || other.notifBosses == _this.notifBosses)&&(identical(other.notifStreak, _this.notifStreak) || other.notifStreak == _this.notifStreak)&&(identical(other.notifRaids, _this.notifRaids) || other.notifRaids == _this.notifRaids)&&(identical(other.notifWeekly, _this.notifWeekly) || other.notifWeekly == _this.notifWeekly)&&(identical(other.notifLeaderboardNudge, _this.notifLeaderboardNudge) || other.notifLeaderboardNudge == _this.notifLeaderboardNudge)&&(identical(other.quietStart, _this.quietStart) || other.quietStart == _this.quietStart)&&(identical(other.quietEnd, _this.quietEnd) || other.quietEnd == _this.quietEnd)&&(identical(other.appearOffline, _this.appearOffline) || other.appearOffline == _this.appearOffline)&&(identical(other.studyContext, _this.studyContext) || other.studyContext == _this.studyContext)&&(identical(other.demoMode, _this.demoMode) || other.demoMode == _this.demoMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserSettings;
  return Object.hash(runtimeType,_this.userId,_this.notifBosses,_this.notifStreak,_this.notifRaids,_this.notifWeekly,_this.notifLeaderboardNudge,_this.quietStart,_this.quietEnd,_this.appearOffline,_this.studyContext,_this.demoMode);
}

@override
String toString() {
  final _this = this as UserSettings;
  return 'UserSettings(userId: ${_this.userId}, notifBosses: ${_this.notifBosses}, notifStreak: ${_this.notifStreak}, notifRaids: ${_this.notifRaids}, notifWeekly: ${_this.notifWeekly}, notifLeaderboardNudge: ${_this.notifLeaderboardNudge}, quietStart: ${_this.quietStart}, quietEnd: ${_this.quietEnd}, appearOffline: ${_this.appearOffline}, studyContext: ${_this.studyContext}, demoMode: ${_this.demoMode})';
}


}

/// @nodoc
abstract mixin class $UserSettingsCopyWith<$Res>  {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) _then) = _$UserSettingsCopyWithImpl;
@useResult
$Res call({
 String userId, bool notifBosses, bool notifStreak, bool notifRaids, bool notifWeekly, bool notifLeaderboardNudge, String quietStart, String quietEnd, bool appearOffline, String? studyContext, bool demoMode
});




}
/// @nodoc
class _$UserSettingsCopyWithImpl<$Res>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._self, this._then);

  final UserSettings _self;
  final $Res Function(UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? notifBosses = null,Object? notifStreak = null,Object? notifRaids = null,Object? notifWeekly = null,Object? notifLeaderboardNudge = null,Object? quietStart = null,Object? quietEnd = null,Object? appearOffline = null,Object? studyContext = freezed,Object? demoMode = null,}) {
  return _then(UserSettings(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,notifBosses: null == notifBosses ? _self.notifBosses : notifBosses // ignore: cast_nullable_to_non_nullable
as bool,notifStreak: null == notifStreak ? _self.notifStreak : notifStreak // ignore: cast_nullable_to_non_nullable
as bool,notifRaids: null == notifRaids ? _self.notifRaids : notifRaids // ignore: cast_nullable_to_non_nullable
as bool,notifWeekly: null == notifWeekly ? _self.notifWeekly : notifWeekly // ignore: cast_nullable_to_non_nullable
as bool,notifLeaderboardNudge: null == notifLeaderboardNudge ? _self.notifLeaderboardNudge : notifLeaderboardNudge // ignore: cast_nullable_to_non_nullable
as bool,quietStart: null == quietStart ? _self.quietStart : quietStart // ignore: cast_nullable_to_non_nullable
as String,quietEnd: null == quietEnd ? _self.quietEnd : quietEnd // ignore: cast_nullable_to_non_nullable
as String,appearOffline: null == appearOffline ? _self.appearOffline : appearOffline // ignore: cast_nullable_to_non_nullable
as bool,studyContext: freezed == studyContext ? _self.studyContext : studyContext // ignore: cast_nullable_to_non_nullable
as String?,demoMode: null == demoMode ? _self.demoMode : demoMode // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettings].
extension UserSettingsPatterns on UserSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettings value)  $default,){
final _that = this;
switch (_that) {
case _UserSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettings value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  bool notifBosses,  bool notifStreak,  bool notifRaids,  bool notifWeekly,  bool notifLeaderboardNudge,  String quietStart,  String quietEnd,  bool appearOffline,  String? studyContext,  bool demoMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.userId,_that.notifBosses,_that.notifStreak,_that.notifRaids,_that.notifWeekly,_that.notifLeaderboardNudge,_that.quietStart,_that.quietEnd,_that.appearOffline,_that.studyContext,_that.demoMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  bool notifBosses,  bool notifStreak,  bool notifRaids,  bool notifWeekly,  bool notifLeaderboardNudge,  String quietStart,  String quietEnd,  bool appearOffline,  String? studyContext,  bool demoMode)  $default,) {final _that = this;
switch (_that) {
case _UserSettings():
return $default(_that.userId,_that.notifBosses,_that.notifStreak,_that.notifRaids,_that.notifWeekly,_that.notifLeaderboardNudge,_that.quietStart,_that.quietEnd,_that.appearOffline,_that.studyContext,_that.demoMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  bool notifBosses,  bool notifStreak,  bool notifRaids,  bool notifWeekly,  bool notifLeaderboardNudge,  String quietStart,  String quietEnd,  bool appearOffline,  String? studyContext,  bool demoMode)?  $default,) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.userId,_that.notifBosses,_that.notifStreak,_that.notifRaids,_that.notifWeekly,_that.notifLeaderboardNudge,_that.quietStart,_that.quietEnd,_that.appearOffline,_that.studyContext,_that.demoMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSettings implements UserSettings {
  const _UserSettings({required this.userId, required this.notifBosses, required this.notifStreak, required this.notifRaids, required this.notifWeekly, required this.notifLeaderboardNudge, required this.quietStart, required this.quietEnd, required this.appearOffline, this.studyContext, required this.demoMode});
  factory _UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);

@override final  String userId;
@override final  bool notifBosses;
@override final  bool notifStreak;
@override final  bool notifRaids;
@override final  bool notifWeekly;
@override final  bool notifLeaderboardNudge;
@override final  String quietStart;
@override final  String quietEnd;
@override final  bool appearOffline;
@override final  String? studyContext;
@override final  bool demoMode;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsCopyWith<_UserSettings> get copyWith => __$UserSettingsCopyWithImpl<_UserSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettings&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.notifBosses, notifBosses) || other.notifBosses == notifBosses)&&(identical(other.notifStreak, notifStreak) || other.notifStreak == notifStreak)&&(identical(other.notifRaids, notifRaids) || other.notifRaids == notifRaids)&&(identical(other.notifWeekly, notifWeekly) || other.notifWeekly == notifWeekly)&&(identical(other.notifLeaderboardNudge, notifLeaderboardNudge) || other.notifLeaderboardNudge == notifLeaderboardNudge)&&(identical(other.quietStart, quietStart) || other.quietStart == quietStart)&&(identical(other.quietEnd, quietEnd) || other.quietEnd == quietEnd)&&(identical(other.appearOffline, appearOffline) || other.appearOffline == appearOffline)&&(identical(other.studyContext, studyContext) || other.studyContext == studyContext)&&(identical(other.demoMode, demoMode) || other.demoMode == demoMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,notifBosses,notifStreak,notifRaids,notifWeekly,notifLeaderboardNudge,quietStart,quietEnd,appearOffline,studyContext,demoMode);
}

@override
String toString() {
    return 'UserSettings(userId: $userId, notifBosses: $notifBosses, notifStreak: $notifStreak, notifRaids: $notifRaids, notifWeekly: $notifWeekly, notifLeaderboardNudge: $notifLeaderboardNudge, quietStart: $quietStart, quietEnd: $quietEnd, appearOffline: $appearOffline, studyContext: $studyContext, demoMode: $demoMode)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsCopyWith<$Res> implements $UserSettingsCopyWith<$Res> {
  factory _$UserSettingsCopyWith(_UserSettings value, $Res Function(_UserSettings) _then) = __$UserSettingsCopyWithImpl;
@override @useResult
$Res call({
 String userId, bool notifBosses, bool notifStreak, bool notifRaids, bool notifWeekly, bool notifLeaderboardNudge, String quietStart, String quietEnd, bool appearOffline, String? studyContext, bool demoMode
});




}
/// @nodoc
class __$UserSettingsCopyWithImpl<$Res>
    implements _$UserSettingsCopyWith<$Res> {
  __$UserSettingsCopyWithImpl(this._self, this._then);

  final _UserSettings _self;
  final $Res Function(_UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? notifBosses = null,Object? notifStreak = null,Object? notifRaids = null,Object? notifWeekly = null,Object? notifLeaderboardNudge = null,Object? quietStart = null,Object? quietEnd = null,Object? appearOffline = null,Object? studyContext = freezed,Object? demoMode = null,}) {
  return _then(_UserSettings(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,notifBosses: null == notifBosses ? _self.notifBosses : notifBosses // ignore: cast_nullable_to_non_nullable
as bool,notifStreak: null == notifStreak ? _self.notifStreak : notifStreak // ignore: cast_nullable_to_non_nullable
as bool,notifRaids: null == notifRaids ? _self.notifRaids : notifRaids // ignore: cast_nullable_to_non_nullable
as bool,notifWeekly: null == notifWeekly ? _self.notifWeekly : notifWeekly // ignore: cast_nullable_to_non_nullable
as bool,notifLeaderboardNudge: null == notifLeaderboardNudge ? _self.notifLeaderboardNudge : notifLeaderboardNudge // ignore: cast_nullable_to_non_nullable
as bool,quietStart: null == quietStart ? _self.quietStart : quietStart // ignore: cast_nullable_to_non_nullable
as String,quietEnd: null == quietEnd ? _self.quietEnd : quietEnd // ignore: cast_nullable_to_non_nullable
as String,appearOffline: null == appearOffline ? _self.appearOffline : appearOffline // ignore: cast_nullable_to_non_nullable
as bool,studyContext: freezed == studyContext ? _self.studyContext : studyContext // ignore: cast_nullable_to_non_nullable
as String?,demoMode: null == demoMode ? _self.demoMode : demoMode // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
