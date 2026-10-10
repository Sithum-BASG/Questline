// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raid_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RaidMember _$RaidMemberFromJson(Map<String, dynamic> json) => _RaidMember(
  raidId: json['raid_id'] as String,
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  skinId: json['skin_id'] as String?,
  frameId: json['frame_id'] as String?,
  bodyType: json['body_type'] as String?,
  titleId: json['title_id'] as String?,
  joinedAt: DateTime.parse(json['joined_at'] as String),
  leftRaid: json['left_raid'] as bool,
  metFairShare: json['met_fair_share'] as bool,
  isMvp: json['is_mvp'] as bool,
);

Map<String, dynamic> _$RaidMemberToJson(_RaidMember instance) =>
    <String, dynamic>{
      'raid_id': instance.raidId,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'skin_id': instance.skinId,
      'frame_id': instance.frameId,
      'body_type': instance.bodyType,
      'title_id': instance.titleId,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_raid': instance.leftRaid,
      'met_fair_share': instance.metFairShare,
      'is_mvp': instance.isMvp,
    };
