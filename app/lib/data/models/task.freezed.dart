// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id; String get userId; String get title; String? get notes; DateTime? get dueAt; DateTime? get originalDueAt; String? get bossId; String? get raidId; String get status; bool get rescheduled; bool get scrollUsed; DateTime get createdAt; String? get stat; int? get difficulty; int? get estMinutes; bool? get tooBig; String? get reason; bool get provisional; bool get challenged; DateTime? get judgedAt; String? get completionMode; int? get completionMinutes; DateTime? get completedAt; DateTime? get completionDay; int? get xpRaw; int? get xpFinal;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Task;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.dueAt, _this.dueAt) || other.dueAt == _this.dueAt)&&(identical(other.originalDueAt, _this.originalDueAt) || other.originalDueAt == _this.originalDueAt)&&(identical(other.bossId, _this.bossId) || other.bossId == _this.bossId)&&(identical(other.raidId, _this.raidId) || other.raidId == _this.raidId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.rescheduled, _this.rescheduled) || other.rescheduled == _this.rescheduled)&&(identical(other.scrollUsed, _this.scrollUsed) || other.scrollUsed == _this.scrollUsed)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.stat, _this.stat) || other.stat == _this.stat)&&(identical(other.difficulty, _this.difficulty) || other.difficulty == _this.difficulty)&&(identical(other.estMinutes, _this.estMinutes) || other.estMinutes == _this.estMinutes)&&(identical(other.tooBig, _this.tooBig) || other.tooBig == _this.tooBig)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.provisional, _this.provisional) || other.provisional == _this.provisional)&&(identical(other.challenged, _this.challenged) || other.challenged == _this.challenged)&&(identical(other.judgedAt, _this.judgedAt) || other.judgedAt == _this.judgedAt)&&(identical(other.completionMode, _this.completionMode) || other.completionMode == _this.completionMode)&&(identical(other.completionMinutes, _this.completionMinutes) || other.completionMinutes == _this.completionMinutes)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.completionDay, _this.completionDay) || other.completionDay == _this.completionDay)&&(identical(other.xpRaw, _this.xpRaw) || other.xpRaw == _this.xpRaw)&&(identical(other.xpFinal, _this.xpFinal) || other.xpFinal == _this.xpFinal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Task;
  return Object.hashAll([runtimeType,_this.id,_this.userId,_this.title,_this.notes,_this.dueAt,_this.originalDueAt,_this.bossId,_this.raidId,_this.status,_this.rescheduled,_this.scrollUsed,_this.createdAt,_this.stat,_this.difficulty,_this.estMinutes,_this.tooBig,_this.reason,_this.provisional,_this.challenged,_this.judgedAt,_this.completionMode,_this.completionMinutes,_this.completedAt,_this.completionDay,_this.xpRaw,_this.xpFinal]);
}

@override
String toString() {
  final _this = this as Task;
  return 'Task(id: ${_this.id}, userId: ${_this.userId}, title: ${_this.title}, notes: ${_this.notes}, dueAt: ${_this.dueAt}, originalDueAt: ${_this.originalDueAt}, bossId: ${_this.bossId}, raidId: ${_this.raidId}, status: ${_this.status}, rescheduled: ${_this.rescheduled}, scrollUsed: ${_this.scrollUsed}, createdAt: ${_this.createdAt}, stat: ${_this.stat}, difficulty: ${_this.difficulty}, estMinutes: ${_this.estMinutes}, tooBig: ${_this.tooBig}, reason: ${_this.reason}, provisional: ${_this.provisional}, challenged: ${_this.challenged}, judgedAt: ${_this.judgedAt}, completionMode: ${_this.completionMode}, completionMinutes: ${_this.completionMinutes}, completedAt: ${_this.completedAt}, completionDay: ${_this.completionDay}, xpRaw: ${_this.xpRaw}, xpFinal: ${_this.xpFinal})';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String title, String? notes, DateTime? dueAt, DateTime? originalDueAt, String? bossId, String? raidId, String status, bool rescheduled, bool scrollUsed, DateTime createdAt, String? stat, int? difficulty, int? estMinutes, bool? tooBig, String? reason, bool provisional, bool challenged, DateTime? judgedAt, String? completionMode, int? completionMinutes, DateTime? completedAt, DateTime? completionDay, int? xpRaw, int? xpFinal
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? notes = freezed,Object? dueAt = freezed,Object? originalDueAt = freezed,Object? bossId = freezed,Object? raidId = freezed,Object? status = null,Object? rescheduled = null,Object? scrollUsed = null,Object? createdAt = null,Object? stat = freezed,Object? difficulty = freezed,Object? estMinutes = freezed,Object? tooBig = freezed,Object? reason = freezed,Object? provisional = null,Object? challenged = null,Object? judgedAt = freezed,Object? completionMode = freezed,Object? completionMinutes = freezed,Object? completedAt = freezed,Object? completionDay = freezed,Object? xpRaw = freezed,Object? xpFinal = freezed,}) {
  return _then(Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,originalDueAt: freezed == originalDueAt ? _self.originalDueAt : originalDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bossId: freezed == bossId ? _self.bossId : bossId // ignore: cast_nullable_to_non_nullable
as String?,raidId: freezed == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rescheduled: null == rescheduled ? _self.rescheduled : rescheduled // ignore: cast_nullable_to_non_nullable
as bool,scrollUsed: null == scrollUsed ? _self.scrollUsed : scrollUsed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,stat: freezed == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as String?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int?,estMinutes: freezed == estMinutes ? _self.estMinutes : estMinutes // ignore: cast_nullable_to_non_nullable
as int?,tooBig: freezed == tooBig ? _self.tooBig : tooBig // ignore: cast_nullable_to_non_nullable
as bool?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,provisional: null == provisional ? _self.provisional : provisional // ignore: cast_nullable_to_non_nullable
as bool,challenged: null == challenged ? _self.challenged : challenged // ignore: cast_nullable_to_non_nullable
as bool,judgedAt: freezed == judgedAt ? _self.judgedAt : judgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionMode: freezed == completionMode ? _self.completionMode : completionMode // ignore: cast_nullable_to_non_nullable
as String?,completionMinutes: freezed == completionMinutes ? _self.completionMinutes : completionMinutes // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionDay: freezed == completionDay ? _self.completionDay : completionDay // ignore: cast_nullable_to_non_nullable
as DateTime?,xpRaw: freezed == xpRaw ? _self.xpRaw : xpRaw // ignore: cast_nullable_to_non_nullable
as int?,xpFinal: freezed == xpFinal ? _self.xpFinal : xpFinal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  String? notes,  DateTime? dueAt,  DateTime? originalDueAt,  String? bossId,  String? raidId,  String status,  bool rescheduled,  bool scrollUsed,  DateTime createdAt,  String? stat,  int? difficulty,  int? estMinutes,  bool? tooBig,  String? reason,  bool provisional,  bool challenged,  DateTime? judgedAt,  String? completionMode,  int? completionMinutes,  DateTime? completedAt,  DateTime? completionDay,  int? xpRaw,  int? xpFinal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.notes,_that.dueAt,_that.originalDueAt,_that.bossId,_that.raidId,_that.status,_that.rescheduled,_that.scrollUsed,_that.createdAt,_that.stat,_that.difficulty,_that.estMinutes,_that.tooBig,_that.reason,_that.provisional,_that.challenged,_that.judgedAt,_that.completionMode,_that.completionMinutes,_that.completedAt,_that.completionDay,_that.xpRaw,_that.xpFinal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  String? notes,  DateTime? dueAt,  DateTime? originalDueAt,  String? bossId,  String? raidId,  String status,  bool rescheduled,  bool scrollUsed,  DateTime createdAt,  String? stat,  int? difficulty,  int? estMinutes,  bool? tooBig,  String? reason,  bool provisional,  bool challenged,  DateTime? judgedAt,  String? completionMode,  int? completionMinutes,  DateTime? completedAt,  DateTime? completionDay,  int? xpRaw,  int? xpFinal)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.userId,_that.title,_that.notes,_that.dueAt,_that.originalDueAt,_that.bossId,_that.raidId,_that.status,_that.rescheduled,_that.scrollUsed,_that.createdAt,_that.stat,_that.difficulty,_that.estMinutes,_that.tooBig,_that.reason,_that.provisional,_that.challenged,_that.judgedAt,_that.completionMode,_that.completionMinutes,_that.completedAt,_that.completionDay,_that.xpRaw,_that.xpFinal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String title,  String? notes,  DateTime? dueAt,  DateTime? originalDueAt,  String? bossId,  String? raidId,  String status,  bool rescheduled,  bool scrollUsed,  DateTime createdAt,  String? stat,  int? difficulty,  int? estMinutes,  bool? tooBig,  String? reason,  bool provisional,  bool challenged,  DateTime? judgedAt,  String? completionMode,  int? completionMinutes,  DateTime? completedAt,  DateTime? completionDay,  int? xpRaw,  int? xpFinal)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.notes,_that.dueAt,_that.originalDueAt,_that.bossId,_that.raidId,_that.status,_that.rescheduled,_that.scrollUsed,_that.createdAt,_that.stat,_that.difficulty,_that.estMinutes,_that.tooBig,_that.reason,_that.provisional,_that.challenged,_that.judgedAt,_that.completionMode,_that.completionMinutes,_that.completedAt,_that.completionDay,_that.xpRaw,_that.xpFinal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task implements Task {
  const _Task({required this.id, required this.userId, required this.title, this.notes, this.dueAt, this.originalDueAt, this.bossId, this.raidId, required this.status, required this.rescheduled, required this.scrollUsed, required this.createdAt, this.stat, this.difficulty, this.estMinutes, this.tooBig, this.reason, required this.provisional, required this.challenged, this.judgedAt, this.completionMode, this.completionMinutes, this.completedAt, this.completionDay, this.xpRaw, this.xpFinal});
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String title;
@override final  String? notes;
@override final  DateTime? dueAt;
@override final  DateTime? originalDueAt;
@override final  String? bossId;
@override final  String? raidId;
@override final  String status;
@override final  bool rescheduled;
@override final  bool scrollUsed;
@override final  DateTime createdAt;
@override final  String? stat;
@override final  int? difficulty;
@override final  int? estMinutes;
@override final  bool? tooBig;
@override final  String? reason;
@override final  bool provisional;
@override final  bool challenged;
@override final  DateTime? judgedAt;
@override final  String? completionMode;
@override final  int? completionMinutes;
@override final  DateTime? completedAt;
@override final  DateTime? completionDay;
@override final  int? xpRaw;
@override final  int? xpFinal;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.originalDueAt, originalDueAt) || other.originalDueAt == originalDueAt)&&(identical(other.bossId, bossId) || other.bossId == bossId)&&(identical(other.raidId, raidId) || other.raidId == raidId)&&(identical(other.status, status) || other.status == status)&&(identical(other.rescheduled, rescheduled) || other.rescheduled == rescheduled)&&(identical(other.scrollUsed, scrollUsed) || other.scrollUsed == scrollUsed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.estMinutes, estMinutes) || other.estMinutes == estMinutes)&&(identical(other.tooBig, tooBig) || other.tooBig == tooBig)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.provisional, provisional) || other.provisional == provisional)&&(identical(other.challenged, challenged) || other.challenged == challenged)&&(identical(other.judgedAt, judgedAt) || other.judgedAt == judgedAt)&&(identical(other.completionMode, completionMode) || other.completionMode == completionMode)&&(identical(other.completionMinutes, completionMinutes) || other.completionMinutes == completionMinutes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completionDay, completionDay) || other.completionDay == completionDay)&&(identical(other.xpRaw, xpRaw) || other.xpRaw == xpRaw)&&(identical(other.xpFinal, xpFinal) || other.xpFinal == xpFinal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,userId,title,notes,dueAt,originalDueAt,bossId,raidId,status,rescheduled,scrollUsed,createdAt,stat,difficulty,estMinutes,tooBig,reason,provisional,challenged,judgedAt,completionMode,completionMinutes,completedAt,completionDay,xpRaw,xpFinal]);
}

@override
String toString() {
    return 'Task(id: $id, userId: $userId, title: $title, notes: $notes, dueAt: $dueAt, originalDueAt: $originalDueAt, bossId: $bossId, raidId: $raidId, status: $status, rescheduled: $rescheduled, scrollUsed: $scrollUsed, createdAt: $createdAt, stat: $stat, difficulty: $difficulty, estMinutes: $estMinutes, tooBig: $tooBig, reason: $reason, provisional: $provisional, challenged: $challenged, judgedAt: $judgedAt, completionMode: $completionMode, completionMinutes: $completionMinutes, completedAt: $completedAt, completionDay: $completionDay, xpRaw: $xpRaw, xpFinal: $xpFinal)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String title, String? notes, DateTime? dueAt, DateTime? originalDueAt, String? bossId, String? raidId, String status, bool rescheduled, bool scrollUsed, DateTime createdAt, String? stat, int? difficulty, int? estMinutes, bool? tooBig, String? reason, bool provisional, bool challenged, DateTime? judgedAt, String? completionMode, int? completionMinutes, DateTime? completedAt, DateTime? completionDay, int? xpRaw, int? xpFinal
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? notes = freezed,Object? dueAt = freezed,Object? originalDueAt = freezed,Object? bossId = freezed,Object? raidId = freezed,Object? status = null,Object? rescheduled = null,Object? scrollUsed = null,Object? createdAt = null,Object? stat = freezed,Object? difficulty = freezed,Object? estMinutes = freezed,Object? tooBig = freezed,Object? reason = freezed,Object? provisional = null,Object? challenged = null,Object? judgedAt = freezed,Object? completionMode = freezed,Object? completionMinutes = freezed,Object? completedAt = freezed,Object? completionDay = freezed,Object? xpRaw = freezed,Object? xpFinal = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,originalDueAt: freezed == originalDueAt ? _self.originalDueAt : originalDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bossId: freezed == bossId ? _self.bossId : bossId // ignore: cast_nullable_to_non_nullable
as String?,raidId: freezed == raidId ? _self.raidId : raidId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rescheduled: null == rescheduled ? _self.rescheduled : rescheduled // ignore: cast_nullable_to_non_nullable
as bool,scrollUsed: null == scrollUsed ? _self.scrollUsed : scrollUsed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,stat: freezed == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as String?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int?,estMinutes: freezed == estMinutes ? _self.estMinutes : estMinutes // ignore: cast_nullable_to_non_nullable
as int?,tooBig: freezed == tooBig ? _self.tooBig : tooBig // ignore: cast_nullable_to_non_nullable
as bool?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,provisional: null == provisional ? _self.provisional : provisional // ignore: cast_nullable_to_non_nullable
as bool,challenged: null == challenged ? _self.challenged : challenged // ignore: cast_nullable_to_non_nullable
as bool,judgedAt: freezed == judgedAt ? _self.judgedAt : judgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionMode: freezed == completionMode ? _self.completionMode : completionMode // ignore: cast_nullable_to_non_nullable
as String?,completionMinutes: freezed == completionMinutes ? _self.completionMinutes : completionMinutes // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionDay: freezed == completionDay ? _self.completionDay : completionDay // ignore: cast_nullable_to_non_nullable
as DateTime?,xpRaw: freezed == xpRaw ? _self.xpRaw : xpRaw // ignore: cast_nullable_to_non_nullable
as int?,xpFinal: freezed == xpFinal ? _self.xpFinal : xpFinal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
