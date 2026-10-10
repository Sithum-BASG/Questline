// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyStat _$DailyStatFromJson(Map<String, dynamic> json) => _DailyStat(
  userId: json['user_id'] as String,
  day: DateTime.parse(json['day'] as String),
  xpIntellect: (json['xp_intellect'] as num).toInt(),
  xpVitality: (json['xp_vitality'] as num).toInt(),
  xpCraft: (json['xp_craft'] as num).toInt(),
  xpCharisma: (json['xp_charisma'] as num).toInt(),
  rawXp: (json['raw_xp'] as num).toInt(),
  focusMinutes: (json['focus_minutes'] as num).toInt(),
  sessionsStarted: (json['sessions_started'] as num).toInt(),
  metMinimum: json['met_minimum'] as bool,
  restDay: json['rest_day'] as bool,
  paused: json['paused'] as bool,
);

Map<String, dynamic> _$DailyStatToJson(_DailyStat instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'day': instance.day.toIso8601String(),
      'xp_intellect': instance.xpIntellect,
      'xp_vitality': instance.xpVitality,
      'xp_craft': instance.xpCraft,
      'xp_charisma': instance.xpCharisma,
      'raw_xp': instance.rawXp,
      'focus_minutes': instance.focusMinutes,
      'sessions_started': instance.sessionsStarted,
      'met_minimum': instance.metMinimum,
      'rest_day': instance.restDay,
      'paused': instance.paused,
    };
