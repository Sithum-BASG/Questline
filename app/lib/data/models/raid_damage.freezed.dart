// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raid_damage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RaidDamage {

 String get raidId; String get userId; int get damage;
/// Create a copy of RaidDamage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaidDamageCopyWith<RaidDamage> get copyWith => _$RaidDamageCopyWithImpl<RaidDamage>(this as RaidDamage, _$identity);

  /// Serializes this RaidDamage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RaidDamage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaidDamage&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.damage, _this.damage) || other.damage == _this.damage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RaidDamage;
  return Object.hash(runtimeType,_this.raidId,_this.userId,_this.damage);
}

@override
String toString() {
  final _this = this as RaidDamage;
  return 'RaidDamage(raidId: ${_this.raidId}, userId: ${_this.userId}, damage: ${_this.damage})';
}


}

/// @nodoc
abstract mixin class $RaidDamageCopyWith<$Res>  {
  factory $RaidDamageCopyWith(RaidDamage value, $Res Function(RaidDamage) _then) = _$RaidDamageCopyWithImpl;
@useResult
$Res call({
 String raidId, String userId, int damage
});




}
/// @nodoc
class _$RaidDamageCopyWithImpl<$Res>
    implements $RaidDamageCopyWith<$Res> {
  _$RaidDamageCopyWithImpl(this._self, this._then);

  final RaidDamage _self;
  final $Res Function(RaidDamage) _then;

/// Create a copy of RaidDamage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? raidId = null,Object? userId = null,Object? damage = null,}) {
  return _then(RaidDamage(
raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RaidDamage].
extension RaidDamagePatterns on RaidDamage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaidDamage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaidDamage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaidDamage value)  $default,){
final _that = this;
switch (_that) {
case _RaidDamage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaidDamage value)?  $default,){
final _that = this;
switch (_that) {
case _RaidDamage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String raidId,  String userId,  int damage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaidDamage() when $default != null:
return $default(_that.raidId,_that.userId,_that.damage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String raidId,  String userId,  int damage)  $default,) {final _that = this;
switch (_that) {
case _RaidDamage():
return $default(_that.raidId,_that.userId,_that.damage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String raidId,  String userId,  int damage)?  $default,) {final _that = this;
switch (_that) {
case _RaidDamage() when $default != null:
return $default(_that.raidId,_that.userId,_that.damage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaidDamage implements RaidDamage {
  const _RaidDamage({required this.raidId, required this.userId, required this.damage});
  factory _RaidDamage.fromJson(Map<String, dynamic> json) => _$RaidDamageFromJson(json);

@override final  String raidId;
@override final  String userId;
@override final  int damage;

/// Create a copy of RaidDamage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaidDamageCopyWith<_RaidDamage> get copyWith => __$RaidDamageCopyWithImpl<_RaidDamage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaidDamageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaidDamage&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.damage, damage) || other.damage == damage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,raidId,userId,damage);
}

@override
String toString() {
    return 'RaidDamage(raidId: $raidId, userId: $userId, damage: $damage)';
}


}

/// @nodoc
abstract mixin class _$RaidDamageCopyWith<$Res> implements $RaidDamageCopyWith<$Res> {
  factory _$RaidDamageCopyWith(_RaidDamage value, $Res Function(_RaidDamage) _then) = __$RaidDamageCopyWithImpl;
@override @useResult
$Res call({
 String raidId, String userId, int damage
});




}
/// @nodoc
class __$RaidDamageCopyWithImpl<$Res>
    implements _$RaidDamageCopyWith<$Res> {
  __$RaidDamageCopyWithImpl(this._self, this._then);

  final _RaidDamage _self;
  final $Res Function(_RaidDamage) _then;

/// Create a copy of RaidDamage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? raidId = null,Object? userId = null,Object? damage = null,}) {
  return _then(_RaidDamage(
raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
