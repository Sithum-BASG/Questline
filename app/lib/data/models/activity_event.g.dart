// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityEvent _$ActivityEventFromJson(Map<String, dynamic> json) =>
    _ActivityEvent(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      visibleTo: (json['visible_to'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActivityEventToJson(_ActivityEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'actor_id': instance.actorId,
      'type': instance.type,
      'payload': instance.payload,
      'visible_to': instance.visibleTo,
      'created_at': instance.createdAt.toIso8601String(),
    };
