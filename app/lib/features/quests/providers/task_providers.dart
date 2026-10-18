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

  Future<String> insertDraft({
    required String title,
    String? notes,
    DateTime? dueAt,
    String? bossId,
  }) async {
    final row = await _client.from('tasks').insert({
      'title': title,
      'notes': ?notes,
      'due_at': ?dueAt?.toUtc().toIso8601String(),
      'boss_id': ?bossId,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<Task?> find(String id) async {
    final row = await _client.from('tasks').select(_columns).eq('id', id).maybeSingle();
    if (row == null) return null;
    return Task.fromJson(row);
  }

  Future<void> saveOpen(String id) async {
    await _client.from('tasks').update({'status': 'open'}).eq('id', id);
  }

  Future<void> setStat(String id, String stat) async {
    await _client.from('tasks').update({'stat': stat}).eq('id', id);
  }

  Future<void> discard(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(supabaseClientProvider));
});

final tasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).list();
});

typedef InsertDraft = Future<String> Function({
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

final taskProvider = FutureProvider.family<Task?, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).find(id);
});
