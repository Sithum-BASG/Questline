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
import '../../core/theme/shadows.dart';
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
                  children: [
                    Expanded(child: Semantics(header: true, child: Text('Hero', style: AppText.h1))),
                    ClayIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                _HeroStage(
                  skinId: _short(profile.equippedSkinId, 'skin_'),
                  backgroundId: _short(profile.equippedBackgroundId, 'bg_'),
                  body: body,
                  onChangeLook: () => context.go('/hero/wardrobe'),
                ),
                const SizedBox(height: 15),
                _Nameplate(name: profile.displayName, title: data.titleName, level: profile.level),
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
                const SizedBox(height: 28),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 96,
                  ),
                  children: [
                    _HeroTile(
                      label: 'Gear',
                      image: GameAssets.gear('weapon_apprentice_wand'),
                      onTap: () => context.go('/hero/gear'),
                    ),
                    _HeroTile(
                      label: 'Wardrobe',
                      image: GameAssets.icon('wardrobe'),
                      onTap: () => context.go('/hero/wardrobe'),
                    ),
                    _HeroTile(
                      label: 'Achievements',
                      image: GameAssets.badge('deep_worker', 1),
                      onTap: () => context.go('/hero/achievements'),
                    ),
                    _HeroTile(
                      label: 'Inventory',
                      image: GameAssets.icon('inventory'),
                      onTap: () => context.go('/hero/inventory'),
                    ),
                    _HeroTile(
                      label: 'Level road',
                      image: GameAssets.icon('level_road'),
                      imageSize: 46,
                      onTap: () => context.go('/hero/level-road'),
                    ),
                    _HeroTile(
                      label: 'Chests',
                      image: GameAssets.icon('chest'),
                      onTap: () => context.go('/chests'),
                    ),
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

/// Full stage: background fills the frame, the character stands on the floor
/// line at 88% so tall skins keep headroom. Nothing covers the character.
class _HeroStage extends StatelessWidget {
  const _HeroStage({
    required this.skinId,
    required this.backgroundId,
    required this.body,
    required this.onChangeLook,
  });

  final String skinId;
  final String backgroundId;
  final BodyType body;
  final VoidCallback onChangeLook;

  static const double _heroScale = 0.88;
  static const BorderRadius _inner = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    const canvas = GameAssets.stageCanvas;
    const feet = Alignment(0, GameAssets.skinFeetY / 1536 * 2 - 1);
    return Clay(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: canvas.width / canvas.height,
        child: ClipRRect(
          borderRadius: _inner,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(GameAssets.background(backgroundId), fit: BoxFit.cover),
              Transform.scale(
                scale: _heroScale,
                alignment: feet,
                child: Image.asset(
                  GameAssets.skin(skinId, body),
                  fit: BoxFit.cover,
                  semanticLabel: 'Your character',
                ),
              ),
              const IgnorePointer(
                child: CustomPaint(
                  painter: InnerShadowPainter(shadows: stageInnerShade, borderRadius: _inner),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: ClayIconButton(
                  kind: ClayKind.onScene,
                  icon: Icons.checkroom_rounded,
                  tooltip: 'Change look',
                  onPressed: onChangeLook,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Character sheet under the stage: level crest, name and title.
class _Nameplate extends StatelessWidget {
  const _Nameplate({required this.name, required this.title, required this.level});

  final String name;
  final String? title;
  final int level;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Clay(
            radius: AppRadius.feature,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 18),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24),
                ),
                if (titleText != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                    decoration: const BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: BorderRadius.all(Radius.circular(13)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.tealDeep),
                        const SizedBox(width: 5),
                        Text(
                          titleText,
                          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.tealDeep),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: -30,
            child: Semantics(
              label: 'Level $level',
              excludeSemantics: true,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: clayTealGradient,
                  border: Border.all(color: AppColors.white, width: 4),
                  boxShadow: AppShadows.tealButton,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('LV', style: AppText.label.copyWith(fontSize: 8, height: 10 / 8, color: AppColors.white)),
                    Text(
                      '$level',
                      style: AppText.h1.copyWith(fontSize: 21, height: 22 / 21, color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.label, required this.image, required this.onTap, this.imageSize = 44});

  final String label;
  final String image;
  final double imageSize;
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
            Image.asset(image, width: imageSize, height: imageSize),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 13, height: 16 / 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
