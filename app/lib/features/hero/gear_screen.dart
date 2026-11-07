import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';

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
          art: (((row['catalog_items'] as Map)['assets'] as Map?)?['image'] as String?) ??
              'assets/images/gear/${row['catalog_id']}.webp',
          attunedStat: row['attuned_stat'] as String?,
          equippedSlot: row['equipped_slot'] as String?,
        ),
  ];
});

/// Gear list with equip and attune actions.
class GearScreen extends ConsumerStatefulWidget {
  const GearScreen({super.key});

  @override
  ConsumerState<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends ConsumerState<GearScreen> {
  String? _error;
  var _busy = false;

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
      ref.invalidate(gearListProvider);
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
      ref.invalidate(gearListProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickStat(GearRow item) async {
    final stat = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in const ['intellect', 'vitality', 'craft', 'charisma'])
                ListTile(
                  title: Text(s[0].toUpperCase() + s.substring(1)),
                  onTap: () => Navigator.pop(context, s),
                ),
            ],
          ),
        );
      },
    );
    if (stat != null) await _attune(item, stat);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gearListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Gear', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load gear',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(gearListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No gear yet',
              body: 'Level rewards unlock weapons, armour and accessories.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              if (_error != null) ...[
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                const SizedBox(height: AppSpacing.s8),
              ],
              for (final item in items) ...[
                ItemCard(
                  name: item.name,
                  art: item.art,
                  rarity: item.rarity,
                  owned: true,
                  equipped: item.equippedSlot != null,
                  attunedStat: item.attunedStat,
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    QChip(label: item.slot, kind: QChipKind.filter),
                    const Spacer(),
                    if (item.equippedSlot == null)
                      QButton(
                        label: 'Equip',
                        variant: QButtonVariant.secondary,
                        onPressed: _busy ? null : () => _equip(item),
                      )
                    else
                      Text('Equipped', style: AppText.caption.copyWith(color: AppColors.tealDeep)),
                    const SizedBox(width: AppSpacing.s8),
                    QButton(
                      label: item.attunedStat == null ? 'Attune' : 'Re-attune',
                      variant: QButtonVariant.text,
                      onPressed: _busy ? null : () => _pickStat(item),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
            ],
          );
        },
      ),
    );
  }
}
