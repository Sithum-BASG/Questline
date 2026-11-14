import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/badge_medallion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/stage_card.dart';
import '../../core/widgets/stat_radar.dart';
import '../../core/widgets/clay.dart';
import '../../core/theme/app_colors.dart';
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
        bottom: false,
        child: async.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => Center(
            child: EmptyState(
              title: 'Could not load profile',
              body: 'Check your connection and try again.',
              icon: Icons.cloud_off_rounded,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(profileViewProvider),
            ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName, style: AppText.h1, softWrap: true),
                          if (data.titleName != null) ...[
                            const SizedBox(height: 2),
                            Text(data.titleName!, style: AppText.bodySmall, softWrap: true),
                          ],
                        ],
                      ),
                    ),
                    ClayIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Clay(
                      radius: AppRadius.hero,
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: Image.asset(
                            GameAssets.background(_short(profile.equippedBackgroundId, 'bg_')),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: IgnorePointer(
                        child: StageCard(
                          skinId: _short(profile.equippedSkinId, 'skin_'),
                          backgroundId: _short(profile.equippedBackgroundId, 'bg_'),
                          body: body,
                          size: StageCardSize.home,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: 18,
                      child: Clay(
                        kind: ClayKind.tealOnScene,
                        radius: 18,
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'Level ${profile.level}',
                            style: AppText.title.copyWith(fontSize: 14, color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1,
                  clipBehavior: Clip.none,
                  children: [
                    _HeroTile(
                      label: 'Gear',
                      icon: Icons.shield_rounded,
                      light: AppColors.rare.withValues(alpha: 0.5),
                      deep: AppColors.rare,
                      onTap: () => context.go('/hero/gear'),
                    ),
                    _HeroTile(
                      label: 'Wardrobe',
                      icon: Icons.checkroom_rounded,
                      light: AppColors.charismaLight,
                      deep: AppColors.charisma,
                      onTap: () => context.go('/hero/wardrobe'),
                    ),
                    _HeroTile(
                      label: 'Inventory',
                      icon: Icons.backpack_rounded,
                      light: AppColors.craftLight,
                      deep: AppColors.craft,
                      onTap: () => context.go('/hero/inventory'),
                    ),
                    _HeroTile(
                      label: 'Chests',
                      icon: Icons.inventory_2_rounded,
                      light: AppColors.legendary.withValues(alpha: 0.55),
                      deep: AppColors.legendaryText,
                      onTap: () => context.go('/chests'),
                    ),
                    _HeroTile(
                      label: 'Level road',
                      icon: Icons.route_rounded,
                      light: AppColors.tealLight,
                      deep: AppColors.tealDeep,
                      onTap: () => context.go('/hero/level-road'),
                    ),
                    _HeroTile(
                      label: 'Achievements',
                      icon: Icons.emoji_events_rounded,
                      light: AppColors.epic.withValues(alpha: 0.5),
                      deep: AppColors.epic,
                      onTap: () => context.go('/hero/achievements'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Semantics(header: true, child: Text('Pinned badges', style: AppText.h2)),
                const SizedBox(height: AppSpacing.s12),
                QCard(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: profile.pinnedBadges.isEmpty
                      ? Text(
                          'Pin up to 3 from Achievements.',
                          style: AppText.bodySmall,
                          textAlign: TextAlign.center,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final id in profile.pinnedBadges)
                              BadgeMedallion(
                                id: _short(id, 'badge_'),
                                tier: data.badgeTiers[id] ?? 1,
                                caption: _short(id, 'badge_').replaceAll('_', ' '),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
                Semantics(header: true, child: Text('Stats', style: AppText.h2)),
                const SizedBox(height: AppSpacing.s12),
                QCard(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: profile.hideRadar
                      ? Text('Radar hidden in settings.', style: AppText.bodySmall, textAlign: TextAlign.center)
                      : StatRadar(valuesFor30: data.radar30, valuesFor7: data.radar7),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.label,
    required this.icon,
    required this.light,
    required this.deep,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color light;
  final Color deep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Clay(
        radius: AppRadius.card,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClayDot(size: 44, gradient: dotGradient(light, deep), icon: icon, iconSize: 22),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
