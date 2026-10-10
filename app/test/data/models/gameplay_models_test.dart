import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/boss.dart';
import 'package:questline/data/models/daily_stat.dart';
import 'package:questline/data/models/focus_session.dart';
import 'package:questline/data/models/inventory_item.dart';
import 'package:questline/data/models/task.dart';
import 'package:questline/data/models/weekly_score.dart';

void main() {
  test('gameplay models round-trip snake_case json', () {
    final task = Task.fromJson({
      'id': '22222222-2222-2222-2222-222222222222',
      'user_id': '11111111-1111-1111-1111-111111111111',
      'title': 'Read chapter 3',
      'notes': null,
      'due_at': null,
      'original_due_at': null,
      'boss_id': null,
      'raid_id': null,
      'status': 'draft',
      'rescheduled': false,
      'scroll_used': false,
      'created_at': '2026-10-10T04:00:00.000Z',
      'stat': 'intellect',
      'difficulty': 3,
      'est_minutes': 30,
      'too_big': false,
      'reason': 'A short reading.',
      'provisional': false,
      'challenged': false,
      'judged_at': null,
      'completion_mode': null,
      'completion_minutes': null,
      'completed_at': null,
      'completion_day': null,
      'xp_raw': null,
      'xp_final': null,
    });
    expect(task.toJson()['est_minutes'], 30);

    final session = FocusSession.fromJson({
      'id': '33333333-3333-3333-3333-333333333333',
      'user_id': task.userId,
      'task_id': task.id,
      'mode': 'focus',
      'started_at': '2026-10-10T05:00:00.000Z',
      'ended_at': null,
      'interruptions': <dynamic>[],
      'interruption_seconds': 0,
      'verified_minutes': null,
      'status': 'active',
      'potion': false,
      'demo': false,
      'processed': false,
      'summary': null,
    });
    expect(session.toJson()['task_id'], task.id);

    final boss = Boss.fromJson({
      'id': '44444444-4444-4444-4444-444444444444',
      'user_id': task.userId,
      'name': 'The Deadline Shade',
      'title': 'Midterm',
      'type': 'exam',
      'tier': 'minion',
      'hours': 3,
      'max_hp': 180,
      'damage': 0,
      'deadline': '2026-10-20T04:00:00.000Z',
      'created_at': '2026-10-10T04:00:00.000Z',
      'status': 'active',
      'last_work_day': null,
      'coins_eligible': true,
      'loot': null,
      'result_seen': false,
    });
    expect(boss.toJson()['max_hp'], 180);

    final item = InventoryItem.fromJson({
      'user_id': task.userId,
      'catalog_id': 'skin_starter',
      'acquired_at': '2026-10-10T04:00:00.000Z',
      'source': 'starter',
      'attuned_stat': null,
      'equipped_slot': null,
    });
    expect(item.toJson()['catalog_id'], 'skin_starter');

    final day = DailyStat.fromJson({
      'user_id': task.userId,
      'day': '2026-10-10',
      'xp_intellect': 10,
      'xp_vitality': 0,
      'xp_craft': 0,
      'xp_charisma': 0,
      'raw_xp': 10,
      'focus_minutes': 25,
      'sessions_started': 1,
      'met_minimum': false,
      'rest_day': false,
      'paused': false,
    });
    expect(day.toJson()['raw_xp'], 10);

    final week = WeeklyScore.fromJson({
      'week_id': '2026-W41',
      'user_id': task.userId,
      'raw_xp': 10,
      'updated_at': '2026-10-10T05:00:00.000Z',
    });
    expect(week.toJson()['week_id'], '2026-W41');
  });
}
