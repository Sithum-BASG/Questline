// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guild_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuildMember {

 String get guildId; String get userId; DateTime get joinedAt; int get questContribution;
/// Create a copy of GuildMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuildMemberCopyWith<GuildMember> get copyWith => _$GuildMemberCopyWithImpl<GuildMember>(this as GuildMember, _$identity);

  /// Serializes this GuildMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GuildMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuildMember&&(identical(other.guildId, _this.guildId) || other.guildId == _this.guildId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.questContribution, _this.questContribution) || other.questContribution == _this.questContribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GuildMember;
  return Object.hash(runtimeType,_this.guildId,_this.userId,_this.joinedAt,_this.questContribution);
}

@override
String toString() {
  final _this = this as GuildMember;
  return 'GuildMember(guildId: ${_this.guildId}, userId: ${_this.userId}, joinedAt: ${_this.joinedAt}, questContribution: ${_this.questContribution})';
}


}

/// @nodoc
abstract mixin class $GuildMemberCopyWith<$Res>  {
  factory $GuildMemberCopyWith(GuildMember value, $Res Function(GuildMember) _then) = _$GuildMemberCopyWithImpl;
@useResult
$Res call({
 String guildId, String userId, DateTime joinedAt, int questContribution
});




}
/// @nodoc
class _$GuildMemberCopyWithImpl<$Res>
    implements $GuildMemberCopyWith<$Res> {
  _$GuildMemberCopyWithImpl(this._self, this._then);

  final GuildMember _self;
  final $Res Function(GuildMember) _then;

/// Create a copy of GuildMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? guildId = null,Object? userId = null,Object? joinedAt = null,Object? questContribution = null,}) {
  return _then(GuildMember(
guildId: null == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,questContribution: null == questContribution ? _self.questContribution : questContribution // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GuildMember].
extension GuildMemberPatterns on GuildMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuildMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuildMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuildMember value)  $default,){
final _that = this;
switch (_that) {
case _GuildMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuildMember value)?  $default,){
final _that = this;
switch (_that) {
case _GuildMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String guildId,  String userId,  DateTime joinedAt,  int questContribution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuildMember() when $default != null:
return $default(_that.guildId,_that.userId,_that.joinedAt,_that.questContribution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String guildId,  String userId,  DateTime joinedAt,  int questContribution)  $default,) {final _that = this;
switch (_that) {
case _GuildMember():
return $default(_that.guildId,_that.userId,_that.joinedAt,_that.questContribution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String guildId,  String userId,  DateTime joinedAt,  int questContribution)?  $default,) {final _that = this;
switch (_that) {
case _GuildMember() when $default != null:
return $default(_that.guildId,_that.userId,_that.joinedAt,_that.questContribution);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuildMember implements GuildMember {
  const _GuildMember({required this.guildId, required this.userId, required this.joinedAt, required this.questContribution});
  factory _GuildMember.fromJson(Map<String, dynamic> json) => _$GuildMemberFromJson(json);

@override final  String guildId;
@override final  String userId;
@override final  DateTime joinedAt;
@override final  int questContribution;

/// Create a copy of GuildMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuildMemberCopyWith<_GuildMember> get copyWith => __$GuildMemberCopyWithImpl<_GuildMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuildMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuildMember&&(identical(other.guildId, guildId) || other.guildId == guildId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.questContribution, questContribution) || other.questContribution == questContribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,guildId,userId,joinedAt,questContribution);
}

@override
String toString() {
    return 'GuildMember(guildId: $guildId, userId: $userId, joinedAt: $joinedAt, questContribution: $questContribution)';
}


}

/// @nodoc
abstract mixin class _$GuildMemberCopyWith<$Res> implements $GuildMemberCopyWith<$Res> {
  factory _$GuildMemberCopyWith(_GuildMember value, $Res Function(_GuildMember) _then) = __$GuildMemberCopyWithImpl;
@override @useResult
$Res call({
 String guildId, String userId, DateTime joinedAt, int questContribution
});




}
/// @nodoc
class __$GuildMemberCopyWithImpl<$Res>
    implements _$GuildMemberCopyWith<$Res> {
  __$GuildMemberCopyWithImpl(this._self, this._then);

  final _GuildMember _self;
  final $Res Function(_GuildMember) _then;

/// Create a copy of GuildMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? guildId = null,Object? userId = null,Object? joinedAt = null,Object? questContribution = null,}) {
  return _then(_GuildMember(
guildId: null == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,questContribution: null == questContribution ? _self.questContribution : questContribution // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
