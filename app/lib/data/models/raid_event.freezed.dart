// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raid_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RaidEvent {

 int get id; String get raidId; String get userId; String get displayName; int get amount; DateTime get at;
/// Create a copy of RaidEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaidEventCopyWith<RaidEvent> get copyWith => _$RaidEventCopyWithImpl<RaidEvent>(this as RaidEvent, _$identity);

  /// Serializes this RaidEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RaidEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaidEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RaidEvent;
  return Object.hash(runtimeType,_this.id,_this.raidId,_this.userId,_this.displayName,_this.amount,_this.at);
}

@override
String toString() {
  final _this = this as RaidEvent;
  return 'RaidEvent(id: ${_this.id}, raidId: ${_this.raidId}, userId: ${_this.userId}, displayName: ${_this.displayName}, amount: ${_this.amount}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $RaidEventCopyWith<$Res>  {
  factory $RaidEventCopyWith(RaidEvent value, $Res Function(RaidEvent) _then) = _$RaidEventCopyWithImpl;
@useResult
$Res call({
 int id, String raidId, String userId, String displayName, int amount, DateTime at
});




}
/// @nodoc
class _$RaidEventCopyWithImpl<$Res>
    implements $RaidEventCopyWith<$Res> {
  _$RaidEventCopyWithImpl(this._self, this._then);

  final RaidEvent _self;
  final $Res Function(RaidEvent) _then;

/// Create a copy of RaidEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? raidId = null,Object? userId = null,Object? displayName = null,Object? amount = null,Object? at = null,}) {
  return _then(RaidEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RaidEvent].
extension RaidEventPatterns on RaidEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaidEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaidEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaidEvent value)  $default,){
final _that = this;
switch (_that) {
case _RaidEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaidEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RaidEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String raidId,  String userId,  String displayName,  int amount,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaidEvent() when $default != null:
return $default(_that.id,_that.raidId,_that.userId,_that.displayName,_that.amount,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String raidId,  String userId,  String displayName,  int amount,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _RaidEvent():
return $default(_that.id,_that.raidId,_that.userId,_that.displayName,_that.amount,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String raidId,  String userId,  String displayName,  int amount,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _RaidEvent() when $default != null:
return $default(_that.id,_that.raidId,_that.userId,_that.displayName,_that.amount,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaidEvent implements RaidEvent {
  const _RaidEvent({required this.id, required this.raidId, required this.userId, required this.displayName, required this.amount, required this.at});
  factory _RaidEvent.fromJson(Map<String, dynamic> json) => _$RaidEventFromJson(json);

@override final  int id;
@override final  String raidId;
@override final  String userId;
@override final  String displayName;
@override final  int amount;
@override final  DateTime at;

/// Create a copy of RaidEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaidEventCopyWith<_RaidEvent> get copyWith => __$RaidEventCopyWithImpl<_RaidEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaidEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaidEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,raidId,userId,displayName,amount,at);
}

@override
String toString() {
    return 'RaidEvent(id: $id, raidId: $raidId, userId: $userId, displayName: $displayName, amount: $amount, at: $at)';
}


}

/// @nodoc
abstract mixin class _$RaidEventCopyWith<$Res> implements $RaidEventCopyWith<$Res> {
  factory _$RaidEventCopyWith(_RaidEvent value, $Res Function(_RaidEvent) _then) = __$RaidEventCopyWithImpl;
@override @useResult
$Res call({
 int id, String raidId, String userId, String displayName, int amount, DateTime at
});




}
/// @nodoc
class __$RaidEventCopyWithImpl<$Res>
    implements _$RaidEventCopyWith<$Res> {
  __$RaidEventCopyWithImpl(this._self, this._then);

  final _RaidEvent _self;
  final $Res Function(_RaidEvent) _then;

/// Create a copy of RaidEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? raidId = null,Object? userId = null,Object? displayName = null,Object? amount = null,Object? at = null,}) {
  return _then(_RaidEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
