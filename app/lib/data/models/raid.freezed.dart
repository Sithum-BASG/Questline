// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raid.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Raid {

 String get id; String get source; String? get guildId; String get name; String get title; String get type; String get tier; int get perPersonMinutes; int get participants; int get maxHp; int get damage; DateTime get deadline; String get status; String? get createdBy; String? get inviteCode; bool get coinsEligible; DateTime get createdAt;
/// Create a copy of Raid
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaidCopyWith<Raid> get copyWith => _$RaidCopyWithImpl<Raid>(this as Raid, _$identity);

  /// Serializes this Raid to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Raid;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Raid&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.guildId, _this.guildId) || other.guildId == _this.guildId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.perPersonMinutes, _this.perPersonMinutes) || other.perPersonMinutes == _this.perPersonMinutes)&&(identical(other.participants, _this.participants) || other.participants == _this.participants)&&(identical(other.maxHp, _this.maxHp) || other.maxHp == _this.maxHp)&&(identical(other.damage, _this.damage) || other.damage == _this.damage)&&(identical(other.deadline, _this.deadline) || other.deadline == _this.deadline)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.inviteCode, _this.inviteCode) || other.inviteCode == _this.inviteCode)&&(identical(other.coinsEligible, _this.coinsEligible) || other.coinsEligible == _this.coinsEligible)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Raid;
  return Object.hash(runtimeType,_this.id,_this.source,_this.guildId,_this.name,_this.title,_this.type,_this.tier,_this.perPersonMinutes,_this.participants,_this.maxHp,_this.damage,_this.deadline,_this.status,_this.createdBy,_this.inviteCode,_this.coinsEligible,_this.createdAt);
}

@override
String toString() {
  final _this = this as Raid;
  return 'Raid(id: ${_this.id}, source: ${_this.source}, guildId: ${_this.guildId}, name: ${_this.name}, title: ${_this.title}, type: ${_this.type}, tier: ${_this.tier}, perPersonMinutes: ${_this.perPersonMinutes}, participants: ${_this.participants}, maxHp: ${_this.maxHp}, damage: ${_this.damage}, deadline: ${_this.deadline}, status: ${_this.status}, createdBy: ${_this.createdBy}, inviteCode: ${_this.inviteCode}, coinsEligible: ${_this.coinsEligible}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $RaidCopyWith<$Res>  {
  factory $RaidCopyWith(Raid value, $Res Function(Raid) _then) = _$RaidCopyWithImpl;
@useResult
$Res call({
 String id, String source, String? guildId, String name, String title, String type, String tier, int perPersonMinutes, int participants, int maxHp, int damage, DateTime deadline, String status, String? createdBy, String? inviteCode, bool coinsEligible, DateTime createdAt
});




}
/// @nodoc
class _$RaidCopyWithImpl<$Res>
    implements $RaidCopyWith<$Res> {
  _$RaidCopyWithImpl(this._self, this._then);

  final Raid _self;
  final $Res Function(Raid) _then;

/// Create a copy of Raid
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? guildId = freezed,Object? name = null,Object? title = null,Object? type = null,Object? tier = null,Object? perPersonMinutes = null,Object? participants = null,Object? maxHp = null,Object? damage = null,Object? deadline = null,Object? status = null,Object? createdBy = freezed,Object? inviteCode = freezed,Object? coinsEligible = null,Object? createdAt = null,}) {
  return _then(Raid(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,guildId: freezed == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,perPersonMinutes: null == perPersonMinutes ? _self.perPersonMinutes : perPersonMinutes // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,coinsEligible: null == coinsEligible ? _self.coinsEligible : coinsEligible // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Raid].
extension RaidPatterns on Raid {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Raid value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Raid() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Raid value)  $default,){
final _that = this;
switch (_that) {
case _Raid():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Raid value)?  $default,){
final _that = this;
switch (_that) {
case _Raid() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String source,  String? guildId,  String name,  String title,  String type,  String tier,  int perPersonMinutes,  int participants,  int maxHp,  int damage,  DateTime deadline,  String status,  String? createdBy,  String? inviteCode,  bool coinsEligible,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Raid() when $default != null:
return $default(_that.id,_that.source,_that.guildId,_that.name,_that.title,_that.type,_that.tier,_that.perPersonMinutes,_that.participants,_that.maxHp,_that.damage,_that.deadline,_that.status,_that.createdBy,_that.inviteCode,_that.coinsEligible,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String source,  String? guildId,  String name,  String title,  String type,  String tier,  int perPersonMinutes,  int participants,  int maxHp,  int damage,  DateTime deadline,  String status,  String? createdBy,  String? inviteCode,  bool coinsEligible,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Raid():
return $default(_that.id,_that.source,_that.guildId,_that.name,_that.title,_that.type,_that.tier,_that.perPersonMinutes,_that.participants,_that.maxHp,_that.damage,_that.deadline,_that.status,_that.createdBy,_that.inviteCode,_that.coinsEligible,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String source,  String? guildId,  String name,  String title,  String type,  String tier,  int perPersonMinutes,  int participants,  int maxHp,  int damage,  DateTime deadline,  String status,  String? createdBy,  String? inviteCode,  bool coinsEligible,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Raid() when $default != null:
return $default(_that.id,_that.source,_that.guildId,_that.name,_that.title,_that.type,_that.tier,_that.perPersonMinutes,_that.participants,_that.maxHp,_that.damage,_that.deadline,_that.status,_that.createdBy,_that.inviteCode,_that.coinsEligible,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Raid implements Raid {
  const _Raid({required this.id, required this.source, this.guildId, required this.name, required this.title, required this.type, required this.tier, required this.perPersonMinutes, required this.participants, required this.maxHp, required this.damage, required this.deadline, required this.status, this.createdBy, this.inviteCode, required this.coinsEligible, required this.createdAt});
  factory _Raid.fromJson(Map<String, dynamic> json) => _$RaidFromJson(json);

@override final  String id;
@override final  String source;
@override final  String? guildId;
@override final  String name;
@override final  String title;
@override final  String type;
@override final  String tier;
@override final  int perPersonMinutes;
@override final  int participants;
@override final  int maxHp;
@override final  int damage;
@override final  DateTime deadline;
@override final  String status;
@override final  String? createdBy;
@override final  String? inviteCode;
@override final  bool coinsEligible;
@override final  DateTime createdAt;

/// Create a copy of Raid
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaidCopyWith<_Raid> get copyWith => __$RaidCopyWithImpl<_Raid>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaidToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Raid&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.guildId, guildId) || other.guildId == guildId)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.perPersonMinutes, perPersonMinutes) || other.perPersonMinutes == perPersonMinutes)&&(identical(other.participants, participants) || other.participants == participants)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.damage, damage) || other.damage == damage)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.coinsEligible, coinsEligible) || other.coinsEligible == coinsEligible)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,source,guildId,name,title,type,tier,perPersonMinutes,participants,maxHp,damage,deadline,status,createdBy,inviteCode,coinsEligible,createdAt);
}

@override
String toString() {
    return 'Raid(id: $id, source: $source, guildId: $guildId, name: $name, title: $title, type: $type, tier: $tier, perPersonMinutes: $perPersonMinutes, participants: $participants, maxHp: $maxHp, damage: $damage, deadline: $deadline, status: $status, createdBy: $createdBy, inviteCode: $inviteCode, coinsEligible: $coinsEligible, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RaidCopyWith<$Res> implements $RaidCopyWith<$Res> {
  factory _$RaidCopyWith(_Raid value, $Res Function(_Raid) _then) = __$RaidCopyWithImpl;
@override @useResult
$Res call({
 String id, String source, String? guildId, String name, String title, String type, String tier, int perPersonMinutes, int participants, int maxHp, int damage, DateTime deadline, String status, String? createdBy, String? inviteCode, bool coinsEligible, DateTime createdAt
});




}
/// @nodoc
class __$RaidCopyWithImpl<$Res>
    implements _$RaidCopyWith<$Res> {
  __$RaidCopyWithImpl(this._self, this._then);

  final _Raid _self;
  final $Res Function(_Raid) _then;

/// Create a copy of Raid
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? guildId = freezed,Object? name = null,Object? title = null,Object? type = null,Object? tier = null,Object? perPersonMinutes = null,Object? participants = null,Object? maxHp = null,Object? damage = null,Object? deadline = null,Object? status = null,Object? createdBy = freezed,Object? inviteCode = freezed,Object? coinsEligible = null,Object? createdAt = null,}) {
  return _then(_Raid(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,guildId: freezed == guildId ? _self.guildId : guildId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,perPersonMinutes: null == perPersonMinutes ? _self.perPersonMinutes : perPersonMinutes // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as int,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,coinsEligible: null == coinsEligible ? _self.coinsEligible : coinsEligible // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
