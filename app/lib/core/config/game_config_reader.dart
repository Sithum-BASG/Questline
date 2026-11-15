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
    'max_active_fights': 15,
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

  Future<int> maxActiveFights() async {
    final value = (await load())['max_active_fights'];
    return value is num ? value.round() : 15;
  }

  Future<int> _int(String key, int fallback) async {
    final value = (await load())[key];
    return value is num ? value.round() : fallback;
  }

  Future<double> _double(String key, double fallback) async {
    final value = (await load())[key];
    return value is num ? value.toDouble() : fallback;
  }

  Future<Map<String, double>> _doubleMap(String key, Map<String, double> fallback) async {
    final raw = (await load())[key];
    if (raw is! Map) return fallback;
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is num) entry.key as String: (entry.value as num).toDouble(),
    };
  }

  /// XP boost per gear rarity (0.03 = +3%).
  Future<Map<String, double>> gearBoost() =>
      _doubleMap('gear_boost', const {'common': 0.03, 'rare': 0.05, 'epic': 0.07, 'legendary': 0.09});

  /// Highest total gear boost one stat can reach.
  Future<double> gearStatCap() => _double('gear_stat_cap', 0.25);

  Future<int> reattuneCost() => _int('reattune_cost', 200);

  /// Coins for a duplicate cosmetic, by rarity.
  Future<Map<String, double>> duplicateRefund() =>
      _doubleMap('duplicate_refund', const {'rare': 100, 'epic': 200, 'legendary': 400, 'mythic': 500});

  /// Coin pouch amounts a Common drop can give.
  Future<List<int>> commonPouchAmounts() async {
    final raw = (await load())['chest_common_pouches'];
    if (raw is! List) return const [50, 100, 200, 500];
    return [
      for (final entry in raw)
        if (entry is List && entry.isNotEmpty && entry.first is num) (entry.first as num).round(),
    ];
  }

  /// Coins for badge tiers I, II and III.
  Future<List<int>> badgeTierCoins() async {
    final raw = (await load())['badge_tier_coins'];
    if (raw is! List) return const [50, 100, 200];
    return [for (final v in raw) if (v is num) v.round()];
  }

  Future<int> consumableOverflowCoins() => _int('consumable_overflow_coins', 100);

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
