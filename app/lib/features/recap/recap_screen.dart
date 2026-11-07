import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import 'providers/recap_providers.dart';
import 'recap_copy.dart';

/// Swipeable weekly results. Claim plays a reward moment (coins already paid).
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, required this.weekId});

  final String weekId;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _claim(WeeklyResultsPayload data) {
    final queue = ref.read(rewardQueueProvider);
    final coins = data.totalCoins;
    queue.add([
      RewardMoment.loot(
        title: coins > 0 ? '+$coins coins' : 'Week closed',
        subtitle: coins > 0
            ? 'Weekly rewards are already in your pouch.'
            : 'A new leaderboard week has started.',
      ),
    ]);
    queue.next();
    if (mounted) context.go('/reward');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recapProvider(widget.weekId));
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load recap',
          body: 'Check your connection and try again.',
          actionLabel: 'Close',
          onAction: () => context.go('/home'),
        ),
        data: (payload) {
          if (payload == null) {
            return EmptyState(
              title: 'No recap yet',
              body: 'Weekly results show up here after the Monday reset.',
              actionLabel: 'Home',
              onAction: () => context.go('/home'),
            );
          }
          final cards = buildRecapCards(payload);
          final last = _index >= cards.length - 1;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.s16,
                    AppSpacing.screen,
                    AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      Text('Week ${payload.weekId}', style: AppText.caption),
                      const Spacer(),
                      Text(
                        '${_index + 1} / ${cards.length}',
                        style: AppText.caption.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: cards.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final card = cards[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(card.title, style: AppText.display, textAlign: TextAlign.center),
                            const SizedBox(height: AppSpacing.s16),
                            Text(card.body, style: AppText.h2, textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.s8,
                    AppSpacing.screen,
                    AppSpacing.s24,
                  ),
                  child: QButton(
                    label: last ? 'Claim' : 'Next',
                    onPressed: () {
                      if (last) {
                        _claim(payload);
                        return;
                      }
                      final reduce = MediaQuery.disableAnimationsOf(context);
                      _pages.nextPage(
                        duration: Duration(milliseconds: reduce ? 150 : 280),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
