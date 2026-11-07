import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/leaderboard_row.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'providers/leaderboard_providers.dart';
import 'providers/presence_providers.dart';
import 'providers/friends_providers.dart';

/// Social tab default: weekly friends leaderboard (KEY). Sub-routes cover feed / friends / guild.
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);
    final focusing = ref.watch(focusingFriendsProvider).asData?.value ?? const {};
    final friends = ref.watch(friendRowsProvider).asData?.value.accepted ?? const [];
    final focusingNames = [
      for (final row in friends)
        if (focusing.containsKey(row.profile.id)) row.profile.displayName,
    ];

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text('Leaderboard', style: AppText.h1),
              const SizedBox(height: AppSpacing.s16),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load the board', style: AppText.h2),
                    const SizedBox(height: AppSpacing.s8),
                    Text('Check your connection and try again.', style: AppText.bodySmall),
                    const SizedBox(height: AppSpacing.s12),
                    QButton(
                      label: 'Retry',
                      onPressed: () => ref.invalidate(leaderboardProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (snap) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Text('Leaderboard', style: AppText.h1),
              if (snap.weekId.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text('Week ${snap.weekId}', style: AppText.caption),
              ],
              const SizedBox(height: AppSpacing.s12),
              _SocialNav(
                onFeed: () => context.go('/social/feed'),
                onFriends: () => context.go('/social/friends'),
                onGuild: () => context.go('/social/guild'),
              ),
              if (focusingNames.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                QCard(
                  child: Row(
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: SizedBox(width: 12, height: 12),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Text(
                          'Focusing now: ${focusingNames.join(', ')}',
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              if (snap.needsMoreFriends) ...[
                QCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your week', style: AppText.h2),
                      const SizedBox(height: AppSpacing.s8),
                      Text('${snap.myRawXp} raw XP', style: AppText.numbers),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Add ${snap.minFriends} friends to unlock rank rewards.',
                        style: AppText.bodySmall,
                      ),
                      if (snap.friendCode != null) ...[
                        const SizedBox(height: AppSpacing.s16),
                        Text('Invite with your code', style: AppText.title),
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          children: [
                            Expanded(child: Text(snap.friendCode!, style: AppText.body)),
                            IconButton(
                              tooltip: 'Copy code',
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: snap.friendCode!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Friend code copied')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        QButton(
                          label: 'Add friends',
                          onPressed: () => context.go('/social/friends'),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                if (snap.belowWeeklyTarget) ...[
                  QCard(
                    child: Text(
                      'Reach ${snap.weeklyTarget} XP to qualify for rewards',
                      style: AppText.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
                for (final entry in snap.entries) ...[
                  LeaderboardRow(
                    rank: entry.rank,
                    name: entry.displayName,
                    title: entry.title,
                    xp: entry.rawXp,
                    skinId: entry.skinId,
                    backgroundId: entry.backgroundId,
                    frameId: entry.frameId,
                    body: entry.body,
                    isYou: entry.isYou,
                    onTap: entry.isYou
                        ? null
                        : () => context.go('/social/friends/${entry.userId}'),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialNav extends StatelessWidget {
  const _SocialNav({
    required this.onFeed,
    required this.onFriends,
    required this.onGuild,
  });

  final VoidCallback onFeed;
  final VoidCallback onFriends;
  final VoidCallback onGuild;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        QButton(label: 'Feed', variant: QButtonVariant.secondary, onPressed: onFeed),
        QButton(label: 'Friends', variant: QButtonVariant.secondary, onPressed: onFriends),
        QButton(label: 'Guild', variant: QButtonVariant.secondary, onPressed: onGuild),
      ],
    );
  }
}
