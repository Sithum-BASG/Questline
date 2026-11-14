import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/motion/app_haptics.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import '../hero/inventory_screen.dart';
import '../hero/wardrobe_screen.dart';
import '../../core/widgets/clay.dart';
import 'providers/chest_providers.dart';

/// Rates, pity counter and open actions for chests.
class ChestsScreen extends ConsumerStatefulWidget {
  const ChestsScreen({super.key});

  @override
  ConsumerState<ChestsScreen> createState() => _ChestsScreenState();
}

class _ChestsScreenState extends ConsumerState<ChestsScreen> {
  var _busy = false;
  String? _error;

  Future<void> _open({required bool useFree}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppHaptics.chestOpen();
      final requestId = 'chest-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(apiClientProvider).openChest(
            requestId: requestId,
            useFreeChest: useFree,
          );
      if (!mounted) return;
      ref.invalidate(chestScreenProvider);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(inventoryCountsProvider);
      context.push('/chests/open', extra: result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chestScreenProvider);
    return Scaffold(
      appBar: const ClayHeader(title: 'Chests'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load chests',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(chestScreenProvider),
        ),
        data: (data) {
          final need = data.chestCost - data.coins;
          final canPay = data.coins >= data.chestCost;
          final canFree = data.freeChests > 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Center(
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Clay(
                        circle: true,
                        width: 230,
                        height: 230,
                        gradient: RadialGradient(colors: [AppColors.white, AppColors.legendarySoft]),
                      ),
                      Image.asset(
                        GameAssets.icon('chest_large'),
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              QCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(GameAssets.icon('coin'), width: 30, height: 30),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${data.coins} coins', style: AppText.h2, softWrap: true)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        QChip(label: '${data.chestCost} coins each'),
                        if (data.freeChests > 0)
                          QChip(
                            label: '${data.freeChests} free',
                            selected: true,
                          ),
                        QChip(
                          label: 'Legendary in ${data.untilLegendary}',
                          kind: QChipKind.rarity,
                          color: AppColors.legendary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const SectionLabel(label: 'Drop rates', gemColor: AppColors.legendary),
              const SizedBox(height: AppSpacing.s12),
              QCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    for (final rarity in const ['common', 'rare', 'epic', 'legendary', 'mythic'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            ClayDot(
                              size: 22,
                              gradient: dotGradient(
                                Color.lerp(AppColors.rarity(rarity), AppColors.white, 0.45)!,
                                AppColors.rarity(rarity),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Text(
                                rarity[0].toUpperCase() + rarity.substring(1),
                                style: AppText.item.copyWith(color: AppColors.rarityText(rarity)),
                              ),
                            ),
                            Text(
                              '${((data.rates[rarity] ?? 0) * 100).toStringAsFixed(rarity == 'mythic' || rarity == 'legendary' ? 1 : 0)}%',
                              style: AppText.numbers,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              if (_error != null) ...[
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.s8),
              ],
              if (canFree)
                QButton(
                  label: 'Open free chest',
                  loading: _busy,
                  onPressed: _busy ? null : () => _open(useFree: true),
                ),
              if (canFree) const SizedBox(height: AppSpacing.s12),
              QButton(
                variant: canFree ? QButtonVariant.secondary : QButtonVariant.primary,
                label: canPay ? 'Open for ${data.chestCost}' : 'Need $need more coins',
                loading: _busy,
                onPressed: _busy || !canPay ? null : () => _open(useFree: false),
              ),
            ],
          );
        },
      ),
    );
  }
}
