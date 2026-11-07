import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/inbox/inbox_copy.dart';

void main() {
  test('inbox copy never echoes a task title key', () {
    final body = inboxBody('weekly_results', {
      'weekId': '2026-W41',
      'rank': 2,
      'title': 'Write essay',
      'task_title': 'secret',
    });
    expect(body.contains('essay'), false);
    expect(body.contains('secret'), false);
    expect(body, contains('2'));
  });

  test('inboxRoute maps known types', () {
    expect(
      inboxRoute('raid_result', {'raidId': 'r1'}),
      '/raids/r1/results',
    );
    expect(
      inboxRoute('boss_result', {'bossId': 'b1'}),
      '/bosses/b1/result',
    );
    expect(
      inboxRoute('friend_request', {}),
      '/social/friends',
    );
  });
}
