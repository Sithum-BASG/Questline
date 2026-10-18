import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/task.dart';
import 'package:questline/features/quests/quest_filters.dart';

Task _task({
  required String title,
  String status = 'open',
  String? stat,
  DateTime? dueAt,
}) {
  return Task(
    id: title,
    userId: 'user',
    title: title,
    status: status,
    rescheduled: false,
    scrollUsed: false,
    createdAt: DateTime.utc(2026, 10, 1),
    stat: stat,
    dueAt: dueAt,
    provisional: false,
    challenged: false,
  );
}

void main() {
  final now = DateTime(2026, 10, 10, 15);

  test('today keeps undated and overdue tasks, upcoming keeps later dues', () {
    final tasks = [
      _task(title: 'Notes'),
      _task(title: 'Overdue', dueAt: DateTime(2026, 10, 9)),
      _task(title: 'Later', dueAt: DateTime(2026, 10, 12)),
      _task(title: 'Finished', status: 'done', stat: 'intellect'),
    ];
    expect(tasksForBucket(tasks, QuestBucket.today, null, now).map((task) => task.title), ['Notes', 'Overdue']);
    expect(tasksForBucket(tasks, QuestBucket.upcoming, null, now).map((task) => task.title), ['Later']);
    expect(tasksForBucket(tasks, QuestBucket.done, 'intellect', now).map((task) => task.title), ['Finished']);
    expect(tasksForBucket(tasks, QuestBucket.today, 'vitality', now), isEmpty);
  });
}
