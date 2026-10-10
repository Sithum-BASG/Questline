// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raid.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Raid _$RaidFromJson(Map<String, dynamic> json) => _Raid(
  id: json['id'] as String,
  source: json['source'] as String,
  guildId: json['guild_id'] as String?,
  name: json['name'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  tier: json['tier'] as String,
  perPersonMinutes: (json['per_person_minutes'] as num).toInt(),
  participants: (json['participants'] as num).toInt(),
  maxHp: (json['max_hp'] as num).toInt(),
  damage: (json['damage'] as num).toInt(),
  deadline: DateTime.parse(json['deadline'] as String),
  status: json['status'] as String,
  createdBy: json['created_by'] as String?,
  inviteCode: json['invite_code'] as String?,
  coinsEligible: json['coins_eligible'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RaidToJson(_Raid instance) => <String, dynamic>{
  'id': instance.id,
  'source': instance.source,
  'guild_id': instance.guildId,
  'name': instance.name,
  'title': instance.title,
  'type': instance.type,
  'tier': instance.tier,
  'per_person_minutes': instance.perPersonMinutes,
  'participants': instance.participants,
  'max_hp': instance.maxHp,
  'damage': instance.damage,
  'deadline': instance.deadline.toIso8601String(),
  'status': instance.status,
  'created_by': instance.createdBy,
  'invite_code': instance.inviteCode,
  'coins_eligible': instance.coinsEligible,
  'created_at': instance.createdAt.toIso8601String(),
};
