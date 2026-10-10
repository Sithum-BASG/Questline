// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Presence _$PresenceFromJson(Map<String, dynamic> json) => _Presence(
  userId: json['user_id'] as String,
  state: json['state'] as String,
  stat: json['stat'] as String?,
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  raidId: json['raid_id'] as String?,
  lastSeen: DateTime.parse(json['last_seen'] as String),
);

Map<String, dynamic> _$PresenceToJson(_Presence instance) => <String, dynamic>{
  'user_id': instance.userId,
  'state': instance.state,
  'stat': instance.stat,
  'started_at': instance.startedAt?.toIso8601String(),
  'raid_id': instance.raidId,
  'last_seen': instance.lastSeen.toIso8601String(),
};
