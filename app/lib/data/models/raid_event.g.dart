// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raid_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RaidEvent _$RaidEventFromJson(Map<String, dynamic> json) => _RaidEvent(
  id: (json['id'] as num).toInt(),
  raidId: json['raid_id'] as String,
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  amount: (json['amount'] as num).toInt(),
  at: DateTime.parse(json['at'] as String),
);

Map<String, dynamic> _$RaidEventToJson(_RaidEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'raid_id': instance.raidId,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'amount': instance.amount,
      'at': instance.at.toIso8601String(),
    };
