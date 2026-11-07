import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'guild_emblems.dart';
import 'providers/guild_providers.dart';

/// Guild home: members, focusing dots, weekly quest and trophies.
class GuildHomeScreen extends ConsumerWidget {
  const GuildHomeScreen({super.key});

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
        loading: () => const Center(child: CircularProgressIndicator()),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Text(guild.name, style: AppText.h1),
              Text(guildEmblemLabel(guild.emblem), style: AppText.caption),
              const SizedBox(height: AppSpacing.s12),
              QCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invite code', style: AppText.title),
                          Text(guild.inviteCode, style: AppText.body),
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
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Weekly quest', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              ProgressBar(
                value: progress,
                leading: 'Raw XP',
                trailing: '${guild.questProgress} / ${guild.questGoal}',
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Members', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              for (final view in snap.members) ...[
                MemberCard(
                  name: view.profile.displayName,
                  title: 'Level ${view.profile.level}',
                  skinId: assetShort(view.profile.equippedSkinId, 'skin_'),
                  backgroundId: assetShort(view.profile.equippedBackgroundId, 'bg_'),
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
                      child: Text(trophy.name ?? 'Raid win', style: AppText.body),
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
