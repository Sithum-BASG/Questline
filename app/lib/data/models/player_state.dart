import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_state.freezed.dart';
part 'player_state.g.dart';

@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    required String userId,
    required int coins,
    required int xpTotal,
    required int weeklyRawXp,
    required String weekId,
    required int streakCount,
    DateTime? streakLastCountedDay,
    required int streakBest,
    required int shields,
    DateTime? lastShieldDay,
    required int potions,
    required int scrolls,
    required int freeChests,
    required bool activePotion,
    required bool comebackArmed,
    required int inactiveDays,
    required int chestsSinceLegendary,
    required int bossCoinsThisWeek,
    required int aiCallsToday,
    required int focusMinutesToday,
    required String onboardingStep,
    required Map<String, dynamic> onboardingBonus,
    required List<String> ownedTitles,
    required Map<String, dynamic> counters,
    required List<int> milestonesPaid,
    required String timezone,
    DateTime? lastActiveDay,
    required DateTime nextRolloverAt,
    int? restWeekday,
    int? pendingRestWeekday,
    required bool pauseActive,
    DateTime? pauseUntil,
    required int pauseDaysUsed,
    String? pauseMonth,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(_withJsonObjects(json, const ['counters', 'onboarding_bonus']));
}

/// Some rows hold a jsonb object as a JSON string (written before the T164 server fix).
/// Decodes those keys so one bad value doesn't fail the whole row.
Map<String, dynamic> _withJsonObjects(Map<String, dynamic> json, List<String> keys) {
  if (!keys.any((key) => json[key] is String)) return json;
  final copy = Map<String, dynamic>.from(json);
  for (final key in keys) {
    final value = copy[key];
    if (value is! String) continue;
    try {
      final decoded = jsonDecode(value);
      copy[key] = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    } on FormatException {
      copy[key] = <String, dynamic>{};
    }
  }
  return copy;
}
