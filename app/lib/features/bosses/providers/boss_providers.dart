import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config_reader.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/boss.dart';
import '../../../data/models/raid.dart';

/// Active and recent solo bosses, soonest deadline first.
final bossesProvider = FutureProvider.autoDispose<List<Boss>>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('bosses')
      .select()
      .order('deadline', ascending: true);
  return (rows as List)
      .map((row) => Boss.fromJson(Map<String, dynamic>.from(row as Map)))
      .toList();
});

/// Solo bosses + raids that still count toward the 15-fight cap.
final activeFightCountProvider = FutureProvider.autoDispose<int>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final bosses = await client
      .from('bosses')
      .select('id')
      .inFilter('status', ['active', 'staggered']);
  final raids = await client.from('raids').select('id').eq('status', 'active');
  return (bosses as List).length + (raids as List).length;
});

final maxActiveFightsProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(gameConfigReaderProvider).maxActiveFights();
});

/// One raid the player is in, with its members' names.
class RaidSummary {
  const RaidSummary({required this.raid, required this.members});

  final Raid raid;
  final List<String> members;

  bool get isActive => raid.status == 'active';
  bool get isGuild => raid.source == 'guild';
  int get hpLeft => (raid.maxHp - raid.damage).clamp(0, raid.maxHp);
}

/// Party raids and guild battles the player is a member of (row security keeps
/// it to their own), soonest deadline first.
final myRaidsProvider = FutureProvider.autoDispose<List<RaidSummary>>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('raids')
      .select('*, raid_members(display_name, left_raid)')
      .order('deadline', ascending: true);
  return [
    for (final row in rows as List)
      RaidSummary(
        raid: Raid.fromJson(Map<String, dynamic>.from(row as Map)),
        members: [
          for (final m in (row['raid_members'] as List? ?? const []))
            if (m is Map && m['left_raid'] != true) (m['display_name'] as String?) ?? '?',
        ],
      ),
  ];
});
