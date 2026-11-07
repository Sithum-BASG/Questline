import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import '../bosses/boss_time.dart';
import 'providers/raid_detail_providers.dart';

/// Live raid HP, members with focusing dots, and damage ticker.
class RaidDetailScreen extends ConsumerWidget {
  const RaidDetailScreen({super.key, required this.raidId});

  final String raidId;

  static String _label(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(raidDetailProvider(raidId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Raid', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bosses'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/raids/$raidId/results');
            });
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
              // Boss art sits on a light card so indigo ink stays readable (UI brief §5.4).
              QCard(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Image.asset(
                        GameAssets.boss(raid.tier),
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(raid.name, style: AppText.h1, textAlign: TextAlign.center),
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
              if (alone) ...[
                const SizedBox(height: AppSpacing.s16),
                QCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite teammates', style: AppText.h2),
                      const SizedBox(height: AppSpacing.s8),
                      Text('Share the invite so others can join.', style: AppText.bodySmall),
                      const SizedBox(height: AppSpacing.s12),
                      QButton(
                        label: 'Open invite',
                        onPressed: () => context.go('/raids/$raidId/invite'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Expanded(child: Text('Members', style: AppText.h2)),
                  if (focusingCount > 0)
                    QChip(
                      label: focusingCount == 1 ? '1 focusing' : '$focusingCount focusing',
                      selected: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
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
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s16),
              Text('Damage ticker', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (ticker.isEmpty)
                Text('No hits yet. Start a focus session on a raid task.', style: AppText.bodySmall)
              else
                for (final event in ticker)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: QCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${event.displayName} hit',
                              style: AppText.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '−${event.amount}',
                            style: AppText.numbers.copyWith(color: AppColors.bossHp),
                          ),
                        ],
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
