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
      _$PlayerStateFromJson(json);
}
