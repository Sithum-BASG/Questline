import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/motion/app_motion.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/raid_event.dart';
import '../../data/models/raid_member.dart';
import '../bosses/boss_time.dart';
import 'providers/raid_detail_providers.dart';
import 'raid_widgets.dart';

/// Live raid: the boss in its arena, HP, the party on stage, the battle log
/// and a docked Attack button.
class RaidDetailScreen extends ConsumerStatefulWidget {
  const RaidDetailScreen({super.key, required this.raidId});

  final String raidId;

  @override
  ConsumerState<RaidDetailScreen> createState() => _RaidDetailScreenState();
}

class _RaidDetailScreenState extends ConsumerState<RaidDetailScreen> {
  var _redirected = false;
  var _attacking = false;

  void _goResultsOnce() {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/raids/${widget.raidId}/results');
    });
  }

  /// Focus on your open raid task, finish a draft, or add a task to the raid.
  Future<void> _attack(String? myId) async {
    if (_attacking || myId == null) return;
    setState(() => _attacking = true);
    try {
      final rows = await ref
          .read(supabaseClientProvider)
          .from('tasks')
          .select('id, status')
          .eq('user_id', myId)
          .eq('raid_id', widget.raidId)
          .inFilter('status', ['open', 'draft'])
          .order('created_at', ascending: true);
      if (!mounted) return;
      final open = [
        for (final r in rows)
          if (r['status'] == 'open') r['id'] as String,
      ];
      final drafts = [
        for (final r in rows)
          if (r['status'] == 'draft') r['id'] as String,
      ];
      if (open.isNotEmpty) {
        context.go('/focus/start?taskId=${open.first}');
      } else if (drafts.isNotEmpty) {
        context.go('/quests/${drafts.first}');
      } else {
        context.go('/quests/new?raidId=${widget.raidId}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open your raid task.')));
      }
    } finally {
      if (mounted) setState(() => _attacking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raidId = widget.raidId;
    final async = ref.watch(raidDetailProvider(raidId));
    final rules = ref.watch(raidRulesProvider).asData?.value;

    return Scaffold(
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load raid',
          body: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(raidDetailProvider(raidId)),
        ),
        data: (snap) {
          if (snap == null) {
            return EmptyState(
              title: 'Raid not found',
              body: 'It may have been removed.',
              actionLabel: 'Back to bosses',
              onAction: () => context.go('/bosses'),
            );
          }
          final raid = snap.raid;
          if (raid.status != 'active') {
            _goResultsOnce();
            return const LoadingSkeleton();
          }
          final now = DateTime.now();
          final remaining = (raid.maxHp - raid.damage).clamp(0, raid.maxHp);
          final hp = raid.maxHp <= 0 ? 0.0 : remaining / raid.maxHp;
          final active = snap.members.where((m) => !m.leftRaid).toList();
          final isGuild = raid.source == 'guild';
          final canInvite = !isGuild && (raid.inviteCode ?? '').isNotEmpty;
          final fairShare = rules?.fairShare(raid.maxHp, raid.participants);
          final topInset = MediaQuery.paddingOf(context).top;
          final arenaHeight = 374 + topInset;

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(bottom: raidDockClearance(context)),
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: 0, right: 0, top: 0, height: arenaHeight, child: const RaidArena()),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: topInset + 40,
                        child: IgnorePointer(
                          child: Center(child: BossArt(tier: raid.tier, size: 280)),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.screen,
                        right: AppSpacing.screen,
                        top: topInset + 12,
                        child: ArenaTopBar(
                          pill: isGuild ? 'GUILD BATTLE' : 'PARTY RAID',
                          onBack: () => context.go('/bosses'),
                          action: canInvite
                              ? ClayIconButton(
                                  icon: Icons.person_add_alt_1_rounded,
                                  tooltip: 'Invite to party',
                                  kind: ClayKind.onScene,
                                  onPressed: () => context.go('/raids/$raidId/invite'),
                                )
                              : null,
                        ),
                      ),
                      if (snap.focusingIds.isNotEmpty || snap.reconnecting)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: arenaHeight - 84,
                          child: Center(
                            child: _LivePill(
                              label: snap.reconnecting ? 'Reconnecting…' : '${snap.focusingIds.length} focusing now',
                              live: !snap.reconnecting,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.screen, arenaHeight - 40, AppSpacing.screen, 0),
                        child: _BossBar(
                          name: raid.name,
                          tier: raid.tier,
                          subtitle: '${raid.title} · ${raidDueLabel(raid.deadline, now)}',
                          timeLeft: bossTimeLeft(raid.deadline, now),
                          hp: hp,
                          hpLeft: remaining,
                          maxHp: raid.maxHp,
                          dealt: raid.damage,
                          noCoins: !raid.coinsEligible,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Party · ${active.length}',
                              style: AppText.h2.copyWith(fontSize: 18, height: 24 / 18),
                            ),
                          ),
                        ),
                        if (fairShare != null)
                          Text('Fair share: ${formatCount(fairShare)} damage', style: AppText.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: _PartyStage(
                      members: active,
                      myId: snap.myId,
                      focusingIds: snap.focusingIds,
                      damageByUser: snap.damageByUser,
                      seats: raid.participants,
                      onInvite: canInvite ? () => context.go('/raids/$raidId/invite') : null,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: Semantics(
                      header: true,
                      child: Text('Battle log', style: AppText.h2.copyWith(fontSize: 18, height: 24 / 18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: _BattleLog(events: snap.events.take(8).toList(), myId: snap.myId, now: now),
                  ),
                ],
              ),
              RaidDock(
                child: QButton(
                  label: 'Attack',
                  icon: Icons.bolt_rounded,
                  height: 60,
                  loading: _attacking,
                  onPressed: _attacking ? null : () => _attack(snap.myId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label, required this.live});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Clay(
      kind: ClayKind.onScene,
      radius: 15,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.22), spreadRadius: 3)],
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: live ? AppColors.tealDeep : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Name, tier, countdown and the segmented HP bar.
class _BossBar extends StatelessWidget {
  const _BossBar({
    required this.name,
    required this.tier,
    required this.subtitle,
    required this.timeLeft,
    required this.hp,
    required this.hpLeft,
    required this.maxHp,
    required this.dealt,
    required this.noCoins,
  });

  final String name;
  final String tier;
  final String subtitle;
  final String timeLeft;
  final double hp;
  final int hpLeft;
  final int maxHp;
  final int dealt;
  final bool noCoins;

  @override
  Widget build(BuildContext context) {
    final strong = AppText.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink);
    return Clay(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(name, style: AppText.h1.copyWith(fontSize: 21, height: 26 / 21)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              RaidTierTag(tier: tier),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.bossHpSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: AppColors.bossHpText),
                    const SizedBox(width: 6),
                    Text(
                      timeLeft,
                      style: AppText.numbers.copyWith(fontSize: 13, height: 16 / 13, color: AppColors.bossHpText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'HP',
                style: AppText.numbers.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.bossHpText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  label: 'Raid boss HP',
                  value: '$hpLeft of $maxHp',
                  child: SizedBox(
                    height: 20,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClayBar(value: hp, gradient: hpFillGradient, height: 20),
                        const IgnorePointer(child: CustomPaint(painter: _HpTicksPainter())),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: AppText.bodySmall,
                    children: [
                      TextSpan(text: formatCount(hpLeft), style: strong),
                      TextSpan(text: ' / ${formatCount(maxHp)} HP'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: AppText.bodySmall,
                    children: [
                      TextSpan(text: formatCount(dealt), style: strong),
                      const TextSpan(text: ' dealt by the party'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (noCoins) ...[
            const SizedBox(height: 8),
            Text('No coins on victory (created under 48 hours).', style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// White tick marks every tenth of the HP bar.
class _HpTicksPainter extends CustomPainter {
  const _HpTicksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 3), Offset(x, size.height - 3), paint);
    }
  }

  @override
  bool shouldRepaint(_HpTicksPainter old) => false;
}

/// The party standing on a stage strip: you front-centre, two rows from five.
class _PartyStage extends StatelessWidget {
  const _PartyStage({
    required this.members,
    required this.myId,
    required this.focusingIds,
    required this.damageByUser,
    required this.seats,
    this.onInvite,
  });

  final List<RaidMember> members;
  final String? myId;
  final Set<String> focusingIds;
  final Map<String, int> damageByUser;
  final int seats;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final me = [
      for (final m in members)
        if (m.userId == myId) m,
    ];
    final others = [
      for (final m in members)
        if (m.userId != myId) m,
    ]..sort((a, b) => (damageByUser[b.userId] ?? -1).compareTo(damageByUser[a.userId] ?? -1));
    final n = members.length;
    final frontCount = n <= 4 ? n : (n + 1) ~/ 2;
    final front = [...others.take(frontCount - me.length)];
    if (me.isNotEmpty) front.insert(front.length ~/ 2, me.first);
    final back = others.skip(frontCount - me.length).toList();
    const stripHeight = 150.0;
    const overlap = 26.0;
    final waiting = seats - n;

    return Clay(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
      child: Column(
        children: [
          SizedBox(
            height: stripHeight + overlap,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: overlap,
                  height: stripHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const RadialGradient(
                        center: Alignment(0, 1.4),
                        radius: 1.3,
                        colors: [AppColors.white, AppColors.partyStripMid, AppColors.partyStripRim],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.04)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                    child: Stack(
                      children: [
                        if (back.isNotEmpty)
                          Positioned.fill(
                            top: -6,
                            child: _HeroRow(members: back, focusingIds: focusingIds, scale: 0.8, showDots: true),
                          ),
                        Positioned.fill(
                          top: back.isEmpty ? 0 : 26,
                          child: _HeroRow(members: front, focusingIds: focusingIds, scale: n <= 2 ? 1.1 : 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in front)
                Expanded(
                  child: Semantics(
                    label: _memberLabel(m),
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (focusingIds.contains(m.userId)) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.teal,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: AppColors.teal.withValues(alpha: 0.22), spreadRadius: 3),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                m.userId == myId ? 'You' : m.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title.copyWith(fontSize: 13, height: 16 / 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ShareMark(damage: damageByUser[m.userId], met: m.metFairShare),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (waiting > 0 && onInvite != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    waiting == 1 ? '1 seat still open' : '$waiting seats still open',
                    style: AppText.bodySmall,
                  ),
                ),
                ClayPill(
                  label: 'Invite',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.tealDeep,
                  onPressed: onInvite,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _memberLabel(RaidMember m) {
    final name = m.userId == myId ? 'You' : m.displayName;
    final damage = damageByUser[m.userId];
    final focusing = focusingIds.contains(m.userId) ? ', focusing now' : '';
    if (damage != null) return '$name, $damage damage$focusing';
    return '$name, ${m.metFairShare ? 'pulled their weight' : 'fighting'}$focusing';
  }
}

/// Exact damage when you may see it, otherwise the "pulled their weight" check.
class _ShareMark extends StatelessWidget {
  const _ShareMark({required this.damage, required this.met});

  final int? damage;
  final bool met;

  @override
  Widget build(BuildContext context) {
    if (damage != null) return DamageChip(amount: damage!, height: 22);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: met ? AppColors.tealSoft : AppColors.well,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_rounded : Icons.bolt_rounded,
            size: 13,
            color: met ? AppColors.tealDeep : AppColors.inkMuted,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              met ? 'Share met' : 'Fighting',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: met ? AppColors.tealDeep : AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-body heroes side by side, cut off by the bottom of the stage.
class _HeroRow extends StatelessWidget {
  const _HeroRow({required this.members, required this.focusingIds, this.scale = 1, this.showDots = false});

  final List<RaidMember> members;
  final Set<String> focusingIds;
  final double scale;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / (members.isEmpty ? 1 : members.length);
        final figure = (slot.clamp(0, 100) * 2.2 * scale).toDouble();
        return Row(
          children: [
            for (final m in members)
              SizedBox(
                width: slot,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    OverflowBox(
                      alignment: Alignment.topCenter,
                      maxWidth: figure,
                      maxHeight: figure * 1.5,
                      child: Image.asset(
                        GameAssets.skin(
                          (m.skinId ?? 'skin_starter').replaceFirst('skin_', ''),
                          m.bodyType == 'b' ? BodyType.b : BodyType.a,
                        ),
                        width: figure,
                        height: figure * 1.5,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    if (showDots && focusingIds.contains(m.userId))
                      Positioned(
                        top: 14,
                        left: slot / 2 + 12,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Latest hits, newest first.
class _BattleLog extends StatelessWidget {
  const _BattleLog({required this.events, required this.myId, required this.now});

  final List<RaidEvent> events;
  final String? myId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Well(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Text(
          'No hits yet. Focus on a raid task to deal damage.',
          style: AppText.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Clay(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (final (i, event) in events.indexed) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            TweenAnimationBuilder<double>(
              key: ValueKey(event.id),
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.raidTicker(context),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
              ),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppText.body.copyWith(fontSize: 14, height: 20 / 14, color: AppColors.inkMuted),
                          children: [
                            TextSpan(
                              text: event.userId == myId ? 'You' : event.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                            const TextSpan(text: ' hit for'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DamageChip(amount: event.amount),
                    SizedBox(
                      width: 48,
                      child: Text(raidAgo(event.at, now), textAlign: TextAlign.right, style: AppText.caption),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
