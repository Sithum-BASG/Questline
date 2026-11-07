import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import '../../data/models/boss.dart';
import 'boss_detail_screen.dart';
import 'providers/boss_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Defeated or escaped result. Claim plays the reward moment then returns to the list.
class BossResultScreen extends ConsumerStatefulWidget {
  const BossResultScreen({super.key, required this.bossId, this.submitResult});

  final String bossId;
  final Map<String, dynamic>? submitResult;

  @override
  ConsumerState<BossResultScreen> createState() => _BossResultScreenState();
}

class _BossResultScreenState extends ConsumerState<BossResultScreen> {
  var _busy = false;

  Future<void> _claim(Boss boss, {required bool escaped, required int coins, required String loot}) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).ackBossResult(boss.id);
      ref.invalidate(bossesProvider);
      ref.invalidate(bossDetailProvider(boss.id));
      final queue = ref.read(rewardQueueProvider);
      if (!escaped) {
        queue.add([
          RewardMoment.boss(
            title: boss.name,
            subtitle: loot == 'full' ? 'Full loot · +$coins coins' : 'Half loot · +$coins coins',
            artPath: GameAssets.boss(boss.tier),
          ),
        ]);
        queue.next();
        if (!mounted) return;
        context.go('/reward');
        return;
      }
      if (!mounted) return;
      context.go('/bosses');
    } on ApiException catch (_) {
      if (mounted) context.go('/bosses');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bossDetailProvider(widget.bossId));
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => EmptyState(
            title: 'Could not load result',
            body: 'Try again from the bosses list.',
            actionLabel: 'Bosses',
            onAction: () => context.go('/bosses'),
          ),
          data: (boss) {
            if (boss == null) {
              return EmptyState(
                title: 'Boss not found',
                body: 'It may already have been cleared.',
                actionLabel: 'Bosses',
                onAction: () => context.go('/bosses'),
              );
            }
            final submit = widget.submitResult;
            final escaped = boss.status == 'escaped' || submit?['result'] == 'escaped';
            final coins = submit?['coins'] is num
                ? (submit!['coins'] as num).toInt()
                : (boss.loot?['coins'] as num?)?.toInt() ?? 0;
            final loot = submit?['loot'] as String? ?? boss.loot?['loot'] as String? ?? 'half';
            final penalty = escaped ? 100 : 0;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    escaped ? 'Escaped' : 'Defeated',
                    style: AppText.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(boss.name, style: AppText.h2, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    escaped
                        ? 'Loot lost. −$penalty coins. XP you earned is kept.'
                        : loot == 'full'
                            ? 'Full loot · +$coins coins'
                            : 'Half loot · +$coins coins',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  QButton(
                    label: _busy ? '…' : 'Claim',
                    onPressed: _busy
                        ? null
                        : () => _claim(boss, escaped: escaped, coins: coins, loot: loot),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
