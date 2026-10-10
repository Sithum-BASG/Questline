// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogItem {

 String get id; String get type; String get name; String? get rarity; String get source; int? get level; String? get slot; double? get boost; String? get passive; String? get setId; Map<String, dynamic> get assets;
/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogItemCopyWith<CatalogItem> get copyWith => _$CatalogItemCopyWithImpl<CatalogItem>(this as CatalogItem, _$identity);

  /// Serializes this CatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatalogItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.rarity, _this.rarity) || other.rarity == _this.rarity)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.boost, _this.boost) || other.boost == _this.boost)&&(identical(other.passive, _this.passive) || other.passive == _this.passive)&&(identical(other.setId, _this.setId) || other.setId == _this.setId)&&const DeepCollectionEquality().equals(other.assets, _this.assets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatalogItem;
  return Object.hash(runtimeType,_this.id,_this.type,_this.name,_this.rarity,_this.source,_this.level,_this.slot,_this.boost,_this.passive,_this.setId,const DeepCollectionEquality().hash(_this.assets));
}

@override
String toString() {
  final _this = this as CatalogItem;
  return 'CatalogItem(id: ${_this.id}, type: ${_this.type}, name: ${_this.name}, rarity: ${_this.rarity}, source: ${_this.source}, level: ${_this.level}, slot: ${_this.slot}, boost: ${_this.boost}, passive: ${_this.passive}, setId: ${_this.setId}, assets: ${_this.assets})';
}


}

/// @nodoc
abstract mixin class $CatalogItemCopyWith<$Res>  {
  factory $CatalogItemCopyWith(CatalogItem value, $Res Function(CatalogItem) _then) = _$CatalogItemCopyWithImpl;
@useResult
$Res call({
 String id, String type, String name, String? rarity, String source, int? level, String? slot, double? boost, String? passive, String? setId, Map<String, dynamic> assets
});




}
/// @nodoc
class _$CatalogItemCopyWithImpl<$Res>
    implements $CatalogItemCopyWith<$Res> {
  _$CatalogItemCopyWithImpl(this._self, this._then);

  final CatalogItem _self;
  final $Res Function(CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? rarity = freezed,Object? source = null,Object? level = freezed,Object? slot = freezed,Object? boost = freezed,Object? passive = freezed,Object? setId = freezed,Object? assets = null,}) {
  return _then(CatalogItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rarity: freezed == rarity ? _self.rarity : rarity // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,boost: freezed == boost ? _self.boost : boost // ignore: cast_nullable_to_non_nullable
as double?,passive: freezed == passive ? _self.passive : passive // ignore: cast_nullable_to_non_nullable
as String?,setId: freezed == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String?,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogItem].
extension CatalogItemPatterns on CatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String name,  String? rarity,  String source,  int? level,  String? slot,  double? boost,  String? passive,  String? setId,  Map<String, dynamic> assets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.rarity,_that.source,_that.level,_that.slot,_that.boost,_that.passive,_that.setId,_that.assets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String name,  String? rarity,  String source,  int? level,  String? slot,  double? boost,  String? passive,  String? setId,  Map<String, dynamic> assets)  $default,) {final _that = this;
switch (_that) {
case _CatalogItem():
return $default(_that.id,_that.type,_that.name,_that.rarity,_that.source,_that.level,_that.slot,_that.boost,_that.passive,_that.setId,_that.assets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String name,  String? rarity,  String source,  int? level,  String? slot,  double? boost,  String? passive,  String? setId,  Map<String, dynamic> assets)?  $default,) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.rarity,_that.source,_that.level,_that.slot,_that.boost,_that.passive,_that.setId,_that.assets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogItem implements CatalogItem {
  const _CatalogItem({required this.id, required this.type, required this.name, this.rarity, required this.source, this.level, this.slot, this.boost, this.passive, this.setId, required  Map<String, dynamic> assets}): _assets = assets;
  factory _CatalogItem.fromJson(Map<String, dynamic> json) => _$CatalogItemFromJson(json);

@override final  String id;
@override final  String type;
@override final  String name;
@override final  String? rarity;
@override final  String source;
@override final  int? level;
@override final  String? slot;
@override final  double? boost;
@override final  String? passive;
@override final  String? setId;
 final  Map<String, dynamic> _assets;
@override Map<String, dynamic> get assets {
  if (_assets is EqualUnmodifiableMapView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_assets);
}


/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogItemCopyWith<_CatalogItem> get copyWith => __$CatalogItemCopyWithImpl<_CatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogItem&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.rarity, rarity) || other.rarity == rarity)&&(identical(other.source, source) || other.source == source)&&(identical(other.level, level) || other.level == level)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.boost, boost) || other.boost == boost)&&(identical(other.passive, passive) || other.passive == passive)&&(identical(other.setId, setId) || other.setId == setId)&&const DeepCollectionEquality().equals(other.assets, _assets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,name,rarity,source,level,slot,boost,passive,setId,const DeepCollectionEquality().hash(_assets));
}

@override
String toString() {
    return 'CatalogItem(id: $id, type: $type, name: $name, rarity: $rarity, source: $source, level: $level, slot: $slot, boost: $boost, passive: $passive, setId: $setId, assets: $assets)';
}


}

/// @nodoc
abstract mixin class _$CatalogItemCopyWith<$Res> implements $CatalogItemCopyWith<$Res> {
  factory _$CatalogItemCopyWith(_CatalogItem value, $Res Function(_CatalogItem) _then) = __$CatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String name, String? rarity, String source, int? level, String? slot, double? boost, String? passive, String? setId, Map<String, dynamic> assets
});




}
/// @nodoc
class __$CatalogItemCopyWithImpl<$Res>
    implements _$CatalogItemCopyWith<$Res> {
  __$CatalogItemCopyWithImpl(this._self, this._then);

  final _CatalogItem _self;
  final $Res Function(_CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? rarity = freezed,Object? source = null,Object? level = freezed,Object? slot = freezed,Object? boost = freezed,Object? passive = freezed,Object? setId = freezed,Object? assets = null,}) {
  return _then(_CatalogItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rarity: freezed == rarity ? _self.rarity : rarity // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,boost: freezed == boost ? _self.boost : boost // ignore: cast_nullable_to_non_nullable
as double?,passive: freezed == passive ? _self.passive : passive // ignore: cast_nullable_to_non_nullable
as String?,setId: freezed == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String?,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
