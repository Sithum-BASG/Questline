// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Achievement _$AchievementFromJson(Map<String, dynamic> json) => _Achievement(
  userId: json['user_id'] as String,
  badgeId: json['badge_id'] as String,
  progress: (json['progress'] as num).toInt(),
  tier: (json['tier'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AchievementToJson(_Achievement instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'badge_id': instance.badgeId,
      'progress': instance.progress,
      'tier': instance.tier,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
