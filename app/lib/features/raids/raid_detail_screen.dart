import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'providers/raid_detail_providers.dart';

/// Live raid HP, members with focusing dots, and damage ticker.
class RaidDetailScreen extends ConsumerWidget {
  const RaidDetailScreen({super.key, required this.raidId});

  final String raidId;

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
          final hp = raid.maxHp <= 0 ? 0.0 : (1 - raid.damage / raid.maxHp).clamp(0.0, 1.0);
          final activeMembers = snap.members.where((m) => !m.leftRaid).toList();
          final alone = activeMembers.length <= 1 && snap.isCreator;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Text(raid.name, style: AppText.h1),
              Text(raid.title, style: AppText.bodySmall),
              const SizedBox(height: AppSpacing.s16),
              ProgressBar(
                value: hp,
                kind: ProgressKind.bossHp,
                leading: 'HP',
                trailing: '${raid.maxHp - raid.damage} / ${raid.maxHp}',
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Due ${raid.deadline.toLocal()}'.split('.').first,
                style: AppText.caption,
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
              Text('Members', style: AppText.h2),
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
                  body: member.bodyType == 'b' ? BodyType.b : BodyType.a,
                  focusing: snap.focusingIds.contains(member.userId),
                  pulledWeight: member.metFairShare,
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s16),
              Text('Damage ticker', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (snap.events.isEmpty)
                Text('No hits yet. Start a focus session on a raid task.', style: AppText.bodySmall)
              else
                for (final event in snap.events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: QCard(
                      child: Text(
                        '${event.displayName} hit for ${event.amount}',
                        style: AppText.body,
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
