// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Friendship _$FriendshipFromJson(Map<String, dynamic> json) => _Friendship(
  userId: json['user_id'] as String,
  friendId: json['friend_id'] as String,
  status: json['status'] as String,
  since: DateTime.parse(json['since'] as String),
);

Map<String, dynamic> _$FriendshipToJson(_Friendship instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'friend_id': instance.friendId,
      'status': instance.status,
      'since': instance.since.toIso8601String(),
    };
