// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuildMember _$GuildMemberFromJson(Map<String, dynamic> json) => _GuildMember(
  guildId: json['guild_id'] as String,
  userId: json['user_id'] as String,
  joinedAt: DateTime.parse(json['joined_at'] as String),
  questContribution: (json['quest_contribution'] as num).toInt(),
);

Map<String, dynamic> _$GuildMemberToJson(_GuildMember instance) =>
    <String, dynamic>{
      'guild_id': instance.guildId,
      'user_id': instance.userId,
      'joined_at': instance.joinedAt.toIso8601String(),
      'quest_contribution': instance.questContribution,
    };
