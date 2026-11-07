import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/badge_medallion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/stage_card.dart';
import '../../core/widgets/stat_radar.dart';
import '../../data/models/friend_summary.dart';
import '../../data/models/profile.dart';

String _short(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;

StatRadarValues _radarFromMap(Map<String, dynamic>? map) {
  if (map == null) return const StatRadarValues(intellect: 0, vitality: 0, craft: 0, charisma: 0);
  return StatRadarValues(
    intellect: (map['intellect'] as num?)?.toDouble() ?? 0,
    vitality: (map['vitality'] as num?)?.toDouble() ?? 0,
    craft: (map['craft'] as num?)?.toDouble() ?? 0,
    charisma: (map['charisma'] as num?)?.toDouble() ?? 0,
  );
}

final friendProfileProvider =
    FutureProvider.autoDispose.family<({Profile profile, FriendSummary? summary})?, String>((ref, uid) async {
  final client = ref.watch(supabaseClientProvider);
  final profileRow = await client
      .from('profiles')
      .select(
        'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at',
      )
      .eq('id', uid)
      .maybeSingle();
  if (profileRow == null) return null;
  final profile = Profile.fromJson(Map<String, dynamic>.from(profileRow));
  FriendSummary? summary;
  try {
    final summaryRow =
        await client.from('friend_summaries').select().eq('user_id', uid).maybeSingle();
    if (summaryRow != null) {
      summary = FriendSummary.fromJson(Map<String, dynamic>.from(summaryRow));
    }
  } catch (_) {
    // Strangers cannot read friend_summaries (RLS); profile alone still shows.
  }
  return (profile: profile, summary: summary);
});

/// Friend-facing profile: stage, weekly XP, radar unless hidden.
class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendProfileProvider(userId));
    return Scaffold(
      appBar: AppBar(title: Text('Friend', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load friend',
          body: 'They may have removed you, or you are offline.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(friendProfileProvider(userId)),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(title: 'Friend not found', body: 'This profile is not available.');
          }
          final profile = data.profile;
          final summary = data.summary;
          final body = profile.bodyType == 'b' ? BodyType.b : BodyType.a;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(profile.displayName, style: AppText.h1),
              Text('@${profile.username}', style: AppText.bodySmall),
              Text('Level ${profile.level}', style: AppText.caption),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: StageCard(
                  skinId: _short(profile.equippedSkinId, 'skin_'),
                  backgroundId: _short(profile.equippedBackgroundId, 'bg_'),
                  body: body,
                  size: StageCardSize.home,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('This week', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              Text(
                summary == null ? 'Weekly XP hidden' : '${summary.weeklyRawXp} raw XP',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Pinned badges', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (profile.pinnedBadges.isEmpty)
                Text('No badges pinned.', style: AppText.bodySmall)
              else
                Wrap(
                  spacing: AppSpacing.s12,
                  children: [
                    for (final id in profile.pinnedBadges)
                      BadgeMedallion(
                        id: _short(id, 'badge_'),
                        tier: 1,
                        caption: _short(id, 'badge_').replaceAll('_', ' '),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.s24),
              Text('Stats', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (profile.hideRadar || summary?.radar30 == null)
                Text(
                  profile.hideRadar ? 'Radar is hidden.' : 'Radar not available yet.',
                  style: AppText.bodySmall,
                )
              else
                StatRadar(
                  valuesFor30: _radarFromMap(summary!.radar30),
                  valuesFor7: _radarFromMap(summary.radar7),
                ),
            ],
          );
        },
      ),
    );
  }
}
