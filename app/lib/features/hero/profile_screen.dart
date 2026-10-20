import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/badge_medallion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/stage_card.dart';
import '../../core/widgets/stat_radar.dart';
import 'providers/profile_providers.dart';

String _short(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;

/// Hero tab profile: stage, title, pinned badges, radar 30/7.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileViewProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Could not load profile',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(profileViewProvider),
          ),
          data: (data) {
            final profile = data.profile;
            final body = profile.bodyType == 'b' ? BodyType.b : BodyType.a;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s16,
                AppSpacing.screen,
                AppSpacing.aboveTabBar,
              ),
              children: [
                Text(profile.displayName, style: AppText.h1),
                if (data.titleName != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(data.titleName!, style: AppText.bodySmall),
                ],
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
                Text('Pinned badges', style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                if (profile.pinnedBadges.isEmpty)
                  Text('Pin up to 3 from Achievements.', style: AppText.bodySmall)
                else
                  Wrap(
                    spacing: AppSpacing.s12,
                    children: [
                      for (final id in profile.pinnedBadges)
                        BadgeMedallion(
                          id: _short(id, 'badge_'),
                          tier: data.badgeTiers[id] ?? 1,
                          caption: _short(id, 'badge_').replaceAll('_', ' '),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.s24),
                Text('Stats', style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                if (profile.hideRadar)
                  Text('Radar hidden in settings.', style: AppText.bodySmall)
                else
                  StatRadar(valuesFor30: data.radar30, valuesFor7: data.radar7),
                const SizedBox(height: AppSpacing.s24),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    QButton(label: 'Gear', variant: QButtonVariant.secondary, onPressed: () => context.go('/hero/gear')),
                    QButton(label: 'Wardrobe', variant: QButtonVariant.secondary, onPressed: () => context.go('/hero/wardrobe')),
                    QButton(label: 'Inventory', variant: QButtonVariant.secondary, onPressed: () => context.go('/hero/inventory')),
                    QButton(label: 'Chests', variant: QButtonVariant.secondary, onPressed: () => context.go('/chests')),
                    QButton(label: 'Level road', variant: QButtonVariant.secondary, onPressed: () => context.go('/hero/level-road')),
                    QButton(label: 'Achievements', variant: QButtonVariant.secondary, onPressed: () => context.go('/hero/achievements')),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
