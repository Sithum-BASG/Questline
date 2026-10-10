// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InboxMessage _$InboxMessageFromJson(Map<String, dynamic> json) =>
    _InboxMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$InboxMessageToJson(_InboxMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'payload': instance.payload,
      'created_at': instance.createdAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
    };
