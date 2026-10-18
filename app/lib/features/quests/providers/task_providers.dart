import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/task.dart';

/// Reads and inserts the signed-in user's tasks. RLS keeps the rows to the owner.
class TaskRepository {
  TaskRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, user_id, title, notes, due_at, original_due_at, boss_id, raid_id, status, rescheduled, scroll_used, created_at, stat, difficulty, est_minutes, too_big, reason, provisional, challenged, judged_at, completion_mode, completion_minutes, completed_at, completion_day, xp_raw, xp_final';

  Future<List<Task>> list() async {
    final rows = await _client.from('tasks').select(_columns).order('created_at');
    return [for (final row in rows) Task.fromJson(row)];
  }

  /// Client insert grant: title, notes, due date, and an optional parent boss.
  Future<void> insertDraft({
    required String title,
    String? notes,
    DateTime? dueAt,
    String? bossId,
  }) async {
    await _client.from('tasks').insert({
      'title': title,
      'notes': ?notes,
      'due_at': ?dueAt?.toUtc().toIso8601String(),
      'boss_id': ?bossId,
    });
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(supabaseClientProvider));
});

final tasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).list();
});

typedef InsertDraft = Future<void> Function({
  required String title,
  String? notes,
  DateTime? dueAt,
  String? bossId,
});

final insertDraftProvider = Provider<InsertDraft>((ref) {
  return ({required String title, String? notes, DateTime? dueAt, String? bossId}) {
    return ref.read(taskRepositoryProvider).insertDraft(
          title: title,
          notes: notes,
          dueAt: dueAt,
          bossId: bossId,
        );
  };
});
