import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
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
      final requestId = 'chest-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(apiClientProvider).openChest(
            requestId: requestId,
            useFreeChest: useFree,
          );
      if (!mounted) return;
      ref.invalidate(chestScreenProvider);
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
      appBar: AppBar(title: Text('Chests', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                child: Image.asset(
                  GameAssets.icon('chest_large'),
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data.coins} coins', style: AppText.h2),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Chest costs ${data.chestCost} coins',
                      style: AppText.bodySmall,
                    ),
                    if (data.freeChests > 0) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        '${data.freeChests} free chest${data.freeChests == 1 ? '' : 's'} ready',
                        style: AppText.bodySmall.copyWith(color: AppColors.awakeningTeal),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Legendary guaranteed in ${data.untilLegendary} chest${data.untilLegendary == 1 ? '' : 's'}',
                      style: AppText.caption.copyWith(color: AppColors.legendary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Drop rates', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              QCard(
                child: Column(
                  children: [
                    for (final rarity in const ['common', 'rare', 'epic', 'legendary', 'mythic'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.rarity(rarity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                rarity[0].toUpperCase() + rarity.substring(1),
                                style: AppText.body,
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
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                const SizedBox(height: AppSpacing.s8),
              ],
              if (canFree)
                QButton(
                  label: _busy ? 'Opening…' : 'Open free chest',
                  onPressed: _busy ? null : () => _open(useFree: true),
                ),
              if (canFree) const SizedBox(height: AppSpacing.s8),
              QButton(
                label: _busy
                    ? 'Opening…'
                    : canPay
                        ? 'Open for ${data.chestCost}'
                        : 'Need $need more coins',
                onPressed: _busy || !canPay ? null : () => _open(useFree: false),
              ),
            ],
          );
        },
      ),
    );
  }
}
