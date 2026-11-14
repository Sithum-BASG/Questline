import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import '../bosses/boss_time.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/boss_card.dart';
import 'providers/raid_detail_providers.dart';

/// Live raid HP, members with focusing dots, and damage ticker.
class RaidDetailScreen extends ConsumerStatefulWidget {
  const RaidDetailScreen({super.key, required this.raidId});

  final String raidId;

  @override
  ConsumerState<RaidDetailScreen> createState() => _RaidDetailScreenState();
}

class _RaidDetailScreenState extends ConsumerState<RaidDetailScreen> {
  var _redirected = false;

  static String _label(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _goResultsOnce() {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/raids/${widget.raidId}/results');
    });
  }

  @override
  Widget build(BuildContext context) {
    final raidId = widget.raidId;
    final async = ref.watch(raidDetailProvider(raidId));

    return Scaffold(
      appBar: ClayHeader(
        title: 'Raid',
        onBack: () => context.go('/bosses'),
      ),
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
            return const EmptyState(title: 'Raid not found', body: 'It may have been removed.');
          }
          final raid = snap.raid;
          if (raid.status != 'active') {
            _goResultsOnce();
            return const LoadingSkeleton();
          }
          final remaining = (raid.maxHp - raid.damage).clamp(0, raid.maxHp);
          final hp = raid.maxHp <= 0 ? 0.0 : remaining / raid.maxHp;
          final activeMembers = snap.members.where((m) => !m.leftRaid).toList();
          final alone = activeMembers.length <= 1 && snap.isCreator;
          final focusingCount = snap.focusingIds.length;
          final now = DateTime.now();
          final ticker = snap.events.take(5).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              if (snap.reconnecting) ...[
                Well(
                  radius: AppRadius.pill,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Reconnecting…',
                    style: AppText.bodySmall.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              const SizedBox(height: 56),
              Stack(
                clipBehavior: Clip.none,
                children: [
              QCard(
                radius: AppRadius.stage,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const RadialGradient(
                          center: Alignment(0, 0.4),
                          radius: 0.9,
                          colors: [Color(0xFFF4F3FF), Color(0xFFD9DBF7), Color(0xFF9EA3DA)],
                          stops: [0, 0.42, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                      child: Column(
                        children: [
                    Text(raid.name, style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s4),
                    Text(raid.title, style: AppText.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        QChip(label: _label(raid.source), selected: true),
                        QChip(label: bossStatusLabel(raid.status)),
                        QChip(label: _label(raid.tier)),
                        QChip(label: _label(raid.type)),
                        QChip(label: bossTimeLeft(raid.deadline, now)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    ProgressBar(
                      value: hp.clamp(0.0, 1.0),
                      kind: ProgressKind.bossHp,
                      height: 18,
                      trailingColor: AppColors.ink,
                      leading: 'HP',
                      trailing: '$remaining / ${raid.maxHp} HP',
                    ),
                    if (!raid.coinsEligible) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'No coins on victory (created under 48 hours).',
                        style: AppText.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -56,
                    child: IgnorePointer(child: Center(child: BossArt(tier: raid.tier, size: 210))),
                  ),
                ],
              ),
              if (alone) ...[
                const SizedBox(height: AppSpacing.s16),
                QCard(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite teammates', style: AppText.h2),
                      const SizedBox(height: AppSpacing.s8),
                      Text('Share the invite so others can join.', style: AppText.bodySmall),
                      const SizedBox(height: AppSpacing.s12),
                      QButton(
                        height: 52,
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Open invite',
                        onPressed: () => context.go('/raids/$raidId/invite'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text('Members', style: AppText.h2))),
                  if (focusingCount > 0)
                    QChip(
                      label: focusingCount == 1 ? '1 focusing' : '$focusingCount focusing',
                      selected: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              for (final member in snap.members) ...[
                MemberCard(
                  name: member.displayName,
                  title: member.leftRaid
                      ? 'Left'
                      : member.metFairShare
                          ? 'Pulled their weight'
                          : 'Fighting',
                  skinId: (member.skinId ?? 'skin_starter').replaceFirst('skin_', ''),
                  backgroundId: 'starter',
                  frameId: (member.frameId ?? 'frame_apprentice').replaceFirst('frame_', ''),
                  body: member.bodyType == 'b' ? BodyType.b : BodyType.a,
                  focusing: snap.focusingIds.contains(member.userId),
                  pulledWeight: member.metFairShare,
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              const SizedBox(height: AppSpacing.s20),
              Semantics(header: true, child: Text('Damage ticker', style: AppText.h2)),
              const SizedBox(height: AppSpacing.s12),
              if (ticker.isEmpty)
                Well(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No hits yet. Start a focus session on a raid task.',
                    style: AppText.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final event in ticker)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(event.id),
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.raidTicker(context),
                      curve: Curves.easeOut,
                      builder: (context, t, child) {
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 12),
                            child: child,
                          ),
                        );
                      },
                      child: Clay(
                        kind: ClayKind.control,
                        radius: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 18, color: AppColors.bossHp),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${event.displayName} hit',
                                style: AppText.item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '−${event.amount}',
                              style: AppText.numbers.copyWith(color: AppColors.bossHpText),
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
