// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyScore {

 String get weekId; String get userId; int get rawXp; DateTime get updatedAt;
/// Create a copy of WeeklyScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyScoreCopyWith<WeeklyScore> get copyWith => _$WeeklyScoreCopyWithImpl<WeeklyScore>(this as WeeklyScore, _$identity);

  /// Serializes this WeeklyScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WeeklyScore;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyScore&&(identical(other.weekId, _this.weekId) || other.weekId == _this.weekId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.rawXp, _this.rawXp) || other.rawXp == _this.rawXp)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeeklyScore;
  return Object.hash(runtimeType,_this.weekId,_this.userId,_this.rawXp,_this.updatedAt);
}

@override
String toString() {
  final _this = this as WeeklyScore;
  return 'WeeklyScore(weekId: ${_this.weekId}, userId: ${_this.userId}, rawXp: ${_this.rawXp}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $WeeklyScoreCopyWith<$Res>  {
  factory $WeeklyScoreCopyWith(WeeklyScore value, $Res Function(WeeklyScore) _then) = _$WeeklyScoreCopyWithImpl;
@useResult
$Res call({
 String weekId, String userId, int rawXp, DateTime updatedAt
});




}
/// @nodoc
class _$WeeklyScoreCopyWithImpl<$Res>
    implements $WeeklyScoreCopyWith<$Res> {
  _$WeeklyScoreCopyWithImpl(this._self, this._then);

  final WeeklyScore _self;
  final $Res Function(WeeklyScore) _then;

/// Create a copy of WeeklyScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekId = null,Object? userId = null,Object? rawXp = null,Object? updatedAt = null,}) {
  return _then(WeeklyScore(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rawXp: null == rawXp ? _self.rawXp : rawXp // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyScore].
extension WeeklyScorePatterns on WeeklyScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyScore value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyScore value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekId,  String userId,  int rawXp,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyScore() when $default != null:
return $default(_that.weekId,_that.userId,_that.rawXp,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekId,  String userId,  int rawXp,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklyScore():
return $default(_that.weekId,_that.userId,_that.rawXp,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekId,  String userId,  int rawXp,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyScore() when $default != null:
return $default(_that.weekId,_that.userId,_that.rawXp,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyScore implements WeeklyScore {
  const _WeeklyScore({required this.weekId, required this.userId, required this.rawXp, required this.updatedAt});
  factory _WeeklyScore.fromJson(Map<String, dynamic> json) => _$WeeklyScoreFromJson(json);

@override final  String weekId;
@override final  String userId;
@override final  int rawXp;
@override final  DateTime updatedAt;

/// Create a copy of WeeklyScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyScoreCopyWith<_WeeklyScore> get copyWith => __$WeeklyScoreCopyWithImpl<_WeeklyScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyScoreToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyScore&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rawXp, rawXp) || other.rawXp == rawXp)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,weekId,userId,rawXp,updatedAt);
}

@override
String toString() {
    return 'WeeklyScore(weekId: $weekId, userId: $userId, rawXp: $rawXp, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyScoreCopyWith<$Res> implements $WeeklyScoreCopyWith<$Res> {
  factory _$WeeklyScoreCopyWith(_WeeklyScore value, $Res Function(_WeeklyScore) _then) = __$WeeklyScoreCopyWithImpl;
@override @useResult
$Res call({
 String weekId, String userId, int rawXp, DateTime updatedAt
});




}
/// @nodoc
class __$WeeklyScoreCopyWithImpl<$Res>
    implements _$WeeklyScoreCopyWith<$Res> {
  __$WeeklyScoreCopyWithImpl(this._self, this._then);

  final _WeeklyScore _self;
  final $Res Function(_WeeklyScore) _then;

/// Create a copy of WeeklyScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekId = null,Object? userId = null,Object? rawXp = null,Object? updatedAt = null,}) {
  return _then(_WeeklyScore(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rawXp: null == rawXp ? _self.rawXp : rawXp // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
