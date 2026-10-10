import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_item.freezed.dart';
part 'inventory_item.g.dart';

@freezed
abstract class InventoryItem with _$InventoryItem {
  const factory InventoryItem({
    required String userId,
    required String catalogId,
    required DateTime acquiredAt,
    required String source,
    String? attunedStat,
    String? equippedSlot,
  }) = _InventoryItem;

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
}
