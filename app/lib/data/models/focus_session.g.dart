// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FocusSession _$FocusSessionFromJson(Map<String, dynamic> json) =>
    _FocusSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      mode: json['mode'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      interruptions: json['interruptions'] as List<dynamic>,
      interruptionSeconds: (json['interruption_seconds'] as num).toInt(),
      verifiedMinutes: (json['verified_minutes'] as num?)?.toInt(),
      status: json['status'] as String,
      potion: json['potion'] as bool,
      demo: json['demo'] as bool,
      processed: json['processed'] as bool,
      summary: json['summary'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FocusSessionToJson(_FocusSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'task_id': instance.taskId,
      'mode': instance.mode,
      'started_at': instance.startedAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'interruptions': instance.interruptions,
      'interruption_seconds': instance.interruptionSeconds,
      'verified_minutes': instance.verifiedMinutes,
      'status': instance.status,
      'potion': instance.potion,
      'demo': instance.demo,
      'processed': instance.processed,
      'summary': instance.summary,
    };
