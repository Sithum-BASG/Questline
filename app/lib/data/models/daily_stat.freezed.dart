// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_stat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyStat {

 String get userId; DateTime get day; int get xpIntellect; int get xpVitality; int get xpCraft; int get xpCharisma; int get rawXp; int get focusMinutes; int get sessionsStarted; bool get metMinimum; bool get restDay; bool get paused;
/// Create a copy of DailyStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyStatCopyWith<DailyStat> get copyWith => _$DailyStatCopyWithImpl<DailyStat>(this as DailyStat, _$identity);

  /// Serializes this DailyStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DailyStat;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyStat&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.xpIntellect, _this.xpIntellect) || other.xpIntellect == _this.xpIntellect)&&(identical(other.xpVitality, _this.xpVitality) || other.xpVitality == _this.xpVitality)&&(identical(other.xpCraft, _this.xpCraft) || other.xpCraft == _this.xpCraft)&&(identical(other.xpCharisma, _this.xpCharisma) || other.xpCharisma == _this.xpCharisma)&&(identical(other.rawXp, _this.rawXp) || other.rawXp == _this.rawXp)&&(identical(other.focusMinutes, _this.focusMinutes) || other.focusMinutes == _this.focusMinutes)&&(identical(other.sessionsStarted, _this.sessionsStarted) || other.sessionsStarted == _this.sessionsStarted)&&(identical(other.metMinimum, _this.metMinimum) || other.metMinimum == _this.metMinimum)&&(identical(other.restDay, _this.restDay) || other.restDay == _this.restDay)&&(identical(other.paused, _this.paused) || other.paused == _this.paused));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DailyStat;
  return Object.hash(runtimeType,_this.userId,_this.day,_this.xpIntellect,_this.xpVitality,_this.xpCraft,_this.xpCharisma,_this.rawXp,_this.focusMinutes,_this.sessionsStarted,_this.metMinimum,_this.restDay,_this.paused);
}

@override
String toString() {
  final _this = this as DailyStat;
  return 'DailyStat(userId: ${_this.userId}, day: ${_this.day}, xpIntellect: ${_this.xpIntellect}, xpVitality: ${_this.xpVitality}, xpCraft: ${_this.xpCraft}, xpCharisma: ${_this.xpCharisma}, rawXp: ${_this.rawXp}, focusMinutes: ${_this.focusMinutes}, sessionsStarted: ${_this.sessionsStarted}, metMinimum: ${_this.metMinimum}, restDay: ${_this.restDay}, paused: ${_this.paused})';
}


}

/// @nodoc
abstract mixin class $DailyStatCopyWith<$Res>  {
  factory $DailyStatCopyWith(DailyStat value, $Res Function(DailyStat) _then) = _$DailyStatCopyWithImpl;
@useResult
$Res call({
 String userId, DateTime day, int xpIntellect, int xpVitality, int xpCraft, int xpCharisma, int rawXp, int focusMinutes, int sessionsStarted, bool metMinimum, bool restDay, bool paused
});




}
/// @nodoc
class _$DailyStatCopyWithImpl<$Res>
    implements $DailyStatCopyWith<$Res> {
  _$DailyStatCopyWithImpl(this._self, this._then);

  final DailyStat _self;
  final $Res Function(DailyStat) _then;

/// Create a copy of DailyStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? day = null,Object? xpIntellect = null,Object? xpVitality = null,Object? xpCraft = null,Object? xpCharisma = null,Object? rawXp = null,Object? focusMinutes = null,Object? sessionsStarted = null,Object? metMinimum = null,Object? restDay = null,Object? paused = null,}) {
  return _then(DailyStat(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,xpIntellect: null == xpIntellect ? _self.xpIntellect : xpIntellect // ignore: cast_nullable_to_non_nullable
as int,xpVitality: null == xpVitality ? _self.xpVitality : xpVitality // ignore: cast_nullable_to_non_nullable
as int,xpCraft: null == xpCraft ? _self.xpCraft : xpCraft // ignore: cast_nullable_to_non_nullable
as int,xpCharisma: null == xpCharisma ? _self.xpCharisma : xpCharisma // ignore: cast_nullable_to_non_nullable
as int,rawXp: null == rawXp ? _self.rawXp : rawXp // ignore: cast_nullable_to_non_nullable
as int,focusMinutes: null == focusMinutes ? _self.focusMinutes : focusMinutes // ignore: cast_nullable_to_non_nullable
as int,sessionsStarted: null == sessionsStarted ? _self.sessionsStarted : sessionsStarted // ignore: cast_nullable_to_non_nullable
as int,metMinimum: null == metMinimum ? _self.metMinimum : metMinimum // ignore: cast_nullable_to_non_nullable
as bool,restDay: null == restDay ? _self.restDay : restDay // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyStat].
extension DailyStatPatterns on DailyStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyStat value)  $default,){
final _that = this;
switch (_that) {
case _DailyStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyStat value)?  $default,){
final _that = this;
switch (_that) {
case _DailyStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  DateTime day,  int xpIntellect,  int xpVitality,  int xpCraft,  int xpCharisma,  int rawXp,  int focusMinutes,  int sessionsStarted,  bool metMinimum,  bool restDay,  bool paused)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyStat() when $default != null:
return $default(_that.userId,_that.day,_that.xpIntellect,_that.xpVitality,_that.xpCraft,_that.xpCharisma,_that.rawXp,_that.focusMinutes,_that.sessionsStarted,_that.metMinimum,_that.restDay,_that.paused);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  DateTime day,  int xpIntellect,  int xpVitality,  int xpCraft,  int xpCharisma,  int rawXp,  int focusMinutes,  int sessionsStarted,  bool metMinimum,  bool restDay,  bool paused)  $default,) {final _that = this;
switch (_that) {
case _DailyStat():
return $default(_that.userId,_that.day,_that.xpIntellect,_that.xpVitality,_that.xpCraft,_that.xpCharisma,_that.rawXp,_that.focusMinutes,_that.sessionsStarted,_that.metMinimum,_that.restDay,_that.paused);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  DateTime day,  int xpIntellect,  int xpVitality,  int xpCraft,  int xpCharisma,  int rawXp,  int focusMinutes,  int sessionsStarted,  bool metMinimum,  bool restDay,  bool paused)?  $default,) {final _that = this;
switch (_that) {
case _DailyStat() when $default != null:
return $default(_that.userId,_that.day,_that.xpIntellect,_that.xpVitality,_that.xpCraft,_that.xpCharisma,_that.rawXp,_that.focusMinutes,_that.sessionsStarted,_that.metMinimum,_that.restDay,_that.paused);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyStat implements DailyStat {
  const _DailyStat({required this.userId, required this.day, required this.xpIntellect, required this.xpVitality, required this.xpCraft, required this.xpCharisma, required this.rawXp, required this.focusMinutes, required this.sessionsStarted, required this.metMinimum, required this.restDay, required this.paused});
  factory _DailyStat.fromJson(Map<String, dynamic> json) => _$DailyStatFromJson(json);

@override final  String userId;
@override final  DateTime day;
@override final  int xpIntellect;
@override final  int xpVitality;
@override final  int xpCraft;
@override final  int xpCharisma;
@override final  int rawXp;
@override final  int focusMinutes;
@override final  int sessionsStarted;
@override final  bool metMinimum;
@override final  bool restDay;
@override final  bool paused;

/// Create a copy of DailyStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyStatCopyWith<_DailyStat> get copyWith => __$DailyStatCopyWithImpl<_DailyStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyStatToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyStat&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.day, day) || other.day == day)&&(identical(other.xpIntellect, xpIntellect) || other.xpIntellect == xpIntellect)&&(identical(other.xpVitality, xpVitality) || other.xpVitality == xpVitality)&&(identical(other.xpCraft, xpCraft) || other.xpCraft == xpCraft)&&(identical(other.xpCharisma, xpCharisma) || other.xpCharisma == xpCharisma)&&(identical(other.rawXp, rawXp) || other.rawXp == rawXp)&&(identical(other.focusMinutes, focusMinutes) || other.focusMinutes == focusMinutes)&&(identical(other.sessionsStarted, sessionsStarted) || other.sessionsStarted == sessionsStarted)&&(identical(other.metMinimum, metMinimum) || other.metMinimum == metMinimum)&&(identical(other.restDay, restDay) || other.restDay == restDay)&&(identical(other.paused, paused) || other.paused == paused));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,day,xpIntellect,xpVitality,xpCraft,xpCharisma,rawXp,focusMinutes,sessionsStarted,metMinimum,restDay,paused);
}

@override
String toString() {
    return 'DailyStat(userId: $userId, day: $day, xpIntellect: $xpIntellect, xpVitality: $xpVitality, xpCraft: $xpCraft, xpCharisma: $xpCharisma, rawXp: $rawXp, focusMinutes: $focusMinutes, sessionsStarted: $sessionsStarted, metMinimum: $metMinimum, restDay: $restDay, paused: $paused)';
}


}

/// @nodoc
abstract mixin class _$DailyStatCopyWith<$Res> implements $DailyStatCopyWith<$Res> {
  factory _$DailyStatCopyWith(_DailyStat value, $Res Function(_DailyStat) _then) = __$DailyStatCopyWithImpl;
@override @useResult
$Res call({
 String userId, DateTime day, int xpIntellect, int xpVitality, int xpCraft, int xpCharisma, int rawXp, int focusMinutes, int sessionsStarted, bool metMinimum, bool restDay, bool paused
});




}
/// @nodoc
class __$DailyStatCopyWithImpl<$Res>
    implements _$DailyStatCopyWith<$Res> {
  __$DailyStatCopyWithImpl(this._self, this._then);

  final _DailyStat _self;
  final $Res Function(_DailyStat) _then;

/// Create a copy of DailyStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? day = null,Object? xpIntellect = null,Object? xpVitality = null,Object? xpCraft = null,Object? xpCharisma = null,Object? rawXp = null,Object? focusMinutes = null,Object? sessionsStarted = null,Object? metMinimum = null,Object? restDay = null,Object? paused = null,}) {
  return _then(_DailyStat(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,xpIntellect: null == xpIntellect ? _self.xpIntellect : xpIntellect // ignore: cast_nullable_to_non_nullable
as int,xpVitality: null == xpVitality ? _self.xpVitality : xpVitality // ignore: cast_nullable_to_non_nullable
as int,xpCraft: null == xpCraft ? _self.xpCraft : xpCraft // ignore: cast_nullable_to_non_nullable
as int,xpCharisma: null == xpCharisma ? _self.xpCharisma : xpCharisma // ignore: cast_nullable_to_non_nullable
as int,rawXp: null == rawXp ? _self.rawXp : rawXp // ignore: cast_nullable_to_non_nullable
as int,focusMinutes: null == focusMinutes ? _self.focusMinutes : focusMinutes // ignore: cast_nullable_to_non_nullable
as int,sessionsStarted: null == sessionsStarted ? _self.sessionsStarted : sessionsStarted // ignore: cast_nullable_to_non_nullable
as int,metMinimum: null == metMinimum ? _self.metMinimum : metMinimum // ignore: cast_nullable_to_non_nullable
as bool,restDay: null == restDay ? _self.restDay : restDay // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
