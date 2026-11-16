import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/config/game_config_reader.dart';
import '../recap_copy.dart';

class RecapRepository {
  RecapRepository(this._client);

  final SupabaseClient _client;

  Future<WeeklyResultsPayload?> load(String weekId) async {
    final rows = await _client
        .from('inbox')
        .select('payload, created_at')
        .eq('type', 'weekly_results')
        .order('created_at', ascending: false)
        .limit(30);
    for (final row in rows) {
      final payload = row['payload'];
      if (payload is Map && payload['weekId'] == weekId) {
        return WeeklyResultsPayload.fromJson(Map<String, dynamic>.from(payload));
      }
    }

    // Fallback from daily_stats when the inbox row is missing (e.g. local preview).
    final parts = weekId.split('-W');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final week = int.tryParse(parts[1]);
    if (year == null || week == null) return null;

    final dayRows = await _client
        .from('daily_stats')
        .select(
          'day, xp_intellect, xp_vitality, xp_craft, xp_charisma, raw_xp',
        )
        .eq('user_id', _client.auth.currentUser?.id ?? '')
        .order('day');
    var intellect = 0;
    var vitality = 0;
    var craft = 0;
    var charisma = 0;
    var rawXp = 0;
    String? bestDay;
    var bestDayXp = 0;
    for (final row in dayRows) {
      final day = row['day'] as String?;
      if (day == null || !_dayInIsoWeek(day, year, week)) continue;
      intellect += (row['xp_intellect'] as num?)?.toInt() ?? 0;
      vitality += (row['xp_vitality'] as num?)?.toInt() ?? 0;
      craft += (row['xp_craft'] as num?)?.toInt() ?? 0;
      charisma += (row['xp_charisma'] as num?)?.toInt() ?? 0;
      final dayRaw = (row['raw_xp'] as num?)?.toInt() ?? 0;
      rawXp += dayRaw;
      if (dayRaw > bestDayXp) {
        bestDayXp = dayRaw;
        bestDay = day;
      }
    }
    return WeeklyResultsPayload(
      weekId: weekId,
      rawXp: rawXp,
      targetHit: rawXp >= 500,
      targetCoins: 0,
      activeFriends: 0,
      rank: null,
      rankCoins: 0,
      specialItem: null,
      guildQuestCoins: 0,
      intellect: intellect,
      vitality: vitality,
      craft: craft,
      charisma: charisma,
      bestDay: bestDay,
      bestDayXp: bestDayXp,
      bossesBeaten: 0,
    );
  }
}

bool _dayInIsoWeek(String day, int year, int week) {
  final parsed = DateTime.tryParse(day);
  if (parsed == null) return false;
  // ISO week: Thursday's year, week number via days since week-1 Monday.
  final utc = DateTime.utc(parsed.year, parsed.month, parsed.day);
  final thursday = utc.add(Duration(days: 4 - (utc.weekday)));
  if (thursday.year != year) return false;
  final jan4 = DateTime.utc(year, 1, 4);
  final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
  final diff = utc.difference(week1Monday).inDays;
  if (diff < 0) return false;
  return (diff ~/ 7) + 1 == week;
}

final recapRepositoryProvider = Provider<RecapRepository>((ref) {
  watchAccount(ref);
  return RecapRepository(ref.watch(supabaseClientProvider));
});

final recapProvider = FutureProvider.family<WeeklyResultsPayload?, String>((ref, weekId) {
  return ref.watch(recapRepositoryProvider).load(weekId);
});

/// Everything around the weekly payload that the recap cards show.
class RecapExtras {
  const RecapExtras({
    required this.monday,
    required this.dailyXp,
    required this.daysMet,
    required this.streak,
    required this.board,
    required this.targetXp,
    required this.dailyMinimum,
    required this.balancedShare,
  });

  /// Monday of the recap week (local date).
  final DateTime monday;

  /// Raw XP per day, Monday first, seven entries.
  final List<int> dailyXp;

  /// Days that met the daily minimum.
  final int daysMet;
  final int streak;

  /// Top of the friends board: name, raw XP, whether it's you.
  final List<(String, int, bool)> board;
  final int targetXp;
  final int dailyMinimum;
  final double balancedShare;
}

/// Monday of ISO week `YYYY-Www`, or null when the id doesn't parse.
DateTime? isoWeekMonday(String weekId) {
  final parts = weekId.split('-W');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final week = int.tryParse(parts[1]);
  if (year == null || week == null) return null;
  final jan4 = DateTime(year, 1, 4);
  final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
  return week1Monday.add(Duration(days: (week - 1) * 7));
}

String _isoDay(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

final recapExtrasProvider = FutureProvider.autoDispose.family<RecapExtras?, String>((ref, weekId) async {
  watchAccount(ref);
  final monday = isoWeekMonday(weekId);
  if (monday == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id ?? '';
  final sunday = monday.add(const Duration(days: 6));

  final days = await client
      .from('daily_stats')
      .select('day, raw_xp, met_minimum')
      .eq('user_id', uid)
      .gte('day', _isoDay(monday))
      .lte('day', _isoDay(sunday));
  final dailyXp = List<int>.filled(7, 0);
  var daysMet = 0;
  for (final row in days) {
    final day = DateTime.tryParse(row['day'] as String? ?? '');
    if (day == null) continue;
    final index = DateTime(day.year, day.month, day.day).difference(monday).inDays;
    if (index < 0 || index > 6) continue;
    dailyXp[index] = (row['raw_xp'] as num?)?.toInt() ?? 0;
    if (row['met_minimum'] == true) daysMet += 1;
  }

  final player = await client.from('player_state').select('streak_count').maybeSingle();

  final scores = await client
      .from('weekly_scores')
      .select('user_id, raw_xp')
      .eq('week_id', weekId)
      .order('raw_xp', ascending: false)
      .limit(3);
  final ids = [for (final row in scores) row['user_id'] as String];
  final names = ids.isEmpty
      ? const <String, String>{}
      : {
          for (final row in await client.from('profiles').select('id, display_name').inFilter('id', ids))
            row['id'] as String: row['display_name'] as String? ?? 'Friend',
        };
  final board = [
    for (final row in scores)
      (
        row['user_id'] == uid ? 'You' : names[row['user_id']] ?? 'Friend',
        (row['raw_xp'] as num?)?.toInt() ?? 0,
        row['user_id'] == uid,
      ),
  ];

  final config = await ref.read(gameConfigReaderProvider).load();
  int intOf(String key, int fallback) => config[key] is num ? (config[key] as num).round() : fallback;
  double doubleOf(String key, double fallback) => config[key] is num ? (config[key] as num).toDouble() : fallback;

  return RecapExtras(
    monday: monday,
    dailyXp: dailyXp,
    daysMet: daysMet,
    streak: (player?['streak_count'] as num?)?.toInt() ?? 0,
    board: board,
    targetXp: intOf('weekly_target_raw_xp', 500),
    dailyMinimum: intOf('streak_min_raw_xp', 40),
    balancedShare: doubleOf('balanced_min_share', 0.15),
  );
});
