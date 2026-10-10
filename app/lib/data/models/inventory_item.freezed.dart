// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryItem {

 String get userId; String get catalogId; DateTime get acquiredAt; String get source; String? get attunedStat; String? get equippedSlot;
/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryItemCopyWith<InventoryItem> get copyWith => _$InventoryItemCopyWithImpl<InventoryItem>(this as InventoryItem, _$identity);

  /// Serializes this InventoryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InventoryItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryItem&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.catalogId, _this.catalogId) || other.catalogId == _this.catalogId)&&(identical(other.acquiredAt, _this.acquiredAt) || other.acquiredAt == _this.acquiredAt)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.attunedStat, _this.attunedStat) || other.attunedStat == _this.attunedStat)&&(identical(other.equippedSlot, _this.equippedSlot) || other.equippedSlot == _this.equippedSlot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InventoryItem;
  return Object.hash(runtimeType,_this.userId,_this.catalogId,_this.acquiredAt,_this.source,_this.attunedStat,_this.equippedSlot);
}

@override
String toString() {
  final _this = this as InventoryItem;
  return 'InventoryItem(userId: ${_this.userId}, catalogId: ${_this.catalogId}, acquiredAt: ${_this.acquiredAt}, source: ${_this.source}, attunedStat: ${_this.attunedStat}, equippedSlot: ${_this.equippedSlot})';
}


}

/// @nodoc
abstract mixin class $InventoryItemCopyWith<$Res>  {
  factory $InventoryItemCopyWith(InventoryItem value, $Res Function(InventoryItem) _then) = _$InventoryItemCopyWithImpl;
@useResult
$Res call({
 String userId, String catalogId, DateTime acquiredAt, String source, String? attunedStat, String? equippedSlot
});




}
/// @nodoc
class _$InventoryItemCopyWithImpl<$Res>
    implements $InventoryItemCopyWith<$Res> {
  _$InventoryItemCopyWithImpl(this._self, this._then);

  final InventoryItem _self;
  final $Res Function(InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? catalogId = null,Object? acquiredAt = null,Object? source = null,Object? attunedStat = freezed,Object? equippedSlot = freezed,}) {
  return _then(InventoryItem(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,catalogId: null == catalogId ? _self.catalogId : catalogId // ignore: cast_nullable_to_non_nullable
as String,acquiredAt: null == acquiredAt ? _self.acquiredAt : acquiredAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,attunedStat: freezed == attunedStat ? _self.attunedStat : attunedStat // ignore: cast_nullable_to_non_nullable
as String?,equippedSlot: freezed == equippedSlot ? _self.equippedSlot : equippedSlot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryItem].
extension InventoryItemPatterns on InventoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryItem value)  $default,){
final _that = this;
switch (_that) {
case _InventoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String catalogId,  DateTime acquiredAt,  String source,  String? attunedStat,  String? equippedSlot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
return $default(_that.userId,_that.catalogId,_that.acquiredAt,_that.source,_that.attunedStat,_that.equippedSlot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String catalogId,  DateTime acquiredAt,  String source,  String? attunedStat,  String? equippedSlot)  $default,) {final _that = this;
switch (_that) {
case _InventoryItem():
return $default(_that.userId,_that.catalogId,_that.acquiredAt,_that.source,_that.attunedStat,_that.equippedSlot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String catalogId,  DateTime acquiredAt,  String source,  String? attunedStat,  String? equippedSlot)?  $default,) {final _that = this;
switch (_that) {
case _InventoryItem() when $default != null:
return $default(_that.userId,_that.catalogId,_that.acquiredAt,_that.source,_that.attunedStat,_that.equippedSlot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InventoryItem implements InventoryItem {
  const _InventoryItem({required this.userId, required this.catalogId, required this.acquiredAt, required this.source, this.attunedStat, this.equippedSlot});
  factory _InventoryItem.fromJson(Map<String, dynamic> json) => _$InventoryItemFromJson(json);

@override final  String userId;
@override final  String catalogId;
@override final  DateTime acquiredAt;
@override final  String source;
@override final  String? attunedStat;
@override final  String? equippedSlot;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryItemCopyWith<_InventoryItem> get copyWith => __$InventoryItemCopyWithImpl<_InventoryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InventoryItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryItem&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.catalogId, catalogId) || other.catalogId == catalogId)&&(identical(other.acquiredAt, acquiredAt) || other.acquiredAt == acquiredAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.attunedStat, attunedStat) || other.attunedStat == attunedStat)&&(identical(other.equippedSlot, equippedSlot) || other.equippedSlot == equippedSlot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,catalogId,acquiredAt,source,attunedStat,equippedSlot);
}

@override
String toString() {
    return 'InventoryItem(userId: $userId, catalogId: $catalogId, acquiredAt: $acquiredAt, source: $source, attunedStat: $attunedStat, equippedSlot: $equippedSlot)';
}


}

/// @nodoc
abstract mixin class _$InventoryItemCopyWith<$Res> implements $InventoryItemCopyWith<$Res> {
  factory _$InventoryItemCopyWith(_InventoryItem value, $Res Function(_InventoryItem) _then) = __$InventoryItemCopyWithImpl;
@override @useResult
$Res call({
 String userId, String catalogId, DateTime acquiredAt, String source, String? attunedStat, String? equippedSlot
});




}
/// @nodoc
class __$InventoryItemCopyWithImpl<$Res>
    implements _$InventoryItemCopyWith<$Res> {
  __$InventoryItemCopyWithImpl(this._self, this._then);

  final _InventoryItem _self;
  final $Res Function(_InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? catalogId = null,Object? acquiredAt = null,Object? source = null,Object? attunedStat = freezed,Object? equippedSlot = freezed,}) {
  return _then(_InventoryItem(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,catalogId: null == catalogId ? _self.catalogId : catalogId // ignore: cast_nullable_to_non_nullable
as String,acquiredAt: null == acquiredAt ? _self.acquiredAt : acquiredAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,attunedStat: freezed == attunedStat ? _self.attunedStat : attunedStat // ignore: cast_nullable_to_non_nullable
as String?,equippedSlot: freezed == equippedSlot ? _self.equippedSlot : equippedSlot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
