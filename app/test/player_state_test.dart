import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/player_state.dart';

void main() {
  final base = PlayerState(
    userId: 'u1',
    coins: 100,
    xpTotal: 80,
    weeklyRawXp: 40,
    weekId: '2026-W47',
    streakCount: 3,
    streakBest: 3,
    shields: 0,
    potions: 0,
    scrolls: 0,
    freeChests: 0,
    activePotion: false,
    comebackArmed: false,
    inactiveDays: 0,
    chestsSinceLegendary: 0,
    bossCoinsThisWeek: 0,
    aiCallsToday: 0,
    focusMinutesToday: 0,
    onboardingStep: 'done',
    onboardingBonus: const {'character': true},
    ownedTitles: const [],
    counters: const {'raid_mvps': 2},
    milestonesPaid: const [],
    timezone: 'UTC',
    nextRolloverAt: DateTime.utc(2026, 11, 16),
    pauseActive: false,
    pauseDaysUsed: 0,
  );

  test('a row with objects parses as before', () {
    expect(PlayerState.fromJson(base.toJson()).counters, {'raid_mvps': 2});
  });

  test('counters and onboarding bonus stored as JSON strings still parse', () {
    final json = base.toJson()
      ..['counters'] = '{"raid_mvps":2,"raids_won":4}'
      ..['onboarding_bonus'] = '{"character":true}';
    final state = PlayerState.fromJson(json);
    expect(state.counters, {'raid_mvps': 2, 'raids_won': 4});
    expect(state.onboardingBonus, {'character': true});
  });

  test('an unreadable string becomes an empty map instead of failing the row', () {
    final json = base.toJson()..['counters'] = 'not json';
    expect(PlayerState.fromJson(json).counters, isEmpty);
  });
}
