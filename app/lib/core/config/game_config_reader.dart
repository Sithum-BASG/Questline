import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';

/// Display-only game numbers from `game_config`, with the schema defaults as fallback.
class GameConfigReader {
  GameConfigReader(this._client);

  final SupabaseClient _client;
  Map<String, dynamic>? _cache;

  static const defaults = <String, dynamic>{
    'chest_cost': 500,
    'chest_legendary_pity': 30,
    'chest_rarity_rates': {
      'common': 0.55,
      'rare': 0.30,
      'epic': 0.12,
      'legendary': 0.025,
      'mythic': 0.005,
    },
  };

  Future<Map<String, dynamic>> load() async {
    if (_cache != null) return _cache!;
    try {
      final rows = await _client.from('game_config').select('key, value');
      final map = Map<String, dynamic>.from(defaults);
      for (final row in rows) {
        final key = row['key'];
        if (key is String) map[key] = row['value'];
      }
      _cache = map;
      return map;
    } catch (_) {
      _cache = Map<String, dynamic>.from(defaults);
      return _cache!;
    }
  }

  Future<int> chestCost() async {
    final value = (await load())['chest_cost'];
    return value is num ? value.round() : 500;
  }

  Future<int> legendaryPity() async {
    final value = (await load())['chest_legendary_pity'];
    return value is num ? value.round() : 30;
  }

  Future<Map<String, double>> rarityRates() async {
    final raw = (await load())['chest_rarity_rates'];
    if (raw is! Map) {
      return {
        for (final entry in (defaults['chest_rarity_rates'] as Map).entries)
          entry.key as String: (entry.value as num).toDouble(),
      };
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is num) entry.key as String: (entry.value as num).toDouble(),
    };
  }
}

final gameConfigReaderProvider = Provider<GameConfigReader>((ref) {
  return GameConfigReader(ref.watch(supabaseClientProvider));
});
