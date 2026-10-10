// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guild_trophy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuildTrophy {

 String get guildId; String get raidId; String? get name; DateTime? get wonAt;
/// Create a copy of GuildTrophy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuildTrophyCopyWith<GuildTrophy> get copyWith => _$GuildTrophyCopyWithImpl<GuildTrophy>(this as GuildTrophy, _$identity);

  /// Serializes this GuildTrophy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GuildTrophy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuildTrophy&&(identical(other.guildId, _this.guildId) || other.guildId == _this.guildId)&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.wonAt, _this.wonAt) || other.wonAt == _this.wonAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GuildTrophy;
  return Object.hash(runtimeType,_this.guildId,_this.raidId,_this.name,_this.wonAt);
}

@override
String toString() {
  final _this = this as GuildTrophy;
  return 'GuildTrophy(guildId: ${_this.guildId}, raidId: ${_this.raidId}, name: ${_this.name}, wonAt: ${_this.wonAt})';
}


}

/// @nodoc
abstract mixin class $GuildTrophyCopyWith<$Res>  {
  factory $GuildTrophyCopyWith(GuildTrophy value, $Res Function(GuildTrophy) _then) = _$GuildTrophyCopyWithImpl;
@useResult
$Res call({
 String guildId, String raidId, String? name, DateTime? wonAt
});




}
/// @nodoc
class _$GuildTrophyCopyWithImpl<$Res>
    implements $GuildTrophyCopyWith<$Res> {
  _$GuildTrophyCopyWithImpl(this._self, this._then);

  final GuildTrophy _self;
  final $Res Function(GuildTrophy) _then;

/// Create a copy of GuildTrophy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? guildId = null,Object? raidId = null,Object? name = freezed,Object? wonAt = freezed,}) {
  return _then(GuildTrophy(
guildId: null == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String,raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,wonAt: freezed == wonAt ? _self.wonAt : wonAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuildTrophy].
extension GuildTrophyPatterns on GuildTrophy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuildTrophy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuildTrophy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuildTrophy value)  $default,){
final _that = this;
switch (_that) {
case _GuildTrophy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuildTrophy value)?  $default,){
final _that = this;
switch (_that) {
case _GuildTrophy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String guildId,  String raidId,  String? name,  DateTime? wonAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuildTrophy() when $default != null:
return $default(_that.guildId,_that.raidId,_that.name,_that.wonAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String guildId,  String raidId,  String? name,  DateTime? wonAt)  $default,) {final _that = this;
switch (_that) {
case _GuildTrophy():
return $default(_that.guildId,_that.raidId,_that.name,_that.wonAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String guildId,  String raidId,  String? name,  DateTime? wonAt)?  $default,) {final _that = this;
switch (_that) {
case _GuildTrophy() when $default != null:
return $default(_that.guildId,_that.raidId,_that.name,_that.wonAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuildTrophy implements GuildTrophy {
  const _GuildTrophy({required this.guildId, required this.raidId, this.name, this.wonAt});
  factory _GuildTrophy.fromJson(Map<String, dynamic> json) => _$GuildTrophyFromJson(json);

@override final  String guildId;
@override final  String raidId;
@override final  String? name;
@override final  DateTime? wonAt;

/// Create a copy of GuildTrophy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuildTrophyCopyWith<_GuildTrophy> get copyWith => __$GuildTrophyCopyWithImpl<_GuildTrophy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuildTrophyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuildTrophy&&(identical(other.guildId, guildId) || other.guildId == guildId)&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.name, name) || other.name == name)&&(identical(other.wonAt, wonAt) || other.wonAt == wonAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,guildId,raidId,name,wonAt);
}

@override
String toString() {
    return 'GuildTrophy(guildId: $guildId, raidId: $raidId, name: $name, wonAt: $wonAt)';
}


}

/// @nodoc
abstract mixin class _$GuildTrophyCopyWith<$Res> implements $GuildTrophyCopyWith<$Res> {
  factory _$GuildTrophyCopyWith(_GuildTrophy value, $Res Function(_GuildTrophy) _then) = __$GuildTrophyCopyWithImpl;
@override @useResult
$Res call({
 String guildId, String raidId, String? name, DateTime? wonAt
});




}
/// @nodoc
class __$GuildTrophyCopyWithImpl<$Res>
    implements _$GuildTrophyCopyWith<$Res> {
  __$GuildTrophyCopyWithImpl(this._self, this._then);

  final _GuildTrophy _self;
  final $Res Function(_GuildTrophy) _then;

/// Create a copy of GuildTrophy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? guildId = null,Object? raidId = null,Object? name = freezed,Object? wonAt = freezed,}) {
  return _then(_GuildTrophy(
guildId: null == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String,raidId: null == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,wonAt: freezed == wonAt ? _self.wonAt : wonAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
