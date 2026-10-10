// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boss.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Boss _$BossFromJson(Map<String, dynamic> json) => _Boss(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  tier: json['tier'] as String,
  hours: (json['hours'] as num).toDouble(),
  maxHp: (json['max_hp'] as num).toInt(),
  damage: (json['damage'] as num).toInt(),
  deadline: DateTime.parse(json['deadline'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  status: json['status'] as String,
  lastWorkDay: json['last_work_day'] == null
      ? null
      : DateTime.parse(json['last_work_day'] as String),
  coinsEligible: json['coins_eligible'] as bool,
  loot: json['loot'] as Map<String, dynamic>?,
  resultSeen: json['result_seen'] as bool,
);

Map<String, dynamic> _$BossToJson(_Boss instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'title': instance.title,
  'type': instance.type,
  'tier': instance.tier,
  'hours': instance.hours,
  'max_hp': instance.maxHp,
  'damage': instance.damage,
  'deadline': instance.deadline.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'status': instance.status,
  'last_work_day': instance.lastWorkDay?.toIso8601String(),
  'coins_eligible': instance.coinsEligible,
  'loot': instance.loot,
  'result_seen': instance.resultSeen,
};
