import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/social/leaderboard_logic.dart';

void main() {
  test('needs more friends below min threshold', () {
    expect(leaderboardNeedsMoreFriends(3), true);
    expect(leaderboardNeedsMoreFriends(4), false);
    expect(leaderboardNeedsMoreFriends(2, minFriends: 4), true);
  });

  test('below weekly target when under 500 raw XP', () {
    expect(leaderboardBelowWeeklyTarget(0), true);
    expect(leaderboardBelowWeeklyTarget(499), true);
    expect(leaderboardBelowWeeklyTarget(500), false);
  });

  test('title label falls back to level', () {
    expect(leaderboardTitleLabel(null, 3), 'Level 3');
    expect(leaderboardTitleLabel('title_freshly_awakened', 3), 'freshly awakened');
  });
}
