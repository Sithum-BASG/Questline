// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  notes: json['notes'] as String?,
  dueAt: json['due_at'] == null
      ? null
      : DateTime.parse(json['due_at'] as String),
  originalDueAt: json['original_due_at'] == null
      ? null
      : DateTime.parse(json['original_due_at'] as String),
  bossId: json['boss_id'] as String?,
  raidId: json['raid_id'] as String?,
  status: json['status'] as String,
  rescheduled: json['rescheduled'] as bool,
  scrollUsed: json['scroll_used'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  stat: json['stat'] as String?,
  difficulty: (json['difficulty'] as num?)?.toInt(),
  estMinutes: (json['est_minutes'] as num?)?.toInt(),
  tooBig: json['too_big'] as bool?,
  reason: json['reason'] as String?,
  provisional: json['provisional'] as bool,
  challenged: json['challenged'] as bool,
  judgedAt: json['judged_at'] == null
      ? null
      : DateTime.parse(json['judged_at'] as String),
  completionMode: json['completion_mode'] as String?,
  completionMinutes: (json['completion_minutes'] as num?)?.toInt(),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  completionDay: json['completion_day'] == null
      ? null
      : DateTime.parse(json['completion_day'] as String),
  xpRaw: (json['xp_raw'] as num?)?.toInt(),
  xpFinal: (json['xp_final'] as num?)?.toInt(),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'notes': instance.notes,
  'due_at': instance.dueAt?.toIso8601String(),
  'original_due_at': instance.originalDueAt?.toIso8601String(),
  'boss_id': instance.bossId,
  'raid_id': instance.raidId,
  'status': instance.status,
  'rescheduled': instance.rescheduled,
  'scroll_used': instance.scrollUsed,
  'created_at': instance.createdAt.toIso8601String(),
  'stat': instance.stat,
  'difficulty': instance.difficulty,
  'est_minutes': instance.estMinutes,
  'too_big': instance.tooBig,
  'reason': instance.reason,
  'provisional': instance.provisional,
  'challenged': instance.challenged,
  'judged_at': instance.judgedAt?.toIso8601String(),
  'completion_mode': instance.completionMode,
  'completion_minutes': instance.completionMinutes,
  'completed_at': instance.completedAt?.toIso8601String(),
  'completion_day': instance.completionDay?.toIso8601String(),
  'xp_raw': instance.xpRaw,
  'xp_final': instance.xpFinal,
};
