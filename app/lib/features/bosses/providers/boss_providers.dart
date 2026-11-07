import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final activeFightCountProvider = Provider.autoDispose<int>((ref) {
  final bosses = ref.watch(bossesProvider).asData?.value ?? const <Boss>[];
  return bosses.where((boss) => boss.status == 'active' || boss.status == 'staggered').length;
});
