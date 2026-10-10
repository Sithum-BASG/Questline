// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Guild _$GuildFromJson(Map<String, dynamic> json) => _Guild(
  id: json['id'] as String,
  name: json['name'] as String,
  emblem: json['emblem'] as String,
  leaderId: json['leader_id'] as String,
  inviteCode: json['invite_code'] as String,
  questWeekId: json['quest_week_id'] as String?,
  questGoal: (json['quest_goal'] as num).toInt(),
  questProgress: (json['quest_progress'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$GuildToJson(_Guild instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emblem': instance.emblem,
  'leader_id': instance.leaderId,
  'invite_code': instance.inviteCode,
  'quest_week_id': instance.questWeekId,
  'quest_goal': instance.questGoal,
  'quest_progress': instance.questProgress,
  'created_at': instance.createdAt.toIso8601String(),
};
