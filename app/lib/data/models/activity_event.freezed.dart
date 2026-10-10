// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityEvent {

 String get id; String get actorId; String get type; Map<String, dynamic> get payload; List<String> get visibleTo; DateTime get createdAt;
/// Create a copy of ActivityEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityEventCopyWith<ActivityEvent> get copyWith => _$ActivityEventCopyWithImpl<ActivityEvent>(this as ActivityEvent, _$identity);

  /// Serializes this ActivityEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActivityEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.actorId, _this.actorId) || other.actorId == _this.actorId)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&const DeepCollectionEquality().equals(other.visibleTo, _this.visibleTo)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActivityEvent;
  return Object.hash(runtimeType,_this.id,_this.actorId,_this.type,const DeepCollectionEquality().hash(_this.payload),const DeepCollectionEquality().hash(_this.visibleTo),_this.createdAt);
}

@override
String toString() {
  final _this = this as ActivityEvent;
  return 'ActivityEvent(id: ${_this.id}, actorId: ${_this.actorId}, type: ${_this.type}, payload: ${_this.payload}, visibleTo: ${_this.visibleTo}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ActivityEventCopyWith<$Res>  {
  factory $ActivityEventCopyWith(ActivityEvent value, $Res Function(ActivityEvent) _then) = _$ActivityEventCopyWithImpl;
@useResult
$Res call({
 String id, String actorId, String type, Map<String, dynamic> payload, List<String> visibleTo, DateTime createdAt
});




}
/// @nodoc
class _$ActivityEventCopyWithImpl<$Res>
    implements $ActivityEventCopyWith<$Res> {
  _$ActivityEventCopyWithImpl(this._self, this._then);

  final ActivityEvent _self;
  final $Res Function(ActivityEvent) _then;

/// Create a copy of ActivityEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? actorId = null,Object? type = null,Object? payload = null,Object? visibleTo = null,Object? createdAt = null,}) {
  return _then(ActivityEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,visibleTo: null == visibleTo ? _self.visibleTo : visibleTo // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityEvent].
extension ActivityEventPatterns on ActivityEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityEvent value)  $default,){
final _that = this;
switch (_that) {
case _ActivityEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String actorId,  String type,  Map<String, dynamic> payload,  List<String> visibleTo,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityEvent() when $default != null:
return $default(_that.id,_that.actorId,_that.type,_that.payload,_that.visibleTo,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String actorId,  String type,  Map<String, dynamic> payload,  List<String> visibleTo,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityEvent():
return $default(_that.id,_that.actorId,_that.type,_that.payload,_that.visibleTo,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String actorId,  String type,  Map<String, dynamic> payload,  List<String> visibleTo,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityEvent() when $default != null:
return $default(_that.id,_that.actorId,_that.type,_that.payload,_that.visibleTo,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityEvent implements ActivityEvent {
  const _ActivityEvent({required this.id, required this.actorId, required this.type, required  Map<String, dynamic> payload, required  List<String> visibleTo, required this.createdAt}): _payload = payload,_visibleTo = visibleTo;
  factory _ActivityEvent.fromJson(Map<String, dynamic> json) => _$ActivityEventFromJson(json);

@override final  String id;
@override final  String actorId;
@override final  String type;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

 final  List<String> _visibleTo;
@override List<String> get visibleTo {
  if (_visibleTo is EqualUnmodifiableListView) return _visibleTo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleTo);
}

@override final  DateTime createdAt;

/// Create a copy of ActivityEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityEventCopyWith<_ActivityEvent> get copyWith => __$ActivityEventCopyWithImpl<_ActivityEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, _payload)&&const DeepCollectionEquality().equals(other.visibleTo, _visibleTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,actorId,type,const DeepCollectionEquality().hash(_payload),const DeepCollectionEquality().hash(_visibleTo),createdAt);
}

@override
String toString() {
    return 'ActivityEvent(id: $id, actorId: $actorId, type: $type, payload: $payload, visibleTo: $visibleTo, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityEventCopyWith<$Res> implements $ActivityEventCopyWith<$Res> {
  factory _$ActivityEventCopyWith(_ActivityEvent value, $Res Function(_ActivityEvent) _then) = __$ActivityEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String actorId, String type, Map<String, dynamic> payload, List<String> visibleTo, DateTime createdAt
});




}
/// @nodoc
class __$ActivityEventCopyWithImpl<$Res>
    implements _$ActivityEventCopyWith<$Res> {
  __$ActivityEventCopyWithImpl(this._self, this._then);

  final _ActivityEvent _self;
  final $Res Function(_ActivityEvent) _then;

/// Create a copy of ActivityEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? actorId = null,Object? type = null,Object? payload = null,Object? visibleTo = null,Object? createdAt = null,}) {
  return _then(_ActivityEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,visibleTo: null == visibleTo ? _self._visibleTo : visibleTo // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
