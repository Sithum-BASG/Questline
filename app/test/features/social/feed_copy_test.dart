import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/social/feed_copy.dart';

void main() {
  test('formats known activity types without task titles', () {
    expect(
      activityFeedLine(actorName: 'Asha', type: 'level_up', payload: {'level': 5}),
      'Asha reached level 5',
    );
    expect(
      activityFeedLine(actorName: 'Asha', type: 'boss_defeated', payload: {'name': 'The Shade'}),
      'Asha defeated The Shade',
    );
    expect(
      activityFeedLine(actorName: 'Asha', type: 'boss_defeated', payload: {'tier': 'minion'}),
      'Asha defeated a minion boss',
    );
    expect(
      activityFeedLine(actorName: 'Asha', type: 'raid_won', payload: {}),
      'Asha won a raid',
    );
    expect(
      activityFeedLine(actorName: 'Asha', type: 'chest_drop', payload: {'rarity': 'epic'}),
      'Asha found epic loot in a chest',
    );
    expect(
      activityFeedLine(actorName: 'Asha', type: 'badge', payload: {'badge': 'badge_deep_worker'}),
      'Asha earned deep worker',
    );
  });

  test('ignores accidental task title keys in payload', () {
    final line = activityFeedLine(
      actorName: 'Asha',
      type: 'level_up',
      payload: {'level': 2, 'title': 'Write essay', 'task_title': 'secret'},
    );
    expect(line.contains('essay'), false);
    expect(line.contains('secret'), false);
    expect(line, 'Asha reached level 2');
  });
}
