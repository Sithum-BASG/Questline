import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gear_socket.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/stat_icon.dart';
import 'providers/profile_providers.dart';

class GearRow {
  const GearRow({
    required this.catalogId,
    required this.name,
    required this.rarity,
    required this.slot,
    required this.art,
    this.attunedStat,
    this.equippedSlot,
  });

  final String catalogId;
  final String name;
  final String rarity;
  final String slot;
  final String art;
  final String? attunedStat;
  final String? equippedSlot;
}

String _gearArt(String id, dynamic assets) =>
    ((assets is Map ? assets['image'] : null) as String?) ?? 'assets/images/gear/$id.webp';

final gearListProvider = FutureProvider<List<GearRow>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('inventory')
      .select('catalog_id, attuned_stat, equipped_slot, catalog_items(id, name, rarity, type, slot, assets)');
  return [
    for (final row in rows)
      if ((row['catalog_items'] as Map?)?['type'] == 'gear')
        GearRow(
          catalogId: row['catalog_id'] as String,
          name: (row['catalog_items'] as Map)['name'] as String? ?? row['catalog_id'] as String,
          rarity: (row['catalog_items'] as Map)['rarity'] as String? ?? 'common',
          slot: (row['catalog_items'] as Map)['slot'] as String? ?? 'weapon',
          art: _gearArt(row['catalog_id'] as String, (row['catalog_items'] as Map)['assets']),
          attunedStat: row['attuned_stat'] as String?,
          equippedSlot: row['equipped_slot'] as String?,
        ),
  ];
});

/// Gear still to unlock on the level road.
class UpcomingGear {
  const UpcomingGear({
    required this.name,
    required this.rarity,
    required this.slot,
    required this.level,
    required this.art,
    this.passive,
  });

  final String name;
  final String rarity;
  final String slot;
  final int level;
  final String art;
  final String? passive;
}

class GearView {
  const GearView({
    required this.items,
    required this.coins,
    required this.upcoming,
    required this.boostByRarity,
    required this.statCap,
    required this.reattuneCost,
  });

  final List<GearRow> items;
  final int coins;
  final List<UpcomingGear> upcoming;
  final Map<String, double> boostByRarity;
  final double statCap;
  final int reattuneCost;

  GearRow? equipped(String slot) {
    for (final item in items) {
      if (item.equippedSlot == slot) return item;
    }
    return null;
  }

  double boostOf(GearRow item) => boostByRarity[item.rarity] ?? 0;

  /// Total boost a stat gets from equipped, attuned gear, capped.
  double statBoost(String stat) {
    var total = 0.0;
    for (final item in items) {
      if (item.equippedSlot != null && item.attunedStat == stat) total += boostOf(item);
    }
    return total > statCap ? statCap : total;
  }
}

final gearViewProvider = FutureProvider<GearView>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(gameConfigReaderProvider);
  final items = await ref.watch(gearListProvider.future);
  final level = (await ref.watch(profileViewProvider.future)).profile.level;
  final player = await client.from('player_state').select('coins').maybeSingle();
  final owned = {for (final item in items) item.catalogId};
  final rows = await client
      .from('catalog_items')
      .select('id, name, rarity, slot, level, passive, assets')
      .eq('type', 'gear')
      .eq('source', 'level')
      .order('level', ascending: true);
  return GearView(
    items: items,
    coins: (player?['coins'] as num?)?.toInt() ?? 0,
    upcoming: [
      for (final row in rows)
        if (!owned.contains(row['id']) && ((row['level'] as num?)?.toInt() ?? 0) > level)
          UpcomingGear(
            name: row['name'] as String? ?? row['id'] as String,
            rarity: row['rarity'] as String? ?? 'common',
            slot: row['slot'] as String? ?? 'weapon',
            level: (row['level'] as num?)?.toInt() ?? 0,
            art: _gearArt(row['id'] as String, row['assets']),
            passive: row['passive'] as String?,
          ),
    ],
    boostByRarity: await config.gearBoost(),
    statCap: await config.gearStatCap(),
    reattuneCost: await config.reattuneCost(),
  );
});

const _slots = ['weapon', 'armour', 'accessory'];
const _stats = ['intellect', 'craft', 'vitality', 'charisma'];

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _pct(double v) => '${(v * 100).round()}%';

/// Gear: boosts by stat, the three equipped slots, other gear and what the level road brings.
class GearScreen extends ConsumerStatefulWidget {
  const GearScreen({super.key});

  @override
  ConsumerState<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends ConsumerState<GearScreen> {
  String? _error;
  var _busy = false;

  void _refresh() {
    ref.invalidate(gearListProvider);
    ref.invalidate(gearViewProvider);
  }

  Future<void> _equip(GearRow item) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).invoke('loot', 'equipGear', {
        'catalogId': item.catalogId,
        'slot': item.slot,
      });
      _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attune(GearRow item, String stat) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).invoke('loot', 'attuneGear', {
        'catalogId': item.catalogId,
        'stat': stat,
      });
      _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickStat(GearRow item, GearView view) async {
    final stat = await QAttuneSheet.show(context, item: item, view: view);
    if (stat != null && stat != item.attunedStat) await _attune(item, stat);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gearViewProvider);
    final coins = async.asData?.value.coins;
    return Scaffold(
      appBar: ClayHeader(title: 'Gear', trailing: coins == null ? null : CoinPill(coins: coins)),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load gear',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _refresh,
        ),
        data: (view) {
          final equippedCount = _slots.where((s) => view.equipped(s) != null).length;
          final spare = [for (final item in view.items) if (item.equippedSlot == null) item];
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, bottomClearance(context)),
            children: [
              _BoostCard(view: view),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
              ],
              const SizedBox(height: 28),
              _SectionTitle(title: 'Equipped', trailing: '$equippedCount of ${_slots.length} slots'),
              const SizedBox(height: AppSpacing.s12),
              for (final slot in _slots) ...[
                _SlotCard(
                  slot: slot,
                  item: view.equipped(slot),
                  view: view,
                  onAttune: _busy ? null : (item) => _pickStat(item, view),
                ),
                const SizedBox(height: 14),
              ],
              if (spare.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                const _SectionTitle(title: 'In your bag'),
                const SizedBox(height: AppSpacing.s12),
                ClayList(
                  dividerIndent: 78,
                  children: [
                    for (final item in spare)
                      _GearRowTile(
                        art: item.art,
                        rarity: item.rarity,
                        name: item.name,
                        sub: '${_cap(item.slot)} · +${_pct(view.boostOf(item))}',
                        trailing: ClayPill(
                          label: 'Equip',
                          height: 36,
                          onPressed: _busy ? null : () => _equip(item),
                        ),
                      ),
                  ],
                ),
              ],
              if (view.upcoming.isNotEmpty) ...[
                const SizedBox(height: 28),
                const _SectionTitle(title: 'Coming on the level road'),
                const SizedBox(height: AppSpacing.s12),
                ClayList(
                  dividerIndent: 78,
                  children: [
                    for (final gear in view.upcoming)
                      _GearRowTile(
                        art: gear.art,
                        rarity: gear.rarity,
                        name: gear.name,
                        sub: '${_cap(gear.slot)} · +${_pct(view.boostByRarity[gear.rarity] ?? 0)}',
                        passive: gear.passive,
                        trailing: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: const BoxDecoration(
                            color: AppColors.well,
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Lv ${gear.level}',
                            style: AppText.title.copyWith(fontSize: 12, height: 16 / 12, color: AppColors.inkMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.s20),
              Text(
                'New gear goes straight into its slot. You pick the stat when it unlocks. Gear never drops from chests.',
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: AppText.h2))),
        if (trailing != null) Text(trailing!, style: AppText.caption.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _BoostCard extends StatelessWidget {
  const _BoostCard({required this.view});

  final GearView view;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: AppRadius.feature,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('XP BOOST BY STAT', style: AppText.label.copyWith(fontSize: 11, height: 14 / 11))),
              Text('Cap ${_pct(view.statCap)} each', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 8),
          for (final stat in _stats)
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  SizedBox(width: 76, child: Text(_cap(stat), style: AppText.bodySmall.copyWith(fontSize: 13))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClayBar(
                      value: view.statCap <= 0 ? 0 : view.statBoost(stat) / view.statCap,
                      gradient: statGradient(stat),
                      height: 8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _pct(view.statBoost(stat)),
                      textAlign: TextAlign.right,
                      style: AppText.title.copyWith(
                        fontSize: 14,
                        height: 18 / 14,
                        color: view.statBoost(stat) > 0 ? AppColors.ink : AppColors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: AppColors.hairline),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Boosts level you up faster. They never count on the leaderboard.', style: AppText.caption),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.item, required this.view, required this.onAttune});

  final String slot;
  final GearRow? item;
  final GearView view;
  final void Function(GearRow)? onAttune;

  @override
  Widget build(BuildContext context) {
    final gear = item;
    return Clay(
      radius: AppRadius.feature,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        children: [
          GearSocket(rarity: gear?.rarity ?? 'common', art: gear?.art, stat: gear?.attunedStat, size: 76),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.toUpperCase(),
                      style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1.2),
                    ),
                    if (gear != null) ...[const SizedBox(width: 6), RarityTag(rarity: gear.rarity)],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  gear?.name ?? 'Nothing equipped',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(
                    fontSize: 16,
                    height: 20 / 16,
                    color: gear == null ? AppColors.inkMuted : AppColors.ink,
                  ),
                ),
                if (gear != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    height: 30,
                    padding: EdgeInsets.fromLTRB(gear.attunedStat == null ? 10 : 4, 0, 10, 0),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (gear.attunedStat != null) ...[
                          StatDot(stat: gear.attunedStat!, size: 22),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            gear.attunedStat == null
                                ? 'Not attuned yet'
                                : '+${_pct(view.boostOf(gear))} ${_cap(gear.attunedStat!)} XP',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontSize: 12, height: 16 / 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (gear != null) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: gear.attunedStat == null ? 'Attune ${gear.name}' : 'Re-attune ${gear.name}',
              excludeSemantics: true,
              child: Clay(
                kind: ClayKind.control,
                radius: 18,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: onAttune == null ? null : () => onAttune!(gear),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.autorenew_rounded, size: 15, color: AppColors.ink),
                    const SizedBox(width: 5),
                    if (gear.attunedStat == null)
                      Text('Attune', style: AppText.title.copyWith(fontSize: 13, height: 16 / 13))
                    else ...[
                      Image.asset(GameAssets.icon('coin'), width: 16, height: 16),
                      const SizedBox(width: 3),
                      Text('${view.reattuneCost}', style: AppText.title.copyWith(fontSize: 13, height: 16 / 13)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GearRowTile extends StatelessWidget {
  const _GearRowTile({
    required this.art,
    required this.rarity,
    required this.name,
    required this.sub,
    required this.trailing,
    this.passive,
  });

  final String art;
  final String rarity;
  final String name;
  final String sub;
  final Widget trailing;
  final String? passive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      child: Row(
        children: [
          GearSocket(rarity: rarity, art: art, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(fontSize: 14, height: 20 / 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RarityTag(rarity: rarity),
                  ],
                ),
                const SizedBox(height: 3),
                Text(sub, style: AppText.caption),
                if (passive != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.rarityText(rarity)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          passive == 'deep_focus' ? 'Deep focus bonus on long sessions' : 'Extra damage to bosses',
                          style: AppText.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.rarityText(rarity),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Bottom sheet to pick the stat a piece of gear boosts.
class QAttuneSheet extends StatelessWidget {
  const QAttuneSheet({super.key, required this.item, required this.view});

  final GearRow item;
  final GearView view;

  static Future<String?> show(BuildContext context, {required GearRow item, required GearView view}) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => QAttuneSheet(item: item, view: view),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changing = item.attunedStat != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GearSocket(rarity: item.rarity, art: item.art, stat: item.attunedStat, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(changing ? 'Re-attune ${item.name}' : 'Attune ${item.name}', style: AppText.h2),
                      const SizedBox(height: 2),
                      Text(
                        changing
                            ? 'Changing the stat costs ${view.reattuneCost} coins. You have ${formatThousands(view.coins)}.'
                            : 'Pick the stat it boosts. The first pick is free.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            for (final stat in _stats) ...[
              Clay(
                kind: ClayKind.control,
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: stat == item.attunedStat ? null : () => Navigator.pop(context, stat),
                child: Row(
                  children: [
                    StatDot(stat: stat, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_cap(stat), style: AppText.title.copyWith(fontSize: 15))),
                    Text(
                      stat == item.attunedStat ? 'Current' : '+${_pct(view.boostOf(item))} XP',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: stat == item.attunedStat ? AppColors.tealDeep : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
