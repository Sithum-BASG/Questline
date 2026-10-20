import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config_reader.dart';
import '../../../core/supabase/supabase_providers.dart';

class ChestScreenData {
  const ChestScreenData({
    required this.coins,
    required this.freeChests,
    required this.pityCounter,
    required this.pityLimit,
    required this.chestCost,
    required this.rates,
  });

  final int coins;
  final int freeChests;
  final int pityCounter;
  final int pityLimit;
  final int chestCost;
  final Map<String, double> rates;

  int get untilLegendary {
    final left = pityLimit - pityCounter;
    return left < 1 ? 1 : left;
  }
}

final chestScreenProvider = FutureProvider<ChestScreenData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(gameConfigReaderProvider);
  final row = await client
      .from('player_state')
      .select('coins, free_chests, chests_since_legendary')
      .maybeSingle();
  final coins = (row?['coins'] as num?)?.toInt() ?? 0;
  final free = (row?['free_chests'] as num?)?.toInt() ?? 0;
  final pity = (row?['chests_since_legendary'] as num?)?.toInt() ?? 0;
  return ChestScreenData(
    coins: coins,
    freeChests: free,
    pityCounter: pity,
    pityLimit: await config.legendaryPity(),
    chestCost: await config.chestCost(),
    rates: await config.rarityRates(),
  );
});
