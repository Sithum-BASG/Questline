// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyScore _$WeeklyScoreFromJson(Map<String, dynamic> json) => _WeeklyScore(
  weekId: json['week_id'] as String,
  userId: json['user_id'] as String,
  rawXp: (json['raw_xp'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WeeklyScoreToJson(_WeeklyScore instance) =>
    <String, dynamic>{
      'week_id': instance.weekId,
      'user_id': instance.userId,
      'raw_xp': instance.rawXp,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
