import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';

class ConsumableCounts {
  const ConsumableCounts({
    required this.shields,
    required this.potions,
    required this.scrolls,
    required this.freeChests,
    required this.activePotion,
    required this.shieldLimit,
    required this.potionLimit,
  });

  final int shields;
  final int potions;
  final int scrolls;
  final int freeChests;
  final bool activePotion;
  final int shieldLimit;
  final int potionLimit;
}

final inventoryCountsProvider = FutureProvider<ConsumableCounts>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(gameConfigReaderProvider);
  final row = await client
      .from('player_state')
      .select('shields, potions, scrolls, free_chests, active_potion')
      .maybeSingle();
  final hold = (await config.load())['hold_limits'];
  final shieldLimit = hold is Map ? (hold['streak_shield'] as num?)?.toInt() ?? 2 : 2;
  final potionLimit = hold is Map ? (hold['focus_potion'] as num?)?.toInt() ?? 3 : 3;
  return ConsumableCounts(
    shields: (row?['shields'] as num?)?.toInt() ?? 0,
    potions: (row?['potions'] as num?)?.toInt() ?? 0,
    scrolls: (row?['scrolls'] as num?)?.toInt() ?? 0,
    freeChests: (row?['free_chests'] as num?)?.toInt() ?? 0,
    activePotion: row?['active_potion'] == true,
    shieldLimit: shieldLimit,
    potionLimit: potionLimit,
  );
});

/// Consumables with hold limits and use potion.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _error;
  var _busy = false;

  Future<void> _usePotion() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).invoke('loot', 'usePotion', {});
      ref.invalidate(inventoryCountsProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryCountsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Inventory', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load inventory',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(inventoryCountsProvider),
        ),
        data: (counts) {
          final empty = counts.shields == 0 && counts.potions == 0 && counts.scrolls == 0 && counts.freeChests == 0;
          if (empty) {
            return const EmptyState(
              title: 'No consumables yet',
              body: 'Find them in chests.',
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
              _ConsumableTile(
                icon: GameAssets.icon('streak_shield'),
                title: 'Streak Shield',
                detail: '${counts.shields} / ${counts.shieldLimit}',
                atMax: counts.shields >= counts.shieldLimit,
              ),
              _ConsumableTile(
                icon: GameAssets.icon('focus_potion'),
                title: 'Focus Potion',
                detail: counts.activePotion
                    ? '${counts.potions} / ${counts.potionLimit} · armed'
                    : '${counts.potions} / ${counts.potionLimit}',
                atMax: counts.potions >= counts.potionLimit,
                actionLabel: counts.potions > 0 && !counts.activePotion ? 'Arm' : null,
                onAction: _busy ? null : _usePotion,
              ),
              _ConsumableTile(
                icon: GameAssets.icon('reschedule_scroll'),
                title: 'Reschedule Scroll',
                detail: '${counts.scrolls}',
              ),
              _ConsumableTile(
                icon: GameAssets.icon('chest'),
                title: 'Free Chest',
                detail: '${counts.freeChests}',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConsumableTile extends StatelessWidget {
  const _ConsumableTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.atMax = false,
    this.actionLabel,
    this.onAction,
  });

  final String icon;
  final String title;
  final String detail;
  final bool atMax;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: QCard(
        child: Row(
          children: [
            Image.asset(icon, width: 48, height: 48),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h2),
                  Text(detail, style: AppText.bodySmall),
                  if (atMax) Text('Max', style: AppText.caption.copyWith(color: AppColors.ember)),
                ],
              ),
            ),
            if (actionLabel != null)
              QButton(label: actionLabel!, variant: QButtonVariant.secondary, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
