// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) => _PlayerState(
  userId: json['user_id'] as String,
  coins: (json['coins'] as num).toInt(),
  xpTotal: (json['xp_total'] as num).toInt(),
  weeklyRawXp: (json['weekly_raw_xp'] as num).toInt(),
  weekId: json['week_id'] as String,
  streakCount: (json['streak_count'] as num).toInt(),
  streakLastCountedDay: json['streak_last_counted_day'] == null
      ? null
      : DateTime.parse(json['streak_last_counted_day'] as String),
  streakBest: (json['streak_best'] as num).toInt(),
  shields: (json['shields'] as num).toInt(),
  lastShieldDay: json['last_shield_day'] == null
      ? null
      : DateTime.parse(json['last_shield_day'] as String),
  potions: (json['potions'] as num).toInt(),
  scrolls: (json['scrolls'] as num).toInt(),
  freeChests: (json['free_chests'] as num).toInt(),
  activePotion: json['active_potion'] as bool,
  comebackArmed: json['comeback_armed'] as bool,
  inactiveDays: (json['inactive_days'] as num).toInt(),
  chestsSinceLegendary: (json['chests_since_legendary'] as num).toInt(),
  bossCoinsThisWeek: (json['boss_coins_this_week'] as num).toInt(),
  aiCallsToday: (json['ai_calls_today'] as num).toInt(),
  focusMinutesToday: (json['focus_minutes_today'] as num).toInt(),
  onboardingStep: json['onboarding_step'] as String,
  onboardingBonus: json['onboarding_bonus'] as Map<String, dynamic>,
  ownedTitles: (json['owned_titles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  counters: json['counters'] as Map<String, dynamic>,
  milestonesPaid: (json['milestones_paid'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  timezone: json['timezone'] as String,
  lastActiveDay: json['last_active_day'] == null
      ? null
      : DateTime.parse(json['last_active_day'] as String),
  nextRolloverAt: DateTime.parse(json['next_rollover_at'] as String),
  restWeekday: (json['rest_weekday'] as num?)?.toInt(),
  pendingRestWeekday: (json['pending_rest_weekday'] as num?)?.toInt(),
  pauseActive: json['pause_active'] as bool,
  pauseUntil: json['pause_until'] == null
      ? null
      : DateTime.parse(json['pause_until'] as String),
  pauseDaysUsed: (json['pause_days_used'] as num).toInt(),
  pauseMonth: json['pause_month'] as String?,
);

Map<String, dynamic> _$PlayerStateToJson(
  _PlayerState instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'coins': instance.coins,
  'xp_total': instance.xpTotal,
  'weekly_raw_xp': instance.weeklyRawXp,
  'week_id': instance.weekId,
  'streak_count': instance.streakCount,
  'streak_last_counted_day': instance.streakLastCountedDay?.toIso8601String(),
  'streak_best': instance.streakBest,
  'shields': instance.shields,
  'last_shield_day': instance.lastShieldDay?.toIso8601String(),
  'potions': instance.potions,
  'scrolls': instance.scrolls,
  'free_chests': instance.freeChests,
  'active_potion': instance.activePotion,
  'comeback_armed': instance.comebackArmed,
  'inactive_days': instance.inactiveDays,
  'chests_since_legendary': instance.chestsSinceLegendary,
  'boss_coins_this_week': instance.bossCoinsThisWeek,
  'ai_calls_today': instance.aiCallsToday,
  'focus_minutes_today': instance.focusMinutesToday,
  'onboarding_step': instance.onboardingStep,
  'onboarding_bonus': instance.onboardingBonus,
  'owned_titles': instance.ownedTitles,
  'counters': instance.counters,
  'milestones_paid': instance.milestonesPaid,
  'timezone': instance.timezone,
  'last_active_day': instance.lastActiveDay?.toIso8601String(),
  'next_rollover_at': instance.nextRolloverAt.toIso8601String(),
  'rest_weekday': instance.restWeekday,
  'pending_rest_weekday': instance.pendingRestWeekday,
  'pause_active': instance.pauseActive,
  'pause_until': instance.pauseUntil?.toIso8601String(),
  'pause_days_used': instance.pauseDaysUsed,
  'pause_month': instance.pauseMonth,
};
