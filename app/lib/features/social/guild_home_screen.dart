import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import 'guild_emblems.dart';
import 'providers/guild_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Guild home: members, focusing dots, weekly quest and trophies.
class GuildHomeScreen extends ConsumerWidget {
  const GuildHomeScreen({super.key});

  String _crestShort(String emblem) {
    return emblem.startsWith('crest_') ? emblem.substring(6) : emblem;
  }

  String _wonLabel(DateTime? wonAt) {
    if (wonAt == null) return 'Raid win';
    final local = wonAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'Won $y-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(guildHomeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Guild', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/social'),
        ),
      ),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load guild',
          body: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(guildHomeProvider),
        ),
        data: (snap) {
          if (snap == null) {
            return EmptyState(
              title: 'Create or join a guild',
              body: 'Team up with friends for guild fights and a weekly quest.',
              actionLabel: 'Get started',
              onAction: () => context.go('/social/guild/new'),
            );
          }
          final guild = snap.guild;
          final progress = guild.questGoal <= 0
              ? 0.0
              : (guild.questProgress / guild.questGoal).clamp(0.0, 1.0);
          final focusingCount = snap.members.where((m) => m.focusing).length;
          final crest = _crestShort(guild.emblem);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              QCard(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.awakeningTeal.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.tealDeep, width: 2),
                      ),
                      child: Text(
                        crest,
                        style: AppText.h1.copyWith(color: AppColors.tealDeep),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(guild.name, style: AppText.h1, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        QChip(label: guildEmblemLabel(guild.emblem)),
                        QChip(
                          label: snap.members.length == 1
                              ? '1 member'
                              : '${snap.members.length} members',
                          selected: true,
                        ),
                        if (snap.isLeader) const QChip(label: 'Leader'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite code', style: AppText.caption),
                              Text(guild.inviteCode, style: AppText.title),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy code',
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: guild.inviteCode));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invite code copied')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Weekly quest', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              QCard(
                child: ProgressBar(
                  value: progress,
                  leading: 'Raw XP',
                  trailing: '${guild.questProgress} / ${guild.questGoal}',
                ),
              ),
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
              for (final view in snap.members) ...[
                MemberCard(
                  name: view.profile.displayName,
                  title: 'Level ${view.profile.level}',
                  skinId: assetShort(view.profile.equippedSkinId, 'skin_'),
                  backgroundId: assetShort(view.profile.equippedBackgroundId, 'bg_'),
                  frameId: assetShort(view.profile.equippedFrameId, 'frame_'),
                  body: bodyFromProfile(view.profile),
                  focusing: view.focusing,
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s16),
              Text('Trophies', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (snap.trophies.isEmpty)
                Text('Win a guild fight to earn a trophy.', style: AppText.bodySmall)
              else
                for (final trophy in snap.trophies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: QCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.legendary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            child: const Icon(Icons.emoji_events, color: AppColors.legendary),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trophy.name ?? 'Raid win', style: AppText.title),
                                Text(_wonLabel(trophy.wonAt), style: AppText.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.s24),
              QButton(
                label: 'Leave guild',
                variant: QButtonVariant.destructive,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Leave guild?', style: AppText.h2),
                      content: Text(
                        snap.isLeader
                            ? 'Leadership passes to the next member, or the guild is deleted if you are alone.'
                            : 'You can join another guild later with an invite code.',
                        style: AppText.body,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  try {
                    await ref.read(apiClientProvider).leaveGuild();
                    ref.invalidate(myGuildIdProvider);
                    ref.invalidate(guildHomeProvider);
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
