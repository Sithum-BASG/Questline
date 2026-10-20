import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/offline/home_snapshot_cache.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/boss.dart';
import '../../../data/models/player_state.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/task.dart';
import '../home_snapshot.dart';

class HomeRepository {
  HomeRepository(this._client, this._cache);

  final SupabaseClient _client;
  final HomeSnapshotCache _cache;

  static const _profileCols =
      'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at';
  static const _playerCols =
      'user_id, coins, xp_total, weekly_raw_xp, week_id, streak_count, streak_last_counted_day, streak_best, shields, last_shield_day, potions, scrolls, free_chests, active_potion, comeback_armed, inactive_days, chests_since_legendary, boss_coins_this_week, ai_calls_today, focus_minutes_today, onboarding_step, onboarding_bonus, owned_titles, counters, milestones_paid, timezone, last_active_day, next_rollover_at, rest_weekday, pending_rest_weekday, pause_active, pause_until, pause_days_used, pause_month';
  static const _taskCols =
      'id, user_id, title, notes, due_at, original_due_at, boss_id, raid_id, status, rescheduled, scroll_used, created_at, stat, difficulty, est_minutes, too_big, reason, provisional, challenged, judged_at, completion_mode, completion_minutes, completed_at, completion_day, xp_raw, xp_final';
  static const _bossCols =
      'id, user_id, name, title, type, tier, hours, max_hp, damage, deadline, created_at, status, last_work_day, coins_eligible, loot, result_seen';

  Future<HomeSnapshot> load() async {
    try {
      final snapshot = await _fetchLive();
      await _cache.save(snapshot.toJson());
      return snapshot;
    } catch (_) {
      final cached = _cache.load();
      if (cached != null) return HomeSnapshot.fromJson(cached, offline: true);
      rethrow;
    }
  }

  Future<HomeSnapshot> _fetchLive() async {
    final profileRow = await _client.from('profiles').select(_profileCols).maybeSingle();
    if (profileRow == null) throw StateError('Profile missing');
    final profile = Profile.fromJson(profileRow);

    final playerRow = await _client.from('player_state').select(_playerCols).maybeSingle();
    if (playerRow == null) throw StateError('Player state missing');
    final player = PlayerState.fromJson(playerRow);

    final taskRows = await _client
        .from('tasks')
        .select(_taskCols)
        .eq('status', 'open')
        .order('due_at', ascending: true)
        .limit(3);
    final tasks = [for (final row in taskRows) Task.fromJson(row)];

    final bossRows = await _client
        .from('bosses')
        .select(_bossCols)
        .inFilter('status', ['active', 'staggered'])
        .order('deadline')
        .limit(1);
    final closestBoss = bossRows.isEmpty ? null : Boss.fromJson(bossRows.first);

    int? weeklyRank;
    final scores = await _client
        .from('weekly_scores')
        .select('user_id, raw_xp')
        .eq('week_id', player.weekId)
        .order('raw_xp', ascending: false);
    for (var i = 0; i < scores.length; i++) {
      if (scores[i]['user_id'] == profile.id) {
        weeklyRank = i + 1;
        break;
      }
    }

    final unread = await _client.from('inbox').select('id').isFilter('read_at', null);
    final unreadInbox = (unread as List).length;

    String? nextRewardLabel;
    final rewardRows = await _client
        .from('level_rewards')
        .select('level, rewards')
        .gt('level', profile.level)
        .order('level')
        .limit(1);
    if (rewardRows.isNotEmpty) {
      final level = rewardRows.first['level'] as num;
      final gap = level.toInt() - profile.level;
      nextRewardLabel = gap == 1 ? 'Next level reward' : '$gap levels until the next reward';
    }

    return HomeSnapshot(
      profile: profile,
      player: player,
      tasks: tasks,
      closestBoss: closestBoss,
      weeklyRank: weeklyRank,
      unreadInbox: unreadInbox,
      nextRewardLabel: nextRewardLabel,
    );
  }
}

final homeSnapshotCacheProvider = FutureProvider<HomeSnapshotCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return HomeSnapshotCache(prefs);
});

final homeRepositoryProvider = FutureProvider<HomeRepository>((ref) async {
  final cache = await ref.watch(homeSnapshotCacheProvider.future);
  return HomeRepository(ref.watch(supabaseClientProvider), cache);
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>((ref) async {
  final repo = await ref.watch(homeRepositoryProvider.future);
  return repo.load();
});
