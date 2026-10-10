// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) =>
    _UserSettings(
      userId: json['user_id'] as String,
      notifBosses: json['notif_bosses'] as bool,
      notifStreak: json['notif_streak'] as bool,
      notifRaids: json['notif_raids'] as bool,
      notifWeekly: json['notif_weekly'] as bool,
      notifLeaderboardNudge: json['notif_leaderboard_nudge'] as bool,
      quietStart: json['quiet_start'] as String,
      quietEnd: json['quiet_end'] as String,
      appearOffline: json['appear_offline'] as bool,
      studyContext: json['study_context'] as String?,
      demoMode: json['demo_mode'] as bool,
    );

Map<String, dynamic> _$UserSettingsToJson(_UserSettings instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'notif_bosses': instance.notifBosses,
      'notif_streak': instance.notifStreak,
      'notif_raids': instance.notifRaids,
      'notif_weekly': instance.notifWeekly,
      'notif_leaderboard_nudge': instance.notifLeaderboardNudge,
      'quiet_start': instance.quietStart,
      'quiet_end': instance.quietEnd,
      'appear_offline': instance.appearOffline,
      'study_context': instance.studyContext,
      'demo_mode': instance.demoMode,
    };
