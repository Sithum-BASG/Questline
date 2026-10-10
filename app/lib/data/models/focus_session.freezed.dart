// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusSession {

 String get id; String get userId; String get taskId; String get mode; DateTime get startedAt; DateTime? get endedAt; List<dynamic> get interruptions; int get interruptionSeconds; int? get verifiedMinutes; String get status; bool get potion; bool get demo; bool get processed; Map<String, dynamic>? get summary;
/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusSessionCopyWith<FocusSession> get copyWith => _$FocusSessionCopyWithImpl<FocusSession>(this as FocusSession, _$identity);

  /// Serializes this FocusSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FocusSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&const DeepCollectionEquality().equals(other.interruptions, _this.interruptions)&&(identical(other.interruptionSeconds, _this.interruptionSeconds) || other.interruptionSeconds == _this.interruptionSeconds)&&(identical(other.verifiedMinutes, _this.verifiedMinutes) || other.verifiedMinutes == _this.verifiedMinutes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.potion, _this.potion) || other.potion == _this.potion)&&(identical(other.demo, _this.demo) || other.demo == _this.demo)&&(identical(other.processed, _this.processed) || other.processed == _this.processed)&&const DeepCollectionEquality().equals(other.summary, _this.summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FocusSession;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.taskId,_this.mode,_this.startedAt,_this.endedAt,const DeepCollectionEquality().hash(_this.interruptions),_this.interruptionSeconds,_this.verifiedMinutes,_this.status,_this.potion,_this.demo,_this.processed,const DeepCollectionEquality().hash(_this.summary));
}

@override
String toString() {
  final _this = this as FocusSession;
  return 'FocusSession(id: ${_this.id}, userId: ${_this.userId}, taskId: ${_this.taskId}, mode: ${_this.mode}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, interruptions: ${_this.interruptions}, interruptionSeconds: ${_this.interruptionSeconds}, verifiedMinutes: ${_this.verifiedMinutes}, status: ${_this.status}, potion: ${_this.potion}, demo: ${_this.demo}, processed: ${_this.processed}, summary: ${_this.summary})';
}


}

/// @nodoc
abstract mixin class $FocusSessionCopyWith<$Res>  {
  factory $FocusSessionCopyWith(FocusSession value, $Res Function(FocusSession) _then) = _$FocusSessionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String taskId, String mode, DateTime startedAt, DateTime? endedAt, List<dynamic> interruptions, int interruptionSeconds, int? verifiedMinutes, String status, bool potion, bool demo, bool processed, Map<String, dynamic>? summary
});




}
/// @nodoc
class _$FocusSessionCopyWithImpl<$Res>
    implements $FocusSessionCopyWith<$Res> {
  _$FocusSessionCopyWithImpl(this._self, this._then);

  final FocusSession _self;
  final $Res Function(FocusSession) _then;

/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? taskId = null,Object? mode = null,Object? startedAt = null,Object? endedAt = freezed,Object? interruptions = null,Object? interruptionSeconds = null,Object? verifiedMinutes = freezed,Object? status = null,Object? potion = null,Object? demo = null,Object? processed = null,Object? summary = freezed,}) {
  return _then(FocusSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,interruptions: null == interruptions ? _self.interruptions : interruptions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,interruptionSeconds: null == interruptionSeconds ? _self.interruptionSeconds : interruptionSeconds // ignore: cast_nullable_to_non_nullable
as int,verifiedMinutes: freezed == verifiedMinutes ? _self.verifiedMinutes : verifiedMinutes // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,potion: null == potion ? _self.potion : potion // ignore: cast_nullable_to_non_nullable
as bool,demo: null == demo ? _self.demo : demo // ignore: cast_nullable_to_non_nullable
as bool,processed: null == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as bool,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [FocusSession].
extension FocusSessionPatterns on FocusSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusSession value)  $default,){
final _that = this;
switch (_that) {
case _FocusSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusSession value)?  $default,){
final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String taskId,  String mode,  DateTime startedAt,  DateTime? endedAt,  List<dynamic> interruptions,  int interruptionSeconds,  int? verifiedMinutes,  String status,  bool potion,  bool demo,  bool processed,  Map<String, dynamic>? summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
return $default(_that.id,_that.userId,_that.taskId,_that.mode,_that.startedAt,_that.endedAt,_that.interruptions,_that.interruptionSeconds,_that.verifiedMinutes,_that.status,_that.potion,_that.demo,_that.processed,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String taskId,  String mode,  DateTime startedAt,  DateTime? endedAt,  List<dynamic> interruptions,  int interruptionSeconds,  int? verifiedMinutes,  String status,  bool potion,  bool demo,  bool processed,  Map<String, dynamic>? summary)  $default,) {final _that = this;
switch (_that) {
case _FocusSession():
return $default(_that.id,_that.userId,_that.taskId,_that.mode,_that.startedAt,_that.endedAt,_that.interruptions,_that.interruptionSeconds,_that.verifiedMinutes,_that.status,_that.potion,_that.demo,_that.processed,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String taskId,  String mode,  DateTime startedAt,  DateTime? endedAt,  List<dynamic> interruptions,  int interruptionSeconds,  int? verifiedMinutes,  String status,  bool potion,  bool demo,  bool processed,  Map<String, dynamic>? summary)?  $default,) {final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
return $default(_that.id,_that.userId,_that.taskId,_that.mode,_that.startedAt,_that.endedAt,_that.interruptions,_that.interruptionSeconds,_that.verifiedMinutes,_that.status,_that.potion,_that.demo,_that.processed,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FocusSession implements FocusSession {
  const _FocusSession({required this.id, required this.userId, required this.taskId, required this.mode, required this.startedAt, this.endedAt, required  List<dynamic> interruptions, required this.interruptionSeconds, this.verifiedMinutes, required this.status, required this.potion, required this.demo, required this.processed,  Map<String, dynamic>? summary}): _interruptions = interruptions,_summary = summary;
  factory _FocusSession.fromJson(Map<String, dynamic> json) => _$FocusSessionFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String taskId;
@override final  String mode;
@override final  DateTime startedAt;
@override final  DateTime? endedAt;
 final  List<dynamic> _interruptions;
@override List<dynamic> get interruptions {
  if (_interruptions is EqualUnmodifiableListView) return _interruptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_interruptions);
}

@override final  int interruptionSeconds;
@override final  int? verifiedMinutes;
@override final  String status;
@override final  bool potion;
@override final  bool demo;
@override final  bool processed;
 final  Map<String, dynamic>? _summary;
@override Map<String, dynamic>? get summary {
  final value = _summary;
  if (value == null) return null;
  if (_summary is EqualUnmodifiableMapView) return _summary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusSessionCopyWith<_FocusSession> get copyWith => __$FocusSessionCopyWithImpl<_FocusSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FocusSessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.interruptions, _interruptions)&&(identical(other.interruptionSeconds, interruptionSeconds) || other.interruptionSeconds == interruptionSeconds)&&(identical(other.verifiedMinutes, verifiedMinutes) || other.verifiedMinutes == verifiedMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.potion, potion) || other.potion == potion)&&(identical(other.demo, demo) || other.demo == demo)&&(identical(other.processed, processed) || other.processed == processed)&&const DeepCollectionEquality().equals(other.summary, _summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,taskId,mode,startedAt,endedAt,const DeepCollectionEquality().hash(_interruptions),interruptionSeconds,verifiedMinutes,status,potion,demo,processed,const DeepCollectionEquality().hash(_summary));
}

@override
String toString() {
    return 'FocusSession(id: $id, userId: $userId, taskId: $taskId, mode: $mode, startedAt: $startedAt, endedAt: $endedAt, interruptions: $interruptions, interruptionSeconds: $interruptionSeconds, verifiedMinutes: $verifiedMinutes, status: $status, potion: $potion, demo: $demo, processed: $processed, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$FocusSessionCopyWith<$Res> implements $FocusSessionCopyWith<$Res> {
  factory _$FocusSessionCopyWith(_FocusSession value, $Res Function(_FocusSession) _then) = __$FocusSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String taskId, String mode, DateTime startedAt, DateTime? endedAt, List<dynamic> interruptions, int interruptionSeconds, int? verifiedMinutes, String status, bool potion, bool demo, bool processed, Map<String, dynamic>? summary
});




}
/// @nodoc
class __$FocusSessionCopyWithImpl<$Res>
    implements _$FocusSessionCopyWith<$Res> {
  __$FocusSessionCopyWithImpl(this._self, this._then);

  final _FocusSession _self;
  final $Res Function(_FocusSession) _then;

/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? taskId = null,Object? mode = null,Object? startedAt = null,Object? endedAt = freezed,Object? interruptions = null,Object? interruptionSeconds = null,Object? verifiedMinutes = freezed,Object? status = null,Object? potion = null,Object? demo = null,Object? processed = null,Object? summary = freezed,}) {
  return _then(_FocusSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,interruptions: null == interruptions ? _self._interruptions : interruptions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,interruptionSeconds: null == interruptionSeconds ? _self.interruptionSeconds : interruptionSeconds // ignore: cast_nullable_to_non_nullable
as int,verifiedMinutes: freezed == verifiedMinutes ? _self.verifiedMinutes : verifiedMinutes // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,potion: null == potion ? _self.potion : potion // ignore: cast_nullable_to_non_nullable
as bool,demo: null == demo ? _self.demo : demo // ignore: cast_nullable_to_non_nullable
as bool,processed: null == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as bool,summary: freezed == summary ? _self._summary : summary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
