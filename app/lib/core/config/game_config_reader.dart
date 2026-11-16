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

  /// Share of the fair share (HP ÷ members) a raider must deal to earn loot.
  Future<double> raidFairShareRatio() => _double('raid_fair_share_ratio', 0.5);

  /// Share of the raid HP that still counts as a narrow win.
  Future<double> raidNarrowThreshold() => _double('raid_narrow_threshold', 0.75);

  /// Extra loot for beating a raid before its deadline (0.25 = +25%).
  Future<double> raidVictoryBonus() => _double('raid_victory_bonus', 0.25);

  /// Coins lost by raiders below their share when the boss escapes.
  Future<int> bossEscapePenalty() => _int('boss_escape_penalty', 100);

  /// Smallest and largest party a raid can start with.
  Future<int> partyMin() => _int('party_min', 2);
  Future<int> partyMax() => _int('party_max', 8);

  /// Boss tiers as (name, hours below which it applies, base loot coins).
  Future<List<(String, double, int)>> bossTiers() async {
    final raw = (await load())['boss_tiers'];
    const fallback = [('minion', 4.0, 100), ('brute', 12.0, 150), ('warlord', 25.0, 200), ('titan', 999.0, 300)];
    if (raw is! List) return fallback;
    final tiers = [
      for (final row in raw)
        if (row is List && row.length >= 4 && row[0] is String && row[2] is num && row[3] is num)
          (row[0] as String, (row[2] as num).toDouble(), (row[3] as num).round()),
    ];
    return tiers.isEmpty ? fallback : tiers;
  }

  /// Most members a guild can hold.
  /// Session XP rates used to preview what a session earns. The server computes the real numbers.
  Future<XpRates> xpRates() async {
    final map = await load();
    double d(String key, double fallback) {
      final value = map[key];
      return value is num ? value.toDouble() : fallback;
    }

    final raw = map['xp_difficulty_multipliers'];
    final multipliers = raw is List ? [for (final v in raw) if (v is num) v.toDouble()] : const <double>[];
    return XpRates(
      multipliers: multipliers.isEmpty ? const [0.5, 0.75, 1.0, 1.3, 1.6] : multipliers,
      focusCapRatio: d('xp_focus_cap_ratio', 1.5),
      activityCapRatio: d('xp_activity_cap_ratio', 1),
      activityShare: d('xp_activity_share', 0.8),
      onTimeBonus: d('xp_on_time_bonus', 0.1),
      latePenaltyPerDay: d('xp_late_penalty_per_day', 0.1),
      lateFloor: d('xp_late_floor', 0.5),
      reschedulePenalty: d('xp_reschedule_penalty', 0.2),
      potionMultiplier: d('potion_multiplier', 1.5),
      potionMinMinutes: d('potion_min_minutes', 25),
      minEarningMinutes: d('session_min_minutes', 5),
      graceSeconds: d('xp_grace_seconds', 30).round(),
      tickShare: d('xp_tick_share', 0.5),
    );
  }

  Future<int> guildMax() => _int('guild_max', 10);

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

/// The `game_config` XP numbers a session preview needs.
class XpRates {
  const XpRates({
    required this.multipliers,
    required this.focusCapRatio,
    required this.activityCapRatio,
    required this.activityShare,
    required this.onTimeBonus,
    required this.latePenaltyPerDay,
    required this.lateFloor,
    required this.reschedulePenalty,
    required this.potionMultiplier,
    required this.potionMinMinutes,
    required this.minEarningMinutes,
    required this.graceSeconds,
    required this.tickShare,
  });

  static const defaults = XpRates(
    multipliers: [0.5, 0.75, 1.0, 1.3, 1.6],
    focusCapRatio: 1.5,
    activityCapRatio: 1,
    activityShare: 0.8,
    onTimeBonus: 0.1,
    latePenaltyPerDay: 0.1,
    lateFloor: 0.5,
    reschedulePenalty: 0.2,
    potionMultiplier: 1.5,
    potionMinMinutes: 25,
    minEarningMinutes: 5,
    graceSeconds: 30,
    tickShare: 0.5,
  );

  final List<double> multipliers;
  final double focusCapRatio;
  final double activityCapRatio;
  final double activityShare;
  final double onTimeBonus;
  final double latePenaltyPerDay;
  final double lateFloor;
  final double reschedulePenalty;
  final double potionMultiplier;
  final double potionMinMinutes;

  /// Sessions shorter than this earn no XP or damage (the server's minimum).
  final double minEarningMinutes;

  /// How long you can leave a focus session before it ends.
  final int graceSeconds;

  /// Share of XP a quest ticked off without focus earns.
  final double tickShare;

  double multiplier(int difficulty) =>
      difficulty >= 1 && difficulty <= multipliers.length ? multipliers[difficulty - 1] : 1;
}
