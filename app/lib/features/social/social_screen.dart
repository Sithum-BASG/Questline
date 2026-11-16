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
import '../../core/widgets/loading_skeleton.dart';
import '../../core/assets/game_assets.dart';
import '../../core/widgets/clay.dart';

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

    final header = [
      ScreenTitle(
        title: 'Social',
        trailing: ClayIconButton(
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'Add a friend',
          onPressed: () => context.go('/social/friends'),
        ),
      ),
      const SizedBox(height: AppSpacing.s16),
      _SocialNav(
        onFeed: () => context.go('/social/feed'),
        onFriends: () => context.go('/social/friends'),
        onGuild: () => context.go('/social/guild'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: header),
              ),
              const Expanded(child: LoadingSkeleton()),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              ...header,
              const SizedBox(height: AppSpacing.s24),
              QCard(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load the board', style: AppText.h2),
                    const SizedBox(height: AppSpacing.s8),
                    Text('Check your connection and try again.', style: AppText.bodySmall),
                    const SizedBox(height: AppSpacing.s16),
                    QButton(
                      label: 'Retry',
                      height: 52,
                      onPressed: () => ref.invalidate(leaderboardProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (snap) {
            final podium = snap.entries.where((e) => e.rank <= 3).toList();
            final showPodium = !snap.needsMoreFriends && podium.length >= 3;
            final listed = showPodium ? snap.entries.where((e) => e.rank > 3).toList() : snap.entries;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s16,
                AppSpacing.screen,
                AppSpacing.aboveTabBar,
              ),
              children: [
                ...header,
                const SizedBox(height: AppSpacing.s24),
                Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: Text('Leaderboard', style: AppText.h2))),
                    if (snap.weekId.isNotEmpty)
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.tealSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.tealDeep),
                            const SizedBox(width: 6),
                            Text(
                              'Week ${snap.weekId}',
                              style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.tealDeep),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (focusingNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Clay(
                    kind: ClayKind.control,
                    radius: AppRadius.pill,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            'Focusing now: ${focusingNames.join(', ')}',
                            style: AppText.item.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s16),
                if (snap.needsMoreFriends) ...[
                  QCard(
                    padding: const EdgeInsets.all(AppSpacing.s20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your week', style: AppText.h2),
                        const SizedBox(height: AppSpacing.s8),
                        Text('${snap.myRawXp} raw XP', style: AppText.stat),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Add ${snap.minFriends} friends to unlock rank rewards.',
                          style: AppText.bodySmall,
                        ),
                        if (snap.friendCode != null) ...[
                          const SizedBox(height: AppSpacing.s20),
                          Text('INVITE WITH YOUR CODE', style: AppText.label),
                          const SizedBox(height: AppSpacing.s8),
                          Well(
                            radius: 22,
                            padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    snap.friendCode!,
                                    style: AppText.h2.copyWith(letterSpacing: 3),
                                  ),
                                ),
                                ClayIconButton(
                                  icon: Icons.copy_rounded,
                                  tooltip: 'Copy code',
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: snap.friendCode!));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Friend code copied')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          QButton(
                            label: 'Add friends',
                            icon: Icons.person_add_alt_1_rounded,
                            height: 54,
                            onPressed: () => context.go('/social/friends'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  if (snap.belowWeeklyTarget) ...[
                    Well(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, size: 18, color: AppColors.tealDeep),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Reach ${snap.weeklyTarget} XP to qualify for rewards',
                              style: AppText.bodySmall.copyWith(color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  if (showPodium) ...[
                    _Podium(entries: podium),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                  for (final entry in listed) ...[
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
                      onTap: entry.isYou ? null : () => context.go('/social/friends/${entry.userId}'),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The top three standing on clay blocks: 2nd, 1st, 3rd.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int rank) {
      for (final e in entries) {
        if (e.rank == rank) return e;
      }
      return null;
    }

    final order = [at(2), at(1), at(3)];
    const heights = [78.0, 106.0, 60.0];
    return SizedBox(
      height: 340,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: order[i] == null
                  ? const SizedBox.shrink()
                  : _PodiumPlace(entry: order[i]!, blockHeight: heights[i], first: i == 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({required this.entry, required this.blockHeight, required this.first});

  final LeaderboardEntry entry;
  final double blockHeight;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final skinH = first ? 190.0 : 160.0;
    return Semantics(
      button: !entry.isYou,
      label: '${entry.displayName}, rank ${entry.rank}, ${entry.rawXp} XP${entry.isYou ? ', you' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: entry.isYou ? null : () => context.go('/social/friends/${entry.userId}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: skinH * 0.82,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: skinH,
                  child: Image.asset(
                    GameAssets.skin(entry.skinId, entry.body),
                    height: skinH,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Clay(
              height: blockHeight,
              radius: 18,
              border: entry.isYou ? Border.all(color: AppColors.awakeningTeal, width: 2) : null,
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: AppText.display.copyWith(
                    fontSize: first ? 30 : 24,
                    fontWeight: FontWeight.w800,
                    color: first ? AppColors.tealDeep : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.isYou ? 'You' : entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title.copyWith(fontSize: 14),
            ),
            Text.rich(
              TextSpan(
                style: AppText.caption,
                children: [
                  TextSpan(
                    text: '${entry.rawXp}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const TextSpan(text: ' XP'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sub-tabs: Leaderboard is this screen; the others navigate.
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
    Widget tab(String label, VoidCallback? onTap, {bool selected = false}) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: selected
              ? Clay(
                  kind: ClayKind.control,
                  radius: 18,
                  height: 36,
                  child: Center(
                    child: Text(
                      label,
                      style: AppText.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDeep,
                      ),
                    ),
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        label,
                        style: AppText.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
        ),
      );
    }

    return Well(
      height: 46,
      radius: 23,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          tab('Leaderboard', null, selected: true),
          const SizedBox(width: 4),
          tab('Feed', onFeed),
          const SizedBox(width: 4),
          tab('Friends', onFriends),
          const SizedBox(width: 4),
          tab('Guild', onGuild),
        ],
      ),
    );
  }
}
