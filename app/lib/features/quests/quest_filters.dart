import '../../../data/models/task.dart';

enum QuestBucket { today, upcoming, done }

/// Open and draft tasks land in Today when they are undated, due today, or overdue.
List<Task> tasksForBucket(List<Task> tasks, QuestBucket bucket, String? stat, DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return [
    for (final task in tasks)
      if (_inBucket(task, bucket, start, end) && (stat == null || task.stat == stat)) task,
  ];
}

bool _inBucket(Task task, QuestBucket bucket, DateTime start, DateTime end) {
  if (task.status == 'done') return bucket == QuestBucket.done;
  if (task.status != 'open' && task.status != 'draft') return false;
  if (bucket == QuestBucket.done) return false;
  final due = task.dueAt?.toLocal();
  final upcoming = due != null && !due.isBefore(end);
  return bucket == QuestBucket.upcoming ? upcoming : !upcoming;
}

bool taskIsLate(Task task, DateTime now) {
  final due = task.dueAt;
  if (due == null || task.status == 'done') return false;
  return due.isBefore(now);
}

String dueLabel(Task task, DateTime now) {
  final due = task.dueAt?.toLocal();
  if (due == null) return 'No due date';
  if (taskIsLate(task, now)) return 'Late';
  return '${due.day}/${due.month}';
}
