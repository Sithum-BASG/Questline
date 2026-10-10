// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guild.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Guild {

 String get id; String get name; String get emblem; String get leaderId; String get inviteCode; String? get questWeekId; int get questGoal; int get questProgress; DateTime get createdAt;
/// Create a copy of Guild
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuildCopyWith<Guild> get copyWith => _$GuildCopyWithImpl<Guild>(this as Guild, _$identity);

  /// Serializes this Guild to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Guild;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Guild&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.emblem, _this.emblem) || other.emblem == _this.emblem)&&(identical(other.leaderId, _this.leaderId) || other.leaderId == _this.leaderId)&&(identical(other.inviteCode, _this.inviteCode) || other.inviteCode == _this.inviteCode)&&(identical(other.questWeekId, _this.questWeekId) || other.questWeekId == _this.questWeekId)&&(identical(other.questGoal, _this.questGoal) || other.questGoal == _this.questGoal)&&(identical(other.questProgress, _this.questProgress) || other.questProgress == _this.questProgress)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Guild;
  return Object.hash(runtimeType,_this.id,_this.name,_this.emblem,_this.leaderId,_this.inviteCode,_this.questWeekId,_this.questGoal,_this.questProgress,_this.createdAt);
}

@override
String toString() {
  final _this = this as Guild;
  return 'Guild(id: ${_this.id}, name: ${_this.name}, emblem: ${_this.emblem}, leaderId: ${_this.leaderId}, inviteCode: ${_this.inviteCode}, questWeekId: ${_this.questWeekId}, questGoal: ${_this.questGoal}, questProgress: ${_this.questProgress}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $GuildCopyWith<$Res>  {
  factory $GuildCopyWith(Guild value, $Res Function(Guild) _then) = _$GuildCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emblem, String leaderId, String inviteCode, String? questWeekId, int questGoal, int questProgress, DateTime createdAt
});




}
/// @nodoc
class _$GuildCopyWithImpl<$Res>
    implements $GuildCopyWith<$Res> {
  _$GuildCopyWithImpl(this._self, this._then);

  final Guild _self;
  final $Res Function(Guild) _then;

/// Create a copy of Guild
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emblem = null,Object? leaderId = null,Object? inviteCode = null,Object? questWeekId = freezed,Object? questGoal = null,Object? questProgress = null,Object? createdAt = null,}) {
  return _then(Guild(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emblem: null == emblem ? _self.emblem : emblem // ignore: cast_nullable_to_non_nullable
as String,leaderId: null == leaderId ? _self.leaderId : leaderId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,questWeekId: freezed == questWeekId ? _self.questWeekId : questWeekId // ignore: cast_nullable_to_non_nullable
as String?,questGoal: null == questGoal ? _self.questGoal : questGoal // ignore: cast_nullable_to_non_nullable
as int,questProgress: null == questProgress ? _self.questProgress : questProgress // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Guild].
extension GuildPatterns on Guild {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Guild value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Guild() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Guild value)  $default,){
final _that = this;
switch (_that) {
case _Guild():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Guild value)?  $default,){
final _that = this;
switch (_that) {
case _Guild() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emblem,  String leaderId,  String inviteCode,  String? questWeekId,  int questGoal,  int questProgress,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Guild() when $default != null:
return $default(_that.id,_that.name,_that.emblem,_that.leaderId,_that.inviteCode,_that.questWeekId,_that.questGoal,_that.questProgress,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emblem,  String leaderId,  String inviteCode,  String? questWeekId,  int questGoal,  int questProgress,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Guild():
return $default(_that.id,_that.name,_that.emblem,_that.leaderId,_that.inviteCode,_that.questWeekId,_that.questGoal,_that.questProgress,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emblem,  String leaderId,  String inviteCode,  String? questWeekId,  int questGoal,  int questProgress,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Guild() when $default != null:
return $default(_that.id,_that.name,_that.emblem,_that.leaderId,_that.inviteCode,_that.questWeekId,_that.questGoal,_that.questProgress,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Guild implements Guild {
  const _Guild({required this.id, required this.name, required this.emblem, required this.leaderId, required this.inviteCode, this.questWeekId, required this.questGoal, required this.questProgress, required this.createdAt});
  factory _Guild.fromJson(Map<String, dynamic> json) => _$GuildFromJson(json);

@override final  String id;
@override final  String name;
@override final  String emblem;
@override final  String leaderId;
@override final  String inviteCode;
@override final  String? questWeekId;
@override final  int questGoal;
@override final  int questProgress;
@override final  DateTime createdAt;

/// Create a copy of Guild
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuildCopyWith<_Guild> get copyWith => __$GuildCopyWithImpl<_Guild>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuildToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Guild&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emblem, emblem) || other.emblem == emblem)&&(identical(other.leaderId, leaderId) || other.leaderId == leaderId)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.questWeekId, questWeekId) || other.questWeekId == questWeekId)&&(identical(other.questGoal, questGoal) || other.questGoal == questGoal)&&(identical(other.questProgress, questProgress) || other.questProgress == questProgress)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,emblem,leaderId,inviteCode,questWeekId,questGoal,questProgress,createdAt);
}

@override
String toString() {
    return 'Guild(id: $id, name: $name, emblem: $emblem, leaderId: $leaderId, inviteCode: $inviteCode, questWeekId: $questWeekId, questGoal: $questGoal, questProgress: $questProgress, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GuildCopyWith<$Res> implements $GuildCopyWith<$Res> {
  factory _$GuildCopyWith(_Guild value, $Res Function(_Guild) _then) = __$GuildCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emblem, String leaderId, String inviteCode, String? questWeekId, int questGoal, int questProgress, DateTime createdAt
});




}
/// @nodoc
class __$GuildCopyWithImpl<$Res>
    implements _$GuildCopyWith<$Res> {
  __$GuildCopyWithImpl(this._self, this._then);

  final _Guild _self;
  final $Res Function(_Guild) _then;

/// Create a copy of Guild
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emblem = null,Object? leaderId = null,Object? inviteCode = null,Object? questWeekId = freezed,Object? questGoal = null,Object? questProgress = null,Object? createdAt = null,}) {
  return _then(_Guild(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emblem: null == emblem ? _self.emblem : emblem // ignore: cast_nullable_to_non_nullable
as String,leaderId: null == leaderId ? _self.leaderId : leaderId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,questWeekId: freezed == questWeekId ? _self.questWeekId : questWeekId // ignore: cast_nullable_to_non_nullable
as String?,questGoal: null == questGoal ? _self.questGoal : questGoal // ignore: cast_nullable_to_non_nullable
as int,questProgress: null == questProgress ? _self.questProgress : questProgress // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
