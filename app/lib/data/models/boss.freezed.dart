// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'boss.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Boss {

 String get id; String get userId; String get name; String get title; String get type; String get tier; double get hours; int get maxHp; int get damage; DateTime get deadline; DateTime get createdAt; String get status; DateTime? get lastWorkDay; bool get coinsEligible; Map<String, dynamic>? get loot; bool get resultSeen;
/// Create a copy of Boss
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BossCopyWith<Boss> get copyWith => _$BossCopyWithImpl<Boss>(this as Boss, _$identity);

  /// Serializes this Boss to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Boss;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Boss&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.hours, _this.hours) || other.hours == _this.hours)&&(identical(other.maxHp, _this.maxHp) || other.maxHp == _this.maxHp)&&(identical(other.damage, _this.damage) || other.damage == _this.damage)&&(identical(other.deadline, _this.deadline) || other.deadline == _this.deadline)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.lastWorkDay, _this.lastWorkDay) || other.lastWorkDay == _this.lastWorkDay)&&(identical(other.coinsEligible, _this.coinsEligible) || other.coinsEligible == _this.coinsEligible)&&const DeepCollectionEquality().equals(other.loot, _this.loot)&&(identical(other.resultSeen, _this.resultSeen) || other.resultSeen == _this.resultSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Boss;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.name,_this.title,_this.type,_this.tier,_this.hours,_this.maxHp,_this.damage,_this.deadline,_this.createdAt,_this.status,_this.lastWorkDay,_this.coinsEligible,const DeepCollectionEquality().hash(_this.loot),_this.resultSeen);
}

@override
String toString() {
  final _this = this as Boss;
  return 'Boss(id: ${_this.id}, userId: ${_this.userId}, name: ${_this.name}, title: ${_this.title}, type: ${_this.type}, tier: ${_this.tier}, hours: ${_this.hours}, maxHp: ${_this.maxHp}, damage: ${_this.damage}, deadline: ${_this.deadline}, createdAt: ${_this.createdAt}, status: ${_this.status}, lastWorkDay: ${_this.lastWorkDay}, coinsEligible: ${_this.coinsEligible}, loot: ${_this.loot}, resultSeen: ${_this.resultSeen})';
}


}

/// @nodoc
abstract mixin class $BossCopyWith<$Res>  {
  factory $BossCopyWith(Boss value, $Res Function(Boss) _then) = _$BossCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, String title, String type, String tier, double hours, int maxHp, int damage, DateTime deadline, DateTime createdAt, String status, DateTime? lastWorkDay, bool coinsEligible, Map<String, dynamic>? loot, bool resultSeen
});




}
/// @nodoc
class _$BossCopyWithImpl<$Res>
    implements $BossCopyWith<$Res> {
  _$BossCopyWithImpl(this._self, this._then);

  final Boss _self;
  final $Res Function(Boss) _then;

/// Create a copy of Boss
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? title = null,Object? type = null,Object? tier = null,Object? hours = null,Object? maxHp = null,Object? damage = null,Object? deadline = null,Object? createdAt = null,Object? status = null,Object? lastWorkDay = freezed,Object? coinsEligible = null,Object? loot = freezed,Object? resultSeen = null,}) {
  return _then(Boss(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as double,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastWorkDay: freezed == lastWorkDay ? _self.lastWorkDay : lastWorkDay // ignore: cast_nullable_to_non_nullable
as DateTime?,coinsEligible: null == coinsEligible ? _self.coinsEligible : coinsEligible // ignore: cast_nullable_to_non_nullable
as bool,loot: freezed == loot ? _self.loot : loot // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,resultSeen: null == resultSeen ? _self.resultSeen : resultSeen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Boss].
extension BossPatterns on Boss {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Boss value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Boss() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Boss value)  $default,){
final _that = this;
switch (_that) {
case _Boss():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Boss value)?  $default,){
final _that = this;
switch (_that) {
case _Boss() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String title,  String type,  String tier,  double hours,  int maxHp,  int damage,  DateTime deadline,  DateTime createdAt,  String status,  DateTime? lastWorkDay,  bool coinsEligible,  Map<String, dynamic>? loot,  bool resultSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Boss() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.title,_that.type,_that.tier,_that.hours,_that.maxHp,_that.damage,_that.deadline,_that.createdAt,_that.status,_that.lastWorkDay,_that.coinsEligible,_that.loot,_that.resultSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String title,  String type,  String tier,  double hours,  int maxHp,  int damage,  DateTime deadline,  DateTime createdAt,  String status,  DateTime? lastWorkDay,  bool coinsEligible,  Map<String, dynamic>? loot,  bool resultSeen)  $default,) {final _that = this;
switch (_that) {
case _Boss():
return $default(_that.id,_that.userId,_that.name,_that.title,_that.type,_that.tier,_that.hours,_that.maxHp,_that.damage,_that.deadline,_that.createdAt,_that.status,_that.lastWorkDay,_that.coinsEligible,_that.loot,_that.resultSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  String title,  String type,  String tier,  double hours,  int maxHp,  int damage,  DateTime deadline,  DateTime createdAt,  String status,  DateTime? lastWorkDay,  bool coinsEligible,  Map<String, dynamic>? loot,  bool resultSeen)?  $default,) {final _that = this;
switch (_that) {
case _Boss() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.title,_that.type,_that.tier,_that.hours,_that.maxHp,_that.damage,_that.deadline,_that.createdAt,_that.status,_that.lastWorkDay,_that.coinsEligible,_that.loot,_that.resultSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Boss implements Boss {
  const _Boss({required this.id, required this.userId, required this.name, required this.title, required this.type, required this.tier, required this.hours, required this.maxHp, required this.damage, required this.deadline, required this.createdAt, required this.status, this.lastWorkDay, required this.coinsEligible,  Map<String, dynamic>? loot, required this.resultSeen}): _loot = loot;
  factory _Boss.fromJson(Map<String, dynamic> json) => _$BossFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  String title;
@override final  String type;
@override final  String tier;
@override final  double hours;
@override final  int maxHp;
@override final  int damage;
@override final  DateTime deadline;
@override final  DateTime createdAt;
@override final  String status;
@override final  DateTime? lastWorkDay;
@override final  bool coinsEligible;
 final  Map<String, dynamic>? _loot;
@override Map<String, dynamic>? get loot {
  final value = _loot;
  if (value == null) return null;
  if (_loot is EqualUnmodifiableMapView) return _loot;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  bool resultSeen;

/// Create a copy of Boss
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BossCopyWith<_Boss> get copyWith => __$BossCopyWithImpl<_Boss>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BossToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Boss&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.maxHp, maxHp) || other.maxHp == maxHp)&&(identical(other.damage, damage) || other.damage == damage)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastWorkDay, lastWorkDay) || other.lastWorkDay == lastWorkDay)&&(identical(other.coinsEligible, coinsEligible) || other.coinsEligible == coinsEligible)&&const DeepCollectionEquality().equals(other.loot, _loot)&&(identical(other.resultSeen, resultSeen) || other.resultSeen == resultSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,name,title,type,tier,hours,maxHp,damage,deadline,createdAt,status,lastWorkDay,coinsEligible,const DeepCollectionEquality().hash(_loot),resultSeen);
}

@override
String toString() {
    return 'Boss(id: $id, userId: $userId, name: $name, title: $title, type: $type, tier: $tier, hours: $hours, maxHp: $maxHp, damage: $damage, deadline: $deadline, createdAt: $createdAt, status: $status, lastWorkDay: $lastWorkDay, coinsEligible: $coinsEligible, loot: $loot, resultSeen: $resultSeen)';
}


}

/// @nodoc
abstract mixin class _$BossCopyWith<$Res> implements $BossCopyWith<$Res> {
  factory _$BossCopyWith(_Boss value, $Res Function(_Boss) _then) = __$BossCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, String title, String type, String tier, double hours, int maxHp, int damage, DateTime deadline, DateTime createdAt, String status, DateTime? lastWorkDay, bool coinsEligible, Map<String, dynamic>? loot, bool resultSeen
});




}
/// @nodoc
class __$BossCopyWithImpl<$Res>
    implements _$BossCopyWith<$Res> {
  __$BossCopyWithImpl(this._self, this._then);

  final _Boss _self;
  final $Res Function(_Boss) _then;

/// Create a copy of Boss
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? title = null,Object? type = null,Object? tier = null,Object? hours = null,Object? maxHp = null,Object? damage = null,Object? deadline = null,Object? createdAt = null,Object? status = null,Object? lastWorkDay = freezed,Object? coinsEligible = null,Object? loot = freezed,Object? resultSeen = null,}) {
  return _then(_Boss(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as double,maxHp: null == maxHp ? _self.maxHp : maxHp // ignore: cast_nullable_to_non_nullable
as int,damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as int,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastWorkDay: freezed == lastWorkDay ? _self.lastWorkDay : lastWorkDay // ignore: cast_nullable_to_non_nullable
as DateTime?,coinsEligible: null == coinsEligible ? _self.coinsEligible : coinsEligible // ignore: cast_nullable_to_non_nullable
as bool,loot: freezed == loot ? _self._loot : loot // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,resultSeen: null == resultSeen ? _self.resultSeen : resultSeen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
