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
import '../../core/widgets/clay.dart';
import '../../core/theme/app_colors.dart';

/// Solo bosses and raids (party raids and guild battles) by deadline.
class BossesScreen extends ConsumerWidget {
  const BossesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bossesProvider);
    final activeCount = ref.watch(activeFightCountProvider).asData?.value ?? 0;
    final maxFights = ref.watch(maxActiveFightsProvider).asData?.value ?? 15;
    final atLimit = activeCount >= maxFights;
    final now = DateTime.now();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s8),
      child: ScreenTitle(
        kicker: '$activeCount of $maxFights fights',
        kickerColor: atLimit ? AppColors.errorText : AppColors.inkMuted,
        title: 'Bosses',
        trailing: ClayPill(
          label: 'Join raid',
          icon: Icons.qr_code_scanner_rounded,
          height: 44,
          onPressed: () => context.go('/raids/join'),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            async.when(
              loading: () => Column(children: [header, const Expanded(child: LoadingSkeleton())]),
              error: (error, _) => Column(
                children: [
                  header,
                  EmptyState(
                    title: 'Could not load bosses',
                    body: 'Check your connection and try again.',
                    icon: Icons.cloud_off_rounded,
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(bossesProvider),
                  ),
                ],
              ),
              data: (bosses) {
                final raids = ref.watch(myRaidsProvider).asData?.value ?? const <RaidSummary>[];
                final results = [
                  for (final b in bosses)
                    if ((b.status == 'defeated' || b.status == 'escaped') && !b.resultSeen) b,
                ];
                final fights = [for (final b in bosses) if (!results.contains(b)) b];
                Boss? featured;
                for (final b in fights) {
                  if (b.status != 'defeated' && b.status != 'escaped') {
                    featured = b;
                    break;
                  }
                }
                final rest = [for (final b in fights) if (b != featured) b];
                // Solo bosses and active raids share one list, soonest deadline first.
                final allFights = <({DateTime deadline, Widget tile})>[
                  for (final boss in rest) (deadline: boss.deadline, tile: _BossTile(boss: boss, now: now)),
                  for (final raid in raids)
                    if (raid.isActive) (deadline: raid.raid.deadline, tile: _RaidTile(summary: raid, now: now)),
                ]..sort((a, b) => a.deadline.compareTo(b.deadline));
                final finishedRaids = [for (final raid in raids) if (!raid.isActive) raid]
                  ..sort((a, b) => b.raid.deadline.compareTo(a.raid.deadline));
                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.aboveDockedButton + 40),
                  children: [
                    header,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (atLimit)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.s8),
                              child: Text(
                                'You have $maxFights active fights. Finish or wait for one to end before summoning another.',
                                style: AppText.bodySmall,
                              ),
                            ),
                          for (final boss in results) ...[
                            const SizedBox(height: AppSpacing.s12),
                            _ResultRow(boss: boss),
                          ],
                          if (bosses.isEmpty && raids.isEmpty) ...[
                            const SizedBox(height: 64),
                            const _EmptyArena(),
                          ],
                          if (featured != null) ...[
                            const SizedBox(height: 72),
                            _FeaturedFight(boss: featured, now: now),
                          ],
                          if (allFights.isNotEmpty) ...[
                            SizedBox(height: featured == null ? 24 : 32),
                            SectionLabel(
                              label: 'All fights · by deadline',
                              count: '${allFights.length}',
                              gemColor: AppColors.bossHp,
                            ),
                            const SizedBox(height: 14),
                            for (final fight in allFights) ...[
                              fight.tile,
                              const SizedBox(height: 14),
                            ],
                          ],
                          if (finishedRaids.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionLabel(
                              label: 'Finished raids',
                              count: '${finishedRaids.length}',
                              gemColor: AppColors.rare,
                            ),
                            const SizedBox(height: 14),
                            for (final raid in finishedRaids) ...[
                              _RaidTile(summary: raid, now: now),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            DockedAction(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: QButton(
                      label: 'Start raid',
                      variant: QButtonVariant.secondary,
                      height: 60,
                      onPressed: atLimit ? null : () => context.go('/raids/new'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    flex: 3,
                    child: QButton(
                      label: 'New boss',
                      icon: Icons.add_rounded,
                      onPressed: atLimit ? null : () => context.go('/bosses/new'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tierLabel(String tier) => tier.isEmpty ? tier : tier.toUpperCase();

String _typeLabel(String type) =>
    type.isEmpty ? type : type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ');

/// Lavender arena the featured boss stands in.
class _Arena extends StatelessWidget {
  const _Arena({this.empty = false});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: RadialGradient(
          center: const Alignment(0, 0.4),
          radius: 0.9,
          colors: empty
              ? const [Color(0xFFF7F7FC), Color(0xFFE6E8F4), Color(0xFFC9CDE3)]
              : const [Color(0xFFF4F3FF), Color(0xFFD9DBF7), Color(0xFF9EA3DA)],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, 0.9),
        child: Container(
          width: 180,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.elliptical(90, 18)),
            gradient: RadialGradient(
              colors: empty
                  ? [const Color(0x382B3168), const Color(0x002B3168)]
                  : [AppColors.bossHp.withValues(alpha: 0.6), AppColors.bossHp.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedFight extends StatelessWidget {
  const _FeaturedFight({required this.boss, required this.now});

  final Boss boss;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hpLeft = (boss.maxHp - boss.damage).clamp(0, boss.maxHp);
    final hp = boss.maxHp <= 0 ? 0.0 : hpLeft / boss.maxHp;
    final time = bossTimeLeft(boss.deadline, now);
    return Semantics(
      button: true,
      label: '${boss.name}, ${boss.tier}, $hpLeft of ${boss.maxHp} HP, $time',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Clay(
            radius: AppRadius.stage,
            padding: const EdgeInsets.all(8),
            onTap: () => context.go('/bosses/${boss.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Arena(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(boss.name, style: AppText.h2.copyWith(fontSize: 20, height: 26 / 20)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TierTag(tier: boss.tier),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_typeLabel(boss.type), style: AppText.caption)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'HP',
                            style: AppText.caption.copyWith(
                              fontFamily: AppText.sora,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: AppColors.bossHpText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: ClayBar(value: hp, gradient: hpFillGradient, height: 18)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppText.bodySmall,
                                children: [
                                  TextSpan(
                                    text: '$hpLeft',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                  TextSpan(text: ' / ${boss.maxHp} HP'),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            bossStatusLabel(boss.status),
                            style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.bossHpText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -62,
            child: IgnorePointer(child: Center(child: BossArt(tier: boss.tier, size: 196))),
          ),
          Positioned(right: 20, top: 20, child: _TimeChip(label: time)),
        ],
      ),
    );
  }
}

class _TierTag extends StatelessWidget {
  const _TierTag({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bossHpSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          _tierLabel(tier),
          style: AppText.caption.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: AppColors.bossHpText,
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, this.small = false});

  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: small ? 22 : 28,
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.bossHpSoft,
        borderRadius: BorderRadius.circular(14),
        boxShadow: small ? null : const [BoxShadow(color: Color(0x1F101935), offset: Offset(1, 3), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: small ? 12 : 14, color: AppColors.bossHpText),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.caption.copyWith(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.bossHpText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.boss});

  final Boss boss;

  @override
  Widget build(BuildContext context) {
    final defeated = boss.status == 'defeated';
    return Clay(
      radius: 26,
      height: 84,
      onTap: () => context.go('/bosses/${boss.id}/result'),
      padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        defeated ? AppColors.legendarySoft : AppColors.bossHpSoft,
                        (defeated ? AppColors.legendarySoft : AppColors.bossHpSoft).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                BossArt(tier: boss.tier, size: 64, greyed: !defeated),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  defeated ? 'BOSS DEFEATED' : 'BOSS ESCAPED',
                  style: AppText.label.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: defeated ? AppColors.tealDeep : AppColors.bossHpText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  boss.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Clay(
            kind: defeated ? ClayKind.teal : ClayKind.control,
            radius: 20,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                defeated ? 'Claim' : 'See',
                style: AppText.title.copyWith(fontSize: 14, color: defeated ? AppColors.white : AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArena extends StatelessWidget {
  const _EmptyArena();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Clay(
          radius: AppRadius.stage,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [
              const _Arena(empty: true),
              const SizedBox(height: 18),
              Text('No bosses yet', style: AppText.h2.copyWith(fontSize: 20)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Turn a deadline into one. Every focused minute on it is a hit.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: -50,
          child: IgnorePointer(child: Center(child: BossArt(tier: 'brute', size: 180, greyed: true))),
        ),
      ],
    );
  }
}

class _BossTile extends StatelessWidget {
  const _BossTile({required this.boss, required this.now});

  final Boss boss;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hpLeft = (boss.maxHp - boss.damage).clamp(0, boss.maxHp);
    final hp = boss.maxHp <= 0 ? 0.0 : hpLeft / boss.maxHp;
    final openResult = (boss.status == 'defeated' || boss.status == 'escaped') && !boss.resultSeen;
    final time = bossTimeLeft(boss.deadline, now);
    return Semantics(
      button: true,
      label: '${boss.name}, ${boss.tier}, $hpLeft of ${boss.maxHp} HP, $time',
      excludeSemantics: true,
      child: Clay(
        radius: 26,
        onTap: () => context.go(openResult ? '/bosses/${boss.id}/result' : '/bosses/${boss.id}'),
        padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const BossPortal(size: 64),
                  Positioned(top: -14, child: BossArt(tier: boss.tier, size: 80)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    boss.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TierTag(tier: boss.tier),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bossStatusLabel(boss.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption,
                        ),
                      ),
                      _TimeChip(label: time, small: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClayBar(value: hp, gradient: hpFillGradient, height: 8),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: AppText.caption,
                      children: [
                        TextSpan(
                          text: '$hpLeft',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        TextSpan(text: ' / ${boss.maxHp} HP'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A party raid or guild battle in the fight list.
class _RaidTile extends StatelessWidget {
  const _RaidTile({required this.summary, required this.now});

  final RaidSummary summary;
  final DateTime now;

  static const _avatarStats = ['charisma', 'intellect', 'craft', 'vitality'];

  String get _resultLabel => switch (summary.raid.status) {
        'victory' => 'Victory',
        'narrow_win' => 'Narrow win',
        'escaped' => 'Escaped',
        _ => 'Active',
      };

  @override
  Widget build(BuildContext context) {
    final raid = summary.raid;
    final hpLeft = summary.hpLeft;
    final hp = raid.maxHp <= 0 ? 0.0 : hpLeft / raid.maxHp;
    final kind = summary.isGuild ? 'GUILD BATTLE' : 'PARTY RAID';
    final time = summary.isActive ? bossTimeLeft(raid.deadline, now) : _resultLabel;
    return Semantics(
      button: true,
      label: '${summary.isGuild ? 'Guild battle' : 'Party raid'}: ${raid.name}, ${raid.tier}, '
          '$hpLeft of ${raid.maxHp} HP, ${summary.members.length} members, $time',
      excludeSemantics: true,
      child: Clay(
        radius: 26,
        onTap: () => context.go(summary.isActive ? '/raids/${raid.id}' : '/raids/${raid.id}/results'),
        padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const BossPortal(size: 64),
                  Positioned(
                    top: -14,
                    child: Opacity(
                      opacity: summary.isActive ? 1 : 0.55,
                      child: BossArt(tier: raid.tier, size: 80),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(raid.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TierTag(tier: raid.tier),
                      const SizedBox(width: 6),
                      Flexible(
                        flex: 5,
                        child: Container(
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            color: summary.isGuild ? AppColors.tealSoft : AppColors.raritySoft('rare'),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            kind,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label.copyWith(
                              fontSize: 9,
                              height: 12 / 9,
                              color: summary.isGuild ? AppColors.tealDeep : AppColors.rarityText('rare'),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 6),
                      _TimeChip(label: time, small: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClayBar(value: hp, gradient: hpFillGradient, height: 8),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final (i, name) in summary.members.take(4).indexed)
                        Align(
                          widthFactor: 0.75,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.stat(_avatarStats[i % _avatarStats.length]),
                              border: Border.all(color: AppColors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: AppText.label.copyWith(fontSize: 9, height: 10 / 9, color: AppColors.white),
                            ),
                          ),
                        ),
                      if (summary.members.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('+${summary.members.length - 4}', style: AppText.caption),
                        ),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          style: AppText.caption,
                          children: [
                            TextSpan(
                              text: '$hpLeft',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            TextSpan(text: ' / ${raid.maxHp} HP'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
