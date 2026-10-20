import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/game/level_curve.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/stage_card.dart';
import '../../core/widgets/task_tile.dart';
import '../../data/models/boss.dart';
import 'home_snapshot.dart';
import 'providers/home_providers.dart';

String _catalogShort(String id, String prefix) =>
    id.startsWith(prefix) ? id.substring(prefix.length) : id;

String _timeLeft(DateTime deadline, DateTime now) {
  final diff = deadline.difference(now);
  if (diff.isNegative) return 'Overdue';
  if (diff.inDays >= 1) return '${diff.inDays}d left';
  if (diff.inHours >= 1) return '${diff.inHours}h left';
  return '${diff.inMinutes}m left';
}

/// Home tab: stage, XP, streak tiles, closest boss placeholder, today's tasks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeSnapshotProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Could not load Home',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(homeSnapshotProvider),
          ),
          data: (snapshot) => _HomeBody(snapshot: snapshot),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = snapshot.profile;
    final player = snapshot.player;
    final body = profile.bodyType == 'b' ? BodyType.b : BodyType.a;
    final xpProgress = LevelCurve.defaults.progressInLevel(player.xpTotal, profile.level);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(homeSnapshotProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s16,
          AppSpacing.screen,
          AppSpacing.aboveTabBar,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hi, ${profile.displayName}',
                  style: AppText.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (snapshot.offline)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.s8),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('Offline', style: AppText.caption.copyWith(color: AppColors.inkMuted)),
                ),
              IconButton(
                tooltip: 'Inbox',
                onPressed: () => context.push('/inbox'),
                icon: Badge(
                  isLabelVisible: snapshot.unreadInbox > 0,
                  label: Text('${snapshot.unreadInbox}'),
                  child: const Icon(Icons.notifications_none_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Center(
            child: StageCard(
              skinId: _catalogShort(profile.equippedSkinId, 'skin_'),
              backgroundId: _catalogShort(profile.equippedBackgroundId, 'bg_'),
              body: body,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          GestureDetector(
            onTap: () => context.go('/hero/level-road'),
            child: ProgressBar(
              value: xpProgress,
              leading: 'Level ${profile.level}',
              trailing: snapshot.nextRewardLabel ?? 'Level road',
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HomeStat(
                icon: Icons.local_fire_department_outlined,
                color: AppColors.streakEmber,
                value: '${player.streakCount}',
                label: 'Streak',
              ),
              _HomeStat(
                icon: Icons.bolt_outlined,
                color: AppColors.awakeningTeal,
                value: '${player.weeklyRawXp}',
                label: 'This week',
              ),
              _HomeStat(
                icon: Icons.emoji_events_outlined,
                color: AppColors.tealDeep,
                value: snapshot.weeklyRank == null ? '—' : '#${snapshot.weeklyRank}',
                label: 'This week',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          _BossSection(boss: snapshot.closestBoss, now: now),
          if (snapshot.showAddFriends) ...[
            const SizedBox(height: AppSpacing.s16),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add friends', style: AppText.h2),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Compare weekly XP when you are ready — never required.',
                    style: AppText.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  QButton(
                    label: 'Find friends',
                    variant: QButtonVariant.secondary,
                    onPressed: () => context.go('/social/friends'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          Text("Today's quests", style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          if (snapshot.tasks.isEmpty)
            EmptyState(
              title: 'Add your first quest',
              body: 'Real tasks turn into XP when you focus.',
              actionLabel: 'Add quest',
              onAction: () => context.push('/quests/new'),
            )
          else
            for (final task in snapshot.tasks) ...[
              TaskTile(
                title: task.title,
                stat: task.stat ?? 'intellect',
                dueLabel: task.dueAt == null ? 'No due date' : _timeLeft(task.dueAt!, now),
                onPlay: () => context.push('/focus/start?taskId=${task.id}'),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          const SizedBox(height: AppSpacing.s16),
          QButton(
            label: 'Start focus',
            onPressed: () => context.push('/focus/start'),
          ),
        ],
      ),
    );
  }
}

class _HomeStat extends StatelessWidget {
  const _HomeStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: AppSpacing.s4),
        Text(value, style: AppText.numbers),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

class _BossSection extends StatelessWidget {
  const _BossSection({required this.boss, required this.now});

  final Boss? boss;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (boss == null) {
      return QCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Got a deadline coming up?', style: AppText.h2),
            const SizedBox(height: AppSpacing.s8),
            Text('Turn it into a boss.', style: AppText.bodySmall),
            const SizedBox(height: AppSpacing.s12),
            QButton(
              label: 'Create boss',
              variant: QButtonVariant.secondary,
              onPressed: () => context.go('/bosses/new'),
            ),
          ],
        ),
      );
    }
    final hp = boss!.maxHp <= 0 ? 0.0 : 1 - (boss!.damage / boss!.maxHp);
    return GestureDetector(
      onTap: () => context.go('/bosses/${boss!.id}'),
      child: BossCard(
        name: boss!.name,
        tier: boss!.tier,
        hp: hp.clamp(0.0, 1.0),
        timeLeft: _timeLeft(boss!.deadline, now),
        status: boss!.status[0].toUpperCase() + boss!.status.substring(1),
      ),
    );
  }
}
