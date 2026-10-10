// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raid_damage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RaidDamage _$RaidDamageFromJson(Map<String, dynamic> json) => _RaidDamage(
  raidId: json['raid_id'] as String,
  userId: json['user_id'] as String,
  damage: (json['damage'] as num).toInt(),
);

Map<String, dynamic> _$RaidDamageToJson(_RaidDamage instance) =>
    <String, dynamic>{
      'raid_id': instance.raidId,
      'user_id': instance.userId,
      'damage': instance.damage,
    };
