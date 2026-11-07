import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
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
  return RecapRepository(ref.watch(supabaseClientProvider));
});

final recapProvider = FutureProvider.family<WeeklyResultsPayload?, String>((ref, weekId) {
  return ref.watch(recapRepositoryProvider).load(weekId);
});
