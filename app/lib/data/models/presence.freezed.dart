// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Presence {

 String get userId; String get state; String? get stat; DateTime? get startedAt; String? get raidId; DateTime get lastSeen;
/// Create a copy of Presence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceCopyWith<Presence> get copyWith => _$PresenceCopyWithImpl<Presence>(this as Presence, _$identity);

  /// Serializes this Presence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Presence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Presence&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.stat, _this.stat) || other.stat == _this.stat)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.lastSeen, _this.lastSeen) || other.lastSeen == _this.lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Presence;
  return Object.hash(runtimeType,_this.userId,_this.state,_this.stat,_this.startedAt,_this.raidId,_this.lastSeen);
}

@override
String toString() {
  final _this = this as Presence;
  return 'Presence(userId: ${_this.userId}, state: ${_this.state}, stat: ${_this.stat}, startedAt: ${_this.startedAt}, raidId: ${_this.raidId}, lastSeen: ${_this.lastSeen})';
}


}

/// @nodoc
abstract mixin class $PresenceCopyWith<$Res>  {
  factory $PresenceCopyWith(Presence value, $Res Function(Presence) _then) = _$PresenceCopyWithImpl;
@useResult
$Res call({
 String userId, String state, String? stat, DateTime? startedAt, String? raidId, DateTime lastSeen
});




}
/// @nodoc
class _$PresenceCopyWithImpl<$Res>
    implements $PresenceCopyWith<$Res> {
  _$PresenceCopyWithImpl(this._self, this._then);

  final Presence _self;
  final $Res Function(Presence) _then;

/// Create a copy of Presence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? state = null,Object? stat = freezed,Object? startedAt = freezed,Object? raidId = freezed,Object? lastSeen = null,}) {
  return _then(Presence(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,stat: freezed == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,raidId: freezed == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String?,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Presence].
extension PresencePatterns on Presence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Presence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Presence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Presence value)  $default,){
final _that = this;
switch (_that) {
case _Presence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Presence value)?  $default,){
final _that = this;
switch (_that) {
case _Presence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String state,  String? stat,  DateTime? startedAt,  String? raidId,  DateTime lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Presence() when $default != null:
return $default(_that.userId,_that.state,_that.stat,_that.startedAt,_that.raidId,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String state,  String? stat,  DateTime? startedAt,  String? raidId,  DateTime lastSeen)  $default,) {final _that = this;
switch (_that) {
case _Presence():
return $default(_that.userId,_that.state,_that.stat,_that.startedAt,_that.raidId,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String state,  String? stat,  DateTime? startedAt,  String? raidId,  DateTime lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _Presence() when $default != null:
return $default(_that.userId,_that.state,_that.stat,_that.startedAt,_that.raidId,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Presence implements Presence {
  const _Presence({required this.userId, required this.state, this.stat, this.startedAt, this.raidId, required this.lastSeen});
  factory _Presence.fromJson(Map<String, dynamic> json) => _$PresenceFromJson(json);

@override final  String userId;
@override final  String state;
@override final  String? stat;
@override final  DateTime? startedAt;
@override final  String? raidId;
@override final  DateTime lastSeen;

/// Create a copy of Presence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresenceCopyWith<_Presence> get copyWith => __$PresenceCopyWithImpl<_Presence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Presence&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.state, state) || other.state == state)&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,state,stat,startedAt,raidId,lastSeen);
}

@override
String toString() {
    return 'Presence(userId: $userId, state: $state, stat: $stat, startedAt: $startedAt, raidId: $raidId, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$PresenceCopyWith<$Res> implements $PresenceCopyWith<$Res> {
  factory _$PresenceCopyWith(_Presence value, $Res Function(_Presence) _then) = __$PresenceCopyWithImpl;
@override @useResult
$Res call({
 String userId, String state, String? stat, DateTime? startedAt, String? raidId, DateTime lastSeen
});




}
/// @nodoc
class __$PresenceCopyWithImpl<$Res>
    implements _$PresenceCopyWith<$Res> {
  __$PresenceCopyWithImpl(this._self, this._then);

  final _Presence _self;
  final $Res Function(_Presence) _then;

/// Create a copy of Presence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? state = null,Object? stat = freezed,Object? startedAt = freezed,Object? raidId = freezed,Object? lastSeen = null,}) {
  return _then(_Presence(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,stat: freezed == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,raidId: freezed == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String?,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
