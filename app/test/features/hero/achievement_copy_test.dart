import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/hero/achievement_copy.dart';

void main() {
  test('togglePinnedBadge pins, unpins and respects the max of 3', () {
    expect(togglePinnedBadge([], 'badge_deep_worker'), ['badge_deep_worker']);
    expect(
      togglePinnedBadge(['badge_deep_worker'], 'badge_deep_worker'),
      <String>[],
    );
    expect(
      togglePinnedBadge(
        ['badge_deep_worker', 'badge_boss_hunter', 'badge_unbroken'],
        'badge_punctual',
      ),
      isNull,
    );
  });

  test('badgeProgressFraction walks tiers using documented thresholds', () {
    expect(
      badgeProgressFraction(badgeId: 'badge_deep_worker', progress: 5, tier: 0),
      0.5,
    );
    expect(
      badgeProgressFraction(badgeId: 'badge_deep_worker', progress: 30, tier: 1),
      0.5,
    );
    expect(
      badgeProgressFraction(badgeId: 'badge_deep_worker', progress: 200, tier: 3),
      1,
    );
  });

  test('badgeProgressLabel shows next threshold until Tier III', () {
    expect(
      badgeProgressLabel(badgeId: 'badge_boss_hunter', progress: 0, tier: 0),
      '0 / 1',
    );
    expect(
      badgeProgressLabel(badgeId: 'badge_boss_hunter', progress: 40, tier: 3),
      'Tier III',
    );
  });
}
