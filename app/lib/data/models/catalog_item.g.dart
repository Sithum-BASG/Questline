// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogItem _$CatalogItemFromJson(Map<String, dynamic> json) => _CatalogItem(
  id: json['id'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
  rarity: json['rarity'] as String?,
  source: json['source'] as String,
  level: (json['level'] as num?)?.toInt(),
  slot: json['slot'] as String?,
  boost: (json['boost'] as num?)?.toDouble(),
  passive: json['passive'] as String?,
  setId: json['set_id'] as String?,
  assets: json['assets'] as Map<String, dynamic>,
);

Map<String, dynamic> _$CatalogItemToJson(_CatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'rarity': instance.rarity,
      'source': instance.source,
      'level': instance.level,
      'slot': instance.slot,
      'boost': instance.boost,
      'passive': instance.passive,
      'set_id': instance.setId,
      'assets': instance.assets,
    };
