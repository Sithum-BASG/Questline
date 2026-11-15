import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/game/level_curve.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/shadows.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/task_tile.dart';
import '../../data/models/boss.dart';
import '../../core/supabase/supabase_providers.dart';
import '../bosses/providers/boss_providers.dart';
import '../inbox/providers/inbox_providers.dart';
import '../social/providers/friends_providers.dart';
import '../social/providers/presence_providers.dart';
import '../hero/level_road_screen.dart';
import 'home_snapshot.dart';
import 'providers/home_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Cold-start reclaim: kill → open app lands on Home with an orphaned active session.
final activeFocusSessionIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (uid == null) return null;
  final row = await client
      .from('sessions')
      .select('id')
      .eq('user_id', uid)
      .eq('status', 'active')
      .maybeSingle();
  return row?['id'] as String?;
});

String _catalogShort(String id, String prefix) =>
    id.startsWith(prefix) ? id.substring(prefix.length) : id;

String _timeLeft(DateTime deadline, DateTime now) {
  final diff = deadline.difference(now);
  if (diff.isNegative) return 'Overdue';
  if (diff.inDays >= 1) return '${diff.inDays}d left';
  if (diff.inHours >= 1) return '${diff.inHours}h left';
  return '${diff.inMinutes}m left';
}

String _greeting(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Good evening,';
  if (h < 12) return 'Good morning,';
  if (h < 17) return 'Good afternoon,';
  return 'Good evening,';
}

/// 2350 → "2,350".
String thousands(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// Home tab: portrait, coins and inbox; greeting; hero window with the level
/// strip; stat orbs; closest boss; today's quests; docked Start focus.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activeFocusSessionIdProvider, (prev, next) {
      final id = next.asData?.value;
      if (id != null && context.mounted) context.go('/focus/$id');
    });

    final async = ref.watch(homeSnapshotProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => Center(
            child: EmptyState(
              title: 'Could not load Home',
              body: 'Check your connection and try again.',
              icon: Icons.cloud_off_rounded,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(homeSnapshotProvider),
            ),
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
    const curve = LevelCurve.defaults;
    final xpProgress = curve.progressInLevel(player.xpTotal, profile.level);
    final floor = curve.totalForLevel(profile.level);
    final ceiling = curve.totalForLevel(profile.level + 1);
    final now = DateTime.now();
    final skinId = _catalogShort(profile.equippedSkinId, 'skin_');
    final backgroundId = _catalogShort(profile.equippedBackgroundId, 'bg_');

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeSnapshotProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveDockedButton + 40,
            ),
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Your profile, level ${profile.level}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => context.go('/hero'),
                      child: PortraitFrame(
                        skinId: skinId,
                        backgroundId: backgroundId,
                        frameId: _catalogShort(profile.equippedFrameId, 'frame_'),
                        body: body,
                        size: PortraitFrameSize.compact,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (snapshot.offline) ...[
                    Well(
                      radius: AppRadius.pill,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                      child: Center(
                        widthFactor: 1,
                        child: Text('Offline', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  ClayPill(
                    label: thousands(player.coins),
                    height: 44,
                    leading: Image.asset(GameAssets.icon('coin'), width: 26, height: 26),
                    onPressed: () => context.go('/chests'),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Consumer(
                    builder: (context, ref, _) {
                      final live = ref.watch(unreadInboxCountProvider).asData?.value;
                      final unread = live ?? snapshot.unreadInbox;
                      return ClayIconButton(
                        icon: Icons.notifications_none_rounded,
                        iconSize: 22,
                        size: 48,
                        badge: unread > 0,
                        tooltip: unread > 0 ? 'Inbox, $unread unread' : 'Inbox',
                        onPressed: () => context.push('/inbox'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                label: 'Hi, ${profile.displayName}',
                excludeSemantics: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_greeting(now)} ',
                        style: AppText.h1.copyWith(fontWeight: FontWeight.w500, color: AppColors.inkMuted),
                      ),
                      TextSpan(text: profile.displayName, style: AppText.h1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 56),
              _HeroWindow(
                skinId: skinId,
                backgroundId: backgroundId,
                body: body,
                level: profile.level,
                xpIn: (player.xpTotal - floor).clamp(0, 1 << 30),
                xpSpan: (ceiling - floor).clamp(1, 1 << 30),
                progress: xpProgress,
                nextReward: snapshot.nextRewardLabel ?? 'Next reward',
                rewardItem: snapshot.nextReward,
                rewardLevel: snapshot.nextRewardLevel,
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.streakEmber,
                      value: '${player.streakCount}',
                      label: 'Day streak',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.bolt_rounded,
                      color: AppColors.awakeningTeal,
                      value: thousands(player.weeklyRawXp),
                      label: 'XP this week',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.success,
                      value: snapshot.weeklyRank == null ? '—' : '#${snapshot.weeklyRank}',
                      label: 'Rank this week',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const _FocusingNowStrip(),
              _BossSection(boss: snapshot.closestBoss, now: now),
              if (snapshot.showAddFriends) ...[
                const SizedBox(height: AppSpacing.s24),
                QCard(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    children: [
                      ClayDot(
                        size: 44,
                        gradient: dotGradient(AppColors.tealLight, AppColors.tealDeep),
                        icon: Icons.group_add_rounded,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add friends', style: AppText.title),
                            const SizedBox(height: 2),
                            Text(
                              'Compare weekly XP when you are ready — never required.',
                              style: AppText.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      ClayPill(
                        label: 'Find friends',
                        color: AppColors.tealDeep,
                        onPressed: () => context.go('/social/friends'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),
              SectionHeader(
                title: "Today's quests",
                action: 'View all',
                onAction: () => context.go('/quests'),
              ),
              const SizedBox(height: AppSpacing.s12),
              if (snapshot.tasks.isEmpty)
                Semantics(
                  button: true,
                  label: 'Add your first quest',
                  excludeSemantics: true,
                  child: Well(
                    radius: 26,
                    height: 70,
                    onTap: () => context.push('/quests/new'),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Clay(
                          kind: ClayKind.teal,
                          circle: true,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.add_rounded, color: AppColors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text('Add your first quest', style: AppText.item),
                      ],
                    ),
                  ),
                )
              else
                ClayList(
                  children: [
                    for (final task in snapshot.tasks)
                      TaskTile(
                        bare: true,
                        title: task.title,
                        stat: task.stat ?? 'intellect',
                        dueLabel: task.dueAt == null ? 'No due date' : _timeLeft(task.dueAt!, now),
                        late: task.dueAt != null && task.dueAt!.isBefore(now),
                        provisional: task.provisional,
                        onPlay: () => context.push('/focus/start?taskId=${task.id}'),
                      ),
                  ],
                ),
            ],
          ),
        ),
        DockedAction(
          child: QButton(
            label: 'Start focus',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.push('/focus/start'),
          ),
        ),
      ],
    );
  }
}

/// The hero in a clay window, head breaking out of the top, with the level
/// strip docked inside the bottom.
/// The next level-road reward in a round socket ringed in its rarity colour,
/// with the level it unlocks at as a corner badge.
class _NextRewardSocket extends StatelessWidget {
  const _NextRewardSocket({required this.reward, required this.level});

  final RoadReward? reward;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final item = reward;
    final accent = item == null
        ? AppColors.rare
        : item.type == 'coins'
            ? AppColors.legendary
            : item.type == 'title'
                ? AppColors.awakeningTeal
                : AppColors.rarity(item.rarity ?? 'common');
    final soft = Color.lerp(accent, AppColors.white, 0.82)!;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.3),
                colors: [AppColors.white, soft, Color.lerp(soft, accent, 0.15)!],
                stops: const [0, 0.55, 1],
              ),
              border: Border.all(color: Color.lerp(accent, AppColors.white, 0.25)!, width: 2.5),
              boxShadow: AppShadows.onScene,
            ),
            child: ClipOval(
              child: item == null
                  ? Icon(Icons.card_giftcard_rounded, size: 22, color: accent)
                  : Padding(
                      padding: EdgeInsets.all(item.itemType == 'background' ? 0 : 3),
                      child: RewardArt(reward: item),
                    ),
            ),
          ),
          if (level != null)
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(11)),
                  border: Border.all(color: AppColors.white, width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(accent, AppColors.white, 0.15)!, accent],
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x38101935), offset: Offset(1, 2), blurRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: AppText.title.copyWith(fontSize: 10, height: 12 / 10, color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroWindow extends StatelessWidget {
  const _HeroWindow({
    required this.skinId,
    required this.backgroundId,
    required this.body,
    required this.level,
    required this.xpIn,
    required this.xpSpan,
    required this.progress,
    required this.nextReward,
    this.rewardItem,
    this.rewardLevel,
  });

  final String skinId;
  final String backgroundId;
  final BodyType body;
  final int level;
  final int xpIn;
  final int xpSpan;
  final double progress;

  /// Spoken / tooltip text for the next reward.
  final String nextReward;

  /// The next reward on the level road and its unlock level, when known.
  final RoadReward? rewardItem;
  final int? rewardLevel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, box) {
          final inner = box.maxWidth - 16;
          // Skin canvas is 1024×1536; draw it a little wider than the window
          // so the upper body fills it and the head breaks out of the top.
          final skinW = inner * 1.12;
          final skinH = skinW * 1.5;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: Clay(radius: AppRadius.hero)),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        GameAssets.background(backgroundId),
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, 0.16),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.1),
                            radius: 0.7,
                            colors: [
                              AppColors.awakeningTeal.withValues(alpha: 0.30),
                              AppColors.awakeningTeal.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      const CustomPaint(
                        painter: InnerShadowPainter(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          shadows: [
                            InnerShadow(Offset(5, 6), 14, Color(0x33101935)),
                            InnerShadow(Offset(-4, -4), 10, Color(0x73FFFFFF)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: -112,
                bottom: 8,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxWidth: skinW,
                      minWidth: skinW,
                      maxHeight: skinH + 72,
                      minHeight: skinH + 72,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 72),
                        child: Semantics(
                          image: true,
                          label: 'Your character',
                          child: Image.asset(
                            GameAssets.skin(skinId, body),
                            width: skinW,
                            height: skinH,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Semantics(
                  button: true,
                  label: 'Level road. Level $level, $xpIn of $xpSpan XP. $nextReward',
                  excludeSemantics: true,
                  child: Clay(
                    kind: ClayKind.onScene,
                    radius: 26,
                    height: 68,
                    onTap: () => context.go('/hero/level-road'),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    child: Row(
                      children: [
                        Clay(
                          kind: ClayKind.tealOnScene,
                          circle: true,
                          width: 46,
                          height: 46,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LV',
                                style: AppText.caption.copyWith(
                                  fontSize: 7,
                                  height: 8 / 7,
                                  letterSpacing: 0.42,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                '$level',
                                style: AppText.numbers.copyWith(fontSize: 17, height: 19 / 17, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: thousands(xpIn),
                                      style: AppText.numbers.copyWith(fontSize: 13, height: 18 / 13),
                                    ),
                                    TextSpan(
                                      text: ' / ${thousands(xpSpan)} XP',
                                      style: AppText.numbers.copyWith(
                                        fontSize: 13,
                                        height: 18 / 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 7),
                              ClayBar(value: progress),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: nextReward,
                          child: _NextRewardSocket(reward: rewardItem, level: rewardLevel),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FocusingNowStrip extends ConsumerWidget {
  const _FocusingNowStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusing = ref.watch(focusingFriendsProvider).asData?.value ?? const {};
    if (focusing.isEmpty) return const SizedBox.shrink();
    final friends = ref.watch(friendRowsProvider).asData?.value.accepted ?? const [];
    final names = [
      for (final row in friends)
        if (focusing.containsKey(row.profile.id)) row.profile.displayName,
    ];
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Clay(
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
              child: Text('Focusing now: ${names.join(', ')}', style: AppText.item.copyWith(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BossSection extends ConsumerWidget {
  const _BossSection({required this.boss, required this.now});

  final Boss? boss;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activeFightCountProvider).asData?.value ?? 0;
    final maxFights = ref.watch(maxActiveFightsProvider).asData?.value ?? 15;
    final atLimit = activeCount >= maxFights;

    if (boss == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Clay(
              radius: AppRadius.stage,
              onTap: atLimit ? null : () => context.go('/bosses/new'),
              semanticLabel: atLimit ? null : 'Create boss',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(122, 22, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Got a deadline coming up?', style: AppText.title),
                    const SizedBox(height: 4),
                    Text(
                      atLimit ? 'You already have $maxFights active fights.' : 'Turn it into a boss.',
                      style: AppText.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(left: 22, top: 12, child: BossPortal(neutral: true)),
            const Positioned(
              left: 4,
              top: -36,
              child: IgnorePointer(child: BossArt(tier: 'brute', greyed: true)),
            ),
          ],
        ),
      );
    }
    final hp = boss!.maxHp <= 0 ? 0.0 : 1 - (boss!.damage / boss!.maxHp);
    final hpLeft = (boss!.maxHp - boss!.damage).clamp(0, boss!.maxHp);
    return BossCard(
      name: boss!.name,
      tier: boss!.tier,
      hp: hp.clamp(0.0, 1.0),
      timeLeft: _timeLeft(boss!.deadline, now),
      status: boss!.status[0].toUpperCase() + boss!.status.substring(1),
      eyebrow: 'Closest boss',
      hpLabel: '${thousands(hpLeft)} / ${thousands(boss!.maxHp)} HP',
      onTap: () => context.go('/bosses/${boss!.id}'),
    );
  }
}
