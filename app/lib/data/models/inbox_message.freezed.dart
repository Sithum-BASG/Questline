// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InboxMessage {

 String get id; String get userId; String get type; Map<String, dynamic> get payload; DateTime get createdAt; DateTime? get readAt;
/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxMessageCopyWith<InboxMessage> get copyWith => _$InboxMessageCopyWithImpl<InboxMessage>(this as InboxMessage, _$identity);

  /// Serializes this InboxMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboxMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboxMessage;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.type,const DeepCollectionEquality().hash(_this.payload),_this.createdAt,_this.readAt);
}

@override
String toString() {
  final _this = this as InboxMessage;
  return 'InboxMessage(id: ${_this.id}, userId: ${_this.userId}, type: ${_this.type}, payload: ${_this.payload}, createdAt: ${_this.createdAt}, readAt: ${_this.readAt})';
}


}

/// @nodoc
abstract mixin class $InboxMessageCopyWith<$Res>  {
  factory $InboxMessageCopyWith(InboxMessage value, $Res Function(InboxMessage) _then) = _$InboxMessageCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String type, Map<String, dynamic> payload, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class _$InboxMessageCopyWithImpl<$Res>
    implements $InboxMessageCopyWith<$Res> {
  _$InboxMessageCopyWithImpl(this._self, this._then);

  final InboxMessage _self;
  final $Res Function(InboxMessage) _then;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(InboxMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxMessage].
extension InboxMessagePatterns on InboxMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxMessage value)  $default,){
final _that = this;
switch (_that) {
case _InboxMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxMessage value)?  $default,){
final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  Map<String, dynamic> payload,  DateTime createdAt,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.payload,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  Map<String, dynamic> payload,  DateTime createdAt,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _InboxMessage():
return $default(_that.id,_that.userId,_that.type,_that.payload,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String type,  Map<String, dynamic> payload,  DateTime createdAt,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.payload,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxMessage implements InboxMessage {
  const _InboxMessage({required this.id, required this.userId, required this.type, required  Map<String, dynamic> payload, required this.createdAt, this.readAt}): _payload = payload;
  factory _InboxMessage.fromJson(Map<String, dynamic> json) => _$InboxMessageFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String type;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  DateTime createdAt;
@override final  DateTime? readAt;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxMessageCopyWith<_InboxMessage> get copyWith => __$InboxMessageCopyWithImpl<_InboxMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,type,const DeepCollectionEquality().hash(_payload),createdAt,readAt);
}

@override
String toString() {
    return 'InboxMessage(id: $id, userId: $userId, type: $type, payload: $payload, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$InboxMessageCopyWith<$Res> implements $InboxMessageCopyWith<$Res> {
  factory _$InboxMessageCopyWith(_InboxMessage value, $Res Function(_InboxMessage) _then) = __$InboxMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String type, Map<String, dynamic> payload, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class __$InboxMessageCopyWithImpl<$Res>
    implements _$InboxMessageCopyWith<$Res> {
  __$InboxMessageCopyWithImpl(this._self, this._then);

  final _InboxMessage _self;
  final $Res Function(_InboxMessage) _then;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_InboxMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
