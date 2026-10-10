// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String,
  friendCode: json['friend_code'] as String,
  displayName: json['display_name'] as String,
  bodyType: json['body_type'] as String,
  level: (json['level'] as num).toInt(),
  titleId: json['title_id'] as String?,
  equippedSkinId: json['equipped_skin_id'] as String,
  equippedBackgroundId: json['equipped_background_id'] as String,
  equippedFrameId: json['equipped_frame_id'] as String,
  pinnedBadges: (json['pinned_badges'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  guildId: json['guild_id'] as String?,
  hideRadar: json['hide_radar'] as bool,
  showBossNames: json['show_boss_names'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'friend_code': instance.friendCode,
  'display_name': instance.displayName,
  'body_type': instance.bodyType,
  'level': instance.level,
  'title_id': instance.titleId,
  'equipped_skin_id': instance.equippedSkinId,
  'equipped_background_id': instance.equippedBackgroundId,
  'equipped_frame_id': instance.equippedFrameId,
  'pinned_badges': instance.pinnedBadges,
  'guild_id': instance.guildId,
  'hide_radar': instance.hideRadar,
  'show_boss_names': instance.showBossNames,
  'created_at': instance.createdAt.toIso8601String(),
};
