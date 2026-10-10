// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FriendSummary {

 String get userId; List<dynamic> get equippedGear; int get weeklyRawXp; Map<String, dynamic>? get radar30; Map<String, dynamic>? get radar7; DateTime get updatedAt;
/// Create a copy of FriendSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendSummaryCopyWith<FriendSummary> get copyWith => _$FriendSummaryCopyWithImpl<FriendSummary>(this as FriendSummary, _$identity);

  /// Serializes this FriendSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FriendSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendSummary&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&const DeepCollectionEquality().equals(other.equippedGear, _this.equippedGear)&&(identical(other.weeklyRawXp, _this.weeklyRawXp) || other.weeklyRawXp == _this.weeklyRawXp)&&const DeepCollectionEquality().equals(other.radar30, _this.radar30)&&const DeepCollectionEquality().equals(other.radar7, _this.radar7)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FriendSummary;
  return Object.hash(runtimeType,_this.userId,const DeepCollectionEquality().hash(_this.equippedGear),_this.weeklyRawXp,const DeepCollectionEquality().hash(_this.radar30),const DeepCollectionEquality().hash(_this.radar7),_this.updatedAt);
}

@override
String toString() {
  final _this = this as FriendSummary;
  return 'FriendSummary(userId: ${_this.userId}, equippedGear: ${_this.equippedGear}, weeklyRawXp: ${_this.weeklyRawXp}, radar30: ${_this.radar30}, radar7: ${_this.radar7}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $FriendSummaryCopyWith<$Res>  {
  factory $FriendSummaryCopyWith(FriendSummary value, $Res Function(FriendSummary) _then) = _$FriendSummaryCopyWithImpl;
@useResult
$Res call({
 String userId, List<dynamic> equippedGear, int weeklyRawXp, Map<String, dynamic>? radar30, Map<String, dynamic>? radar7, DateTime updatedAt
});




}
/// @nodoc
class _$FriendSummaryCopyWithImpl<$Res>
    implements $FriendSummaryCopyWith<$Res> {
  _$FriendSummaryCopyWithImpl(this._self, this._then);

  final FriendSummary _self;
  final $Res Function(FriendSummary) _then;

/// Create a copy of FriendSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? equippedGear = null,Object? weeklyRawXp = null,Object? radar30 = freezed,Object? radar7 = freezed,Object? updatedAt = null,}) {
  return _then(FriendSummary(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,equippedGear: null == equippedGear ? _self.equippedGear : equippedGear // ignore: cast_nullable_to_non_nullable
as List<dynamic>,weeklyRawXp: null == weeklyRawXp ? _self.weeklyRawXp : weeklyRawXp // ignore: cast_nullable_to_non_nullable
as int,radar30: freezed == radar30 ? _self.radar30 : radar30 // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,radar7: freezed == radar7 ? _self.radar7 : radar7 // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FriendSummary].
extension FriendSummaryPatterns on FriendSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendSummary value)  $default,){
final _that = this;
switch (_that) {
case _FriendSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendSummary value)?  $default,){
final _that = this;
switch (_that) {
case _FriendSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  List<dynamic> equippedGear,  int weeklyRawXp,  Map<String, dynamic>? radar30,  Map<String, dynamic>? radar7,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendSummary() when $default != null:
return $default(_that.userId,_that.equippedGear,_that.weeklyRawXp,_that.radar30,_that.radar7,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  List<dynamic> equippedGear,  int weeklyRawXp,  Map<String, dynamic>? radar30,  Map<String, dynamic>? radar7,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FriendSummary():
return $default(_that.userId,_that.equippedGear,_that.weeklyRawXp,_that.radar30,_that.radar7,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  List<dynamic> equippedGear,  int weeklyRawXp,  Map<String, dynamic>? radar30,  Map<String, dynamic>? radar7,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FriendSummary() when $default != null:
return $default(_that.userId,_that.equippedGear,_that.weeklyRawXp,_that.radar30,_that.radar7,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FriendSummary implements FriendSummary {
  const _FriendSummary({required this.userId, required  List<dynamic> equippedGear, required this.weeklyRawXp,  Map<String, dynamic>? radar30,  Map<String, dynamic>? radar7, required this.updatedAt}): _equippedGear = equippedGear,_radar30 = radar30,_radar7 = radar7;
  factory _FriendSummary.fromJson(Map<String, dynamic> json) => _$FriendSummaryFromJson(json);

@override final  String userId;
 final  List<dynamic> _equippedGear;
@override List<dynamic> get equippedGear {
  if (_equippedGear is EqualUnmodifiableListView) return _equippedGear;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equippedGear);
}

@override final  int weeklyRawXp;
 final  Map<String, dynamic>? _radar30;
@override Map<String, dynamic>? get radar30 {
  final value = _radar30;
  if (value == null) return null;
  if (_radar30 is EqualUnmodifiableMapView) return _radar30;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _radar7;
@override Map<String, dynamic>? get radar7 {
  final value = _radar7;
  if (value == null) return null;
  if (_radar7 is EqualUnmodifiableMapView) return _radar7;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime updatedAt;

/// Create a copy of FriendSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendSummaryCopyWith<_FriendSummary> get copyWith => __$FriendSummaryCopyWithImpl<_FriendSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendSummary&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.equippedGear, _equippedGear)&&(identical(other.weeklyRawXp, weeklyRawXp) || other.weeklyRawXp == weeklyRawXp)&&const DeepCollectionEquality().equals(other.radar30, _radar30)&&const DeepCollectionEquality().equals(other.radar7, _radar7)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,const DeepCollectionEquality().hash(_equippedGear),weeklyRawXp,const DeepCollectionEquality().hash(_radar30),const DeepCollectionEquality().hash(_radar7),updatedAt);
}

@override
String toString() {
    return 'FriendSummary(userId: $userId, equippedGear: $equippedGear, weeklyRawXp: $weeklyRawXp, radar30: $radar30, radar7: $radar7, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FriendSummaryCopyWith<$Res> implements $FriendSummaryCopyWith<$Res> {
  factory _$FriendSummaryCopyWith(_FriendSummary value, $Res Function(_FriendSummary) _then) = __$FriendSummaryCopyWithImpl;
@override @useResult
$Res call({
 String userId, List<dynamic> equippedGear, int weeklyRawXp, Map<String, dynamic>? radar30, Map<String, dynamic>? radar7, DateTime updatedAt
});




}
/// @nodoc
class __$FriendSummaryCopyWithImpl<$Res>
    implements _$FriendSummaryCopyWith<$Res> {
  __$FriendSummaryCopyWithImpl(this._self, this._then);

  final _FriendSummary _self;
  final $Res Function(_FriendSummary) _then;

/// Create a copy of FriendSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? equippedGear = null,Object? weeklyRawXp = null,Object? radar30 = freezed,Object? radar7 = freezed,Object? updatedAt = null,}) {
  return _then(_FriendSummary(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,equippedGear: null == equippedGear ? _self._equippedGear : equippedGear // ignore: cast_nullable_to_non_nullable
as List<dynamic>,weeklyRawXp: null == weeklyRawXp ? _self.weeklyRawXp : weeklyRawXp // ignore: cast_nullable_to_non_nullable
as int,radar30: freezed == radar30 ? _self._radar30 : radar30 // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,radar7: freezed == radar7 ? _self._radar7 : radar7 // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
