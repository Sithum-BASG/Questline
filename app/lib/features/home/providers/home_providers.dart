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
import '../../hero/level_road_screen.dart';

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
    final uid = _client.auth.currentUser?.id;
    try {
      final snapshot = await _fetchLive();
      if (uid != null) await _cache.save(uid, snapshot.toJson());
      return snapshot;
    } catch (_) {
      final cached = uid == null ? null : _cache.load(uid);
      if (cached != null) return HomeSnapshot.fromJson(cached, offline: true);
      rethrow;
    }
  }

  Future<HomeSnapshot> _fetchLive() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final profileRow = await _client.from('profiles').select(_profileCols).eq('id', uid).maybeSingle();
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
        .order('deadline', ascending: true)
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
    RoadReward? nextReward;
    int? nextRewardLevel;
    final rewardRows = await _client
        .from('level_rewards')
        .select('level, rewards')
        .gt('level', profile.level)
        .order('level', ascending: true)
        .limit(1);
    if (rewardRows.isNotEmpty) {
      nextRewardLevel = (rewardRows.first['level'] as num).toInt();
      final entries = [
        for (final r in (rewardRows.first['rewards'] as List? ?? const []))
          if (r is Map) Map<String, dynamic>.from(r),
      ];
      // Show the item if the level has one, else the title, else the coins.
      Map<String, dynamic>? pick;
      for (final type in const ['item', 'title', 'coins']) {
        pick ??= entries.where((r) => r['type'] == type).firstOrNull;
      }
      pick ??= entries.firstOrNull;
      if (pick != null) {
        final id = pick['id'];
        Map<String, dynamic>? item;
        if (id is String) {
          item = await _client.from('catalog_items').select('name, type, rarity, slot').eq('id', id).maybeSingle();
        }
        final reward = RoadReward(
          type: pick['type'] as String? ?? 'item',
          id: id is String ? id : null,
          amount: (pick['amount'] as num?)?.toInt(),
          name: item?['name'] as String?,
          rarity: item?['rarity'] as String?,
          slot: item?['slot'] as String?,
          itemType: item?['type'] as String?,
        );
        nextReward = reward;
        final rarity = reward.rarity;
        final rarityText =
            rarity == null || rarity == 'common' ? '' : ', ${rarity[0].toUpperCase()}${rarity.substring(1)}';
        nextRewardLabel = 'Next reward at level $nextRewardLevel: ${reward.label}$rarityText';
      }
    }

    final friends = await _client
        .from('friendships')
        .select('friend_id')
        .eq('status', 'accepted')
        .limit(1);
    final showAddFriends = (friends as List).isEmpty;

    return HomeSnapshot(
      profile: profile,
      player: player,
      tasks: tasks,
      closestBoss: closestBoss,
      weeklyRank: weeklyRank,
      unreadInbox: unreadInbox,
      nextRewardLabel: nextRewardLabel,
      nextReward: nextReward,
      nextRewardLevel: nextRewardLevel,
      showAddFriends: showAddFriends,
    );
  }
}

final homeSnapshotCacheProvider = FutureProvider<HomeSnapshotCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return HomeSnapshotCache(prefs);
});

final homeRepositoryProvider = FutureProvider<HomeRepository>((ref) async {
  watchAccount(ref);
  final cache = await ref.watch(homeSnapshotCacheProvider.future);
  return HomeRepository(ref.watch(supabaseClientProvider), cache);
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>((ref) async {
  final repo = await ref.watch(homeRepositoryProvider.future);
  return repo.load();
});
