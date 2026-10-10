// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelReward {

 int get level; List<Map<String, dynamic>> get rewards;
/// Create a copy of LevelReward
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelRewardCopyWith<LevelReward> get copyWith => _$LevelRewardCopyWithImpl<LevelReward>(this as LevelReward, _$identity);

  /// Serializes this LevelReward to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LevelReward;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelReward&&(identical(other.level, _this.level) || other.level == _this.level)&&const DeepCollectionEquality().equals(other.rewards, _this.rewards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LevelReward;
  return Object.hash(runtimeType,_this.level,const DeepCollectionEquality().hash(_this.rewards));
}

@override
String toString() {
  final _this = this as LevelReward;
  return 'LevelReward(level: ${_this.level}, rewards: ${_this.rewards})';
}


}

/// @nodoc
abstract mixin class $LevelRewardCopyWith<$Res>  {
  factory $LevelRewardCopyWith(LevelReward value, $Res Function(LevelReward) _then) = _$LevelRewardCopyWithImpl;
@useResult
$Res call({
 int level, List<Map<String, dynamic>> rewards
});




}
/// @nodoc
class _$LevelRewardCopyWithImpl<$Res>
    implements $LevelRewardCopyWith<$Res> {
  _$LevelRewardCopyWithImpl(this._self, this._then);

  final LevelReward _self;
  final $Res Function(LevelReward) _then;

/// Create a copy of LevelReward
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = null,Object? rewards = null,}) {
  return _then(LevelReward(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,rewards: null == rewards ? _self.rewards : rewards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelReward].
extension LevelRewardPatterns on LevelReward {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelReward value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelReward() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelReward value)  $default,){
final _that = this;
switch (_that) {
case _LevelReward():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelReward value)?  $default,){
final _that = this;
switch (_that) {
case _LevelReward() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int level,  List<Map<String, dynamic>> rewards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelReward() when $default != null:
return $default(_that.level,_that.rewards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int level,  List<Map<String, dynamic>> rewards)  $default,) {final _that = this;
switch (_that) {
case _LevelReward():
return $default(_that.level,_that.rewards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int level,  List<Map<String, dynamic>> rewards)?  $default,) {final _that = this;
switch (_that) {
case _LevelReward() when $default != null:
return $default(_that.level,_that.rewards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelReward implements LevelReward {
  const _LevelReward({required this.level, required  List<Map<String, dynamic>> rewards}): _rewards = rewards;
  factory _LevelReward.fromJson(Map<String, dynamic> json) => _$LevelRewardFromJson(json);

@override final  int level;
 final  List<Map<String, dynamic>> _rewards;
@override List<Map<String, dynamic>> get rewards {
  if (_rewards is EqualUnmodifiableListView) return _rewards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rewards);
}


/// Create a copy of LevelReward
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelRewardCopyWith<_LevelReward> get copyWith => __$LevelRewardCopyWithImpl<_LevelReward>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelRewardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelReward&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.rewards, _rewards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,level,const DeepCollectionEquality().hash(_rewards));
}

@override
String toString() {
    return 'LevelReward(level: $level, rewards: $rewards)';
}


}

/// @nodoc
abstract mixin class _$LevelRewardCopyWith<$Res> implements $LevelRewardCopyWith<$Res> {
  factory _$LevelRewardCopyWith(_LevelReward value, $Res Function(_LevelReward) _then) = __$LevelRewardCopyWithImpl;
@override @useResult
$Res call({
 int level, List<Map<String, dynamic>> rewards
});




}
/// @nodoc
class __$LevelRewardCopyWithImpl<$Res>
    implements _$LevelRewardCopyWith<$Res> {
  __$LevelRewardCopyWithImpl(this._self, this._then);

  final _LevelReward _self;
  final $Res Function(_LevelReward) _then;

/// Create a copy of LevelReward
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = null,Object? rewards = null,}) {
  return _then(_LevelReward(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,rewards: null == rewards ? _self._rewards : rewards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
