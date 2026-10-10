// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_trophy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuildTrophy _$GuildTrophyFromJson(Map<String, dynamic> json) => _GuildTrophy(
  guildId: json['guild_id'] as String,
  raidId: json['raid_id'] as String,
  name: json['name'] as String?,
  wonAt: json['won_at'] == null
      ? null
      : DateTime.parse(json['won_at'] as String),
);

Map<String, dynamic> _$GuildTrophyToJson(_GuildTrophy instance) =>
    <String, dynamic>{
      'guild_id': instance.guildId,
      'raid_id': instance.raidId,
      'name': instance.name,
      'won_at': instance.wonAt?.toIso8601String(),
    };
