import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';

class ConsumableCounts {
  const ConsumableCounts({
    required this.shields,
    required this.potions,
    required this.scrolls,
    required this.freeChests,
    required this.activePotion,
    required this.shieldLimit,
    required this.potionLimit,
    this.streak = 0,
    this.overflowCoins = 100,
  });

  final int shields;
  final int potions;
  final int scrolls;
  final int freeChests;
  final bool activePotion;
  final int shieldLimit;
  final int potionLimit;

  /// Current streak, for the shield line.
  final int streak;

  /// Coins a consumable over its hold limit turns into.
  final int overflowCoins;
}

final inventoryCountsProvider = FutureProvider<ConsumableCounts>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final config = ref.watch(gameConfigReaderProvider);
  final row = await client
      .from('player_state')
      .select('shields, potions, scrolls, free_chests, active_potion, streak_count')
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
    streak: (row?['streak_count'] as num?)?.toInt() ?? 0,
    overflowCoins: await config.consumableOverflowCoins(),
  );
});

/// Consumables with hold limits, the potion switch and free chests.
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
      appBar: const ClayHeader(title: 'Inventory'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load inventory',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(inventoryCountsProvider),
        ),
        data: (counts) {
          final empty = counts.shields == 0 && counts.potions == 0 && counts.scrolls == 0 && counts.freeChests == 0;
          if (empty) return _EmptyInventory(onChests: () => context.go('/chests'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s32),
            children: [
              if (_error != null) ...[
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
                const SizedBox(height: AppSpacing.s12),
              ],
              _ItemCard(
                art: GameAssets.icon('streak_shield'),
                wash: AppColors.emberSoft,
                name: 'Streak Shield',
                count: counts.shields,
                limit: counts.shieldLimit,
                description: "Covers one missed day on its own. It can't cover two days in a row.",
                footer: _StatusLine(
                  icon: counts.shields > 0 ? Icons.check_rounded : null,
                  text: counts.shields > 0
                      ? (counts.streak > 0 ? 'Ready: protects your ${counts.streak}-day streak' : 'Ready')
                      : 'None held',
                  color: counts.shields > 0 ? AppColors.tealDeep : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              _ItemCard(
                art: GameAssets.icon('focus_potion'),
                wash: AppColors.tealSoft,
                name: 'Focus Potion',
                count: counts.potions,
                limit: counts.potionLimit,
                description: "Your next verified longer session earns bonus XP. Doesn't stack with the comeback bonus.",
                footer: counts.activePotion
                    ? const _StatusLine(
                        icon: Icons.check_rounded,
                        text: 'Armed for your next session',
                        color: AppColors.tealDeep,
                      )
                    : counts.potions > 0
                        ? Row(
                            children: [
                              QButton(
                                label: 'Arm for next session',
                                height: 36,
                                loading: _busy,
                                onPressed: _busy ? null : _usePotion,
                              ),
                            ],
                          )
                        : const _StatusLine(
                            icon: Icons.play_arrow_rounded,
                            text: 'Turn it on in Start focus',
                            color: AppColors.inkMuted,
                          ),
              ),
              const SizedBox(height: 14),
              _ItemCard(
                art: GameAssets.icon('reschedule_scroll'),
                wash: AppColors.successSoft,
                name: 'Reschedule Scroll',
                count: counts.scrolls,
                description: 'Move a due date without the late penalty. Offered when you change a date.',
                footer: const _StatusLine(text: 'No holding limit', color: AppColors.inkMuted),
              ),
              const SizedBox(height: 14),
              _ItemCard(
                art: GameAssets.icon('chest_large'),
                wash: AppColors.raritySoft('epic'),
                name: 'Free Chest',
                count: counts.freeChests,
                description: 'A standard chest at no cost. Counts toward the Legendary guarantee.',
                footer: counts.freeChests > 0
                    ? Row(
                        children: [QButton(label: 'Open now', height: 36, onPressed: () => context.go('/chests'))],
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                'Consumables come from Rare chest drops. One that would go over its limit turns into '
                '${counts.overflowCoins} coins.',
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.art,
    required this.wash,
    required this.name,
    required this.count,
    required this.description,
    this.limit,
    this.footer,
  });

  final String art;
  final Color wash;
  final String name;
  final int count;
  final int? limit;
  final String description;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cap = limit;
    final atMax = cap != null && cap > 0 && count >= cap;
    final label = cap != null && cap > 0
        ? (atMax ? 'Max $count / $cap' : '$count / $cap')
        : (count == 0 ? 'None' : '× $count');
    final pillBg = atMax ? AppColors.legendarySoft : (count == 0 ? AppColors.well : AppColors.tealSoft);
    final pillInk = atMax ? AppColors.legendaryText : (count == 0 ? AppColors.placeholder : AppColors.tealDeep);
    final image = Image.asset(art, width: 60, height: 60);
    return Clay(
      radius: AppRadius.feature,
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Well(
            width: 72,
            height: 72,
            radius: 22,
            color: wash,
            child: Center(
              child: count == 0 ? Opacity(opacity: 0.4, child: ColorFiltered(colorFilter: _grey, child: image)) : image,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: AppText.title.copyWith(fontSize: 16, height: 20 / 16))),
                    const SizedBox(width: 8),
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: pillBg, borderRadius: const BorderRadius.all(Radius.circular(13))),
                      alignment: Alignment.center,
                      child: Text(label, style: AppText.title.copyWith(fontSize: 13, height: 16 / 13, color: pillInk)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: AppText.bodySmall.copyWith(fontSize: 13, height: 18 / 13)),
                if (footer != null) ...[const SizedBox(height: 6), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _grey = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 6)],
        Flexible(child: Text(text, style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: color))),
      ],
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onChests});

  final VoidCallback onChests;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s24, AppSpacing.screen, AppSpacing.s32),
      children: [
        Clay(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final id in const ['streak_shield', 'focus_potion', 'reschedule_scroll'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: 0.35,
                        child: ColorFiltered(
                          colorFilter: _grey,
                          child: Image.asset(GameAssets.icon(id), width: 56, height: 56),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('No consumables yet', style: AppText.h2),
              const SizedBox(height: 10),
              Text(
                'Find them in chests. Shields, potions and scrolls drop as Rare items.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              QButton(label: 'Go to chests', onPressed: onChests),
            ],
          ),
        ),
      ],
    );
  }
}
