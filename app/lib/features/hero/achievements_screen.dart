import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/badge_medallion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import 'achievement_copy.dart';
import 'providers/achievements_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Badges with pin (max 3) and owned titles to equip.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String? _error;
  var _busy = false;

  Future<void> _togglePin(BadgeProgress badge, List<String> pinned) async {
    if (badge.tier < 1) {
      setState(() => _error = 'Earn Tier I before pinning this badge.');
      return;
    }
    final next = togglePinnedBadge(pinned, badge.badgeId);
    if (next == null) {
      setState(() => _error = 'Unpin one first — you can pin up to 3.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(achievementsRepositoryProvider).setPinnedBadges(next);
      invalidateAchievementViews(ref);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not update pinned badges.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _equipTitle(String? titleId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(achievementsRepositoryProvider).setTitleId(titleId);
      invalidateAchievementViews(ref);
    } catch (_) {
      if (mounted) setState(() => _error = 'You need to own that title first.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementsViewProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Achievements', style: AppText.h2)),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load achievements',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(achievementsViewProvider),
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Text('Badges', style: AppText.h2),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Pin up to 3 earned badges on your profile.',
                style: AppText.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s16,
                runSpacing: AppSpacing.s16,
                children: [
                  for (final badge in data.badges)
                    _BadgeTile(
                      badge: badge,
                      pinned: data.pinnedBadges.contains(badge.badgeId),
                      enabled: !_busy,
                      onTap: () => _togglePin(badge, data.pinnedBadges),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s32),
              Text('Titles', style: AppText.h2),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Shown under your name on your profile and the leaderboard.',
                style: AppText.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              if (data.titles.isEmpty)
                const QCard(
                  child: Text(
                    'Titles unlock from Tier III badges and level rewards.',
                    style: AppText.bodySmall,
                  ),
                )
              else ...[
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final title in data.titles)
                      QChip(
                        label: title.name,
                        selected: data.equippedTitleId == title.id,
                        onTap: _busy ? null : () => _equipTitle(title.id),
                      ),
                  ],
                ),
                if (data.equippedTitleId != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  QButton(
                    label: 'Clear title',
                    variant: QButtonVariant.secondary,
                    onPressed: _busy ? null : () => _equipTitle(null),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s16),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.pinned,
    required this.enabled,
    required this.onTap,
  });

  final BadgeProgress badge;
  final bool pinned;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = badgeProgressFraction(
      badgeId: badge.badgeId,
      progress: badge.progress,
      tier: badge.tier,
    );
    return Semantics(
      button: true,
      selected: pinned,
      label: '${badge.name}, tier ${badge.tier}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeMedallion(
                id: badgeShortId(badge.badgeId),
                tier: badge.tier,
                progress: badge.tier < 3 ? fraction : null,
                size: 80,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(badge.name, style: AppText.caption),
              Text(
                badgeProgressLabel(
                  badgeId: badge.badgeId,
                  progress: badge.progress,
                  tier: badge.tier,
                ),
                style: AppText.caption.copyWith(color: AppColors.inkMuted),
              ),
              if (pinned)
                Text(
                  'Pinned',
                  style: AppText.caption.copyWith(color: AppColors.tealDeep),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
