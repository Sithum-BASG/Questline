import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/boss.dart';
import 'boss_time.dart';
import 'providers/boss_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Solo bosses sorted by deadline. Raids land in a later phase.
class BossesScreen extends ConsumerWidget {
  const BossesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bossesProvider);
    final activeCount = ref.watch(activeFightCountProvider);
    final atLimit = activeCount >= 15;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => EmptyState(
            title: 'Could not load bosses',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(bossesProvider),
          ),
          data: (bosses) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.s16,
                    AppSpacing.screen,
                    AppSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Bosses', style: AppText.h1),
                      const SizedBox(height: AppSpacing.s8),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: [
                          QButton(
                            label: 'New boss',
                            onPressed: atLimit ? null : () => context.go('/bosses/new'),
                          ),
                          QButton(
                            label: 'Start raid',
                            variant: QButtonVariant.secondary,
                            onPressed: atLimit ? null : () => context.go('/raids/new'),
                          ),
                          QButton(
                            label: 'Join raid',
                            variant: QButtonVariant.secondary,
                            onPressed: () => context.go('/raids/join'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (atLimit)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: Text(
                      'You have 15 active fights. Finish or wait for one to end before summoning another.',
                      style: AppText.bodySmall,
                    ),
                  ),
                Expanded(
                  child: bosses.isEmpty
                      ? EmptyState(
                          title: 'No bosses yet',
                          body: 'Turn a deadline into one.',
                          actionLabel: atLimit ? null : 'Create boss',
                          onAction: atLimit ? null : () => context.go('/bosses/new'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.s12,
                            AppSpacing.screen,
                            100,
                          ),
                          itemCount: bosses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
                          itemBuilder: (context, index) {
                            final boss = bosses[index];
                            return _BossTile(boss: boss, now: now);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BossTile extends StatelessWidget {
  const _BossTile({required this.boss, required this.now});

  final Boss boss;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hp = boss.maxHp <= 0 ? 0.0 : 1 - (boss.damage / boss.maxHp);
    final openResult = (boss.status == 'defeated' || boss.status == 'escaped') && !boss.resultSeen;
    return GestureDetector(
      onTap: () => context.go(openResult ? '/bosses/${boss.id}/result' : '/bosses/${boss.id}'),
      child: BossCard(
        name: boss.name,
        tier: boss.tier,
        hp: hp.clamp(0.0, 1.0),
        timeLeft: bossTimeLeft(boss.deadline, now),
        status: bossStatusLabel(boss.status),
      ),
    );
  }
}
