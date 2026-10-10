// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FriendSummary _$FriendSummaryFromJson(Map<String, dynamic> json) =>
    _FriendSummary(
      userId: json['user_id'] as String,
      equippedGear: json['equipped_gear'] as List<dynamic>,
      weeklyRawXp: (json['weekly_raw_xp'] as num).toInt(),
      radar30: json['radar30'] as Map<String, dynamic>?,
      radar7: json['radar7'] as Map<String, dynamic>?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FriendSummaryToJson(_FriendSummary instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'equipped_gear': instance.equippedGear,
      'weekly_raw_xp': instance.weeklyRawXp,
      'radar30': instance.radar30,
      'radar7': instance.radar7,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
