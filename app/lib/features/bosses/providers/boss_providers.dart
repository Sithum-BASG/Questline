import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config_reader.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/boss.dart';

/// Active and recent solo bosses, soonest deadline first.
final bossesProvider = FutureProvider.autoDispose<List<Boss>>((ref) async {
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
