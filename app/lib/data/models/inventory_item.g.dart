// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    _InventoryItem(
      userId: json['user_id'] as String,
      catalogId: json['catalog_id'] as String,
      acquiredAt: DateTime.parse(json['acquired_at'] as String),
      source: json['source'] as String,
      attunedStat: json['attuned_stat'] as String?,
      equippedSlot: json['equipped_slot'] as String?,
    );

Map<String, dynamic> _$InventoryItemToJson(_InventoryItem instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'catalog_id': instance.catalogId,
      'acquired_at': instance.acquiredAt.toIso8601String(),
      'source': instance.source,
      'attuned_stat': instance.attunedStat,
      'equipped_slot': instance.equippedSlot,
    };
