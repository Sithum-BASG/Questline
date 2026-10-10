// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LevelReward _$LevelRewardFromJson(Map<String, dynamic> json) => _LevelReward(
  level: (json['level'] as num).toInt(),
  rewards: (json['rewards'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$LevelRewardToJson(_LevelReward instance) =>
    <String, dynamic>{'level': instance.level, 'rewards': instance.rewards};
