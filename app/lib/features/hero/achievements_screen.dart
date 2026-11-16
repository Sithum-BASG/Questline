import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import 'achievement_copy.dart';
import 'providers/achievements_providers.dart';
import 'package:questline/core/assets/decode_size.dart';

/// Coins for tiers I, II, III from game_config.
final badgeTierCoinsProvider = FutureProvider<List<int>>((ref) {
  return ref.watch(gameConfigReaderProvider).badgeTierCoins();
});

/// What each badge counts, and the unit shown after its numbers.
const _badgeBlurb = <String, ({String text, String unit})>{
  'badge_deep_worker': (text: 'Hours of verified focus', unit: ' h'),
  'badge_boss_hunter': (text: 'Bosses defeated', unit: ''),
  'badge_team_player': (text: 'Raids won', unit: ''),
  'badge_unbroken': (text: 'Longest streak', unit: ' d'),
  'badge_balanced': (text: 'Weeks with every stat in play', unit: ' wk'),
  'badge_early_bird': (text: 'Sessions started early in the day', unit: ''),
  'badge_steady_pace': (text: 'Weeks with focus most days', unit: ' wk'),
  'badge_punctual': (text: 'Dated quests done on time', unit: ''),
};

const _romans = ['I', 'II', 'III'];

/// Badges with progress, tier rewards and pinning (up to 3).
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementsViewProvider);
    final coins = ref.watch(badgeTierCoinsProvider).asData?.value ?? const [50, 100, 200];
    return Scaffold(
      appBar: const ClayHeader(title: 'Achievements'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load achievements',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(achievementsViewProvider),
        ),
        data: (data) {
          final badges = [...data.badges]..sort((a, b) {
              final pa = data.pinnedBadges.contains(a.badgeId) ? 0 : 1;
              final pb = data.pinnedBadges.contains(b.badgeId) ? 0 : 1;
              if (pa != pb) return pa - pb;
              final byTier = b.tier.compareTo(a.tier);
              if (byTier != 0) return byTier;
              return b.progress.compareTo(a.progress);
            });
          final earned = data.badges.fold<int>(0, (sum, b) => sum + b.tier.clamp(0, 3));
          var coinsEarned = 0;
          for (final b in data.badges) {
            for (var t = 0; t < b.tier.clamp(0, 3) && t < coins.length; t++) {
              coinsEarned += coins[t];
            }
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, bottomClearance(context)),
            children: [
              _SummaryCard(
                earned: earned,
                total: data.badges.length * 3,
                coins: coinsEarned,
                pinned: data.pinnedBadges.length,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
              ],
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Semantics(header: true, child: Text('Badges', style: AppText.h2))),
                  if (coins.length >= 3)
                    Flexible(
                      flex: 2,
                      child: Text(
                        'Tier I ${coins[0]} · II ${coins[1]} · III ${coins[2]} + title',
                        textAlign: TextAlign.right,
                        style: AppText.caption,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 222,
                ),
                children: [
                  for (final badge in badges)
                    _BadgeCard(
                      badge: badge,
                      coins: coins,
                      pinned: data.pinnedBadges.contains(badge.badgeId),
                      onPin: _busy ? null : () => _togglePin(badge, data.pinnedBadges),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.earned, required this.total, required this.coins, required this.pinned});

  final int earned;
  final int total;
  final int coins;
  final int pinned;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: AppRadius.feature,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(72, 72),
                  painter: _RingPainter(progress: total == 0 ? 0 : earned / total),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$earned', style: AppText.title.copyWith(fontSize: 18, height: 20 / 18)),
                    Text(
                      'of $total',
                      style: AppText.caption.copyWith(fontSize: 10, height: 12 / 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Badge tiers earned', softWrap: true, style: AppText.title.copyWith(fontSize: 17, height: 22 / 17)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset(GameAssets.icon('coin'), width: 16, height: 16),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          style: AppText.bodySmall.copyWith(fontSize: 13),
                          children: [
                            TextSpan(
                              text: '$coins',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            const TextSpan(text: ' coins from badges'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.tealDeep),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text('$pinned of 3 pinned to your profile', style: AppText.bodySmall.copyWith(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 6);
    final track = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final fill = Paint()
      ..color = AppColors.awakeningTeal
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (progress > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.coins, required this.pinned, required this.onPin});

  final BadgeProgress badge;
  final List<int> coins;
  final bool pinned;
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    final tier = badge.tier.clamp(0, 3);
    final maxed = tier >= 3;
    final started = tier > 0 || badge.progress > 0;
    final thresholds = badgeThresholds[badge.badgeId] ?? const [1, 1, 1];
    final next = thresholds[maxed ? 2 : tier];
    final blurb = _badgeBlurb[badge.badgeId];
    final unit = blurb?.unit ?? '';
    final tierLabel = maxed
        ? 'TIER III · MAX'
        : tier > 0
            ? 'TIER ${_romans[tier - 1]}'
            : started
                ? 'IN PROGRESS'
                : 'NOT STARTED';
    final tierColor = maxed
        ? AppColors.legendaryText
        : tier > 0
            ? AppColors.tealDeep
            : AppColors.placeholder;
    final image = Image.asset(
      GameAssets.badge(badgeShortId(badge.badgeId), tier < 1 ? 1 : tier),
      width: 84,
      height: 84,
      cacheWidth: decodeWidth(context, 84),
    );
    return Semantics(
      label: '${badge.name}, ${tierLabel.toLowerCase()}, ${badge.progress} of $next',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Clay(
              radius: 26,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (tier < 1)
                    Opacity(
                      opacity: 0.4,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0, 0, 0, 1, 0,
                        ]),
                        child: image,
                      ),
                    )
                  else
                    image,
                  const SizedBox(height: 4),
                  Text(
                    badge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 15, height: 20 / 15),
                  ),
                  Text(
                    tierLabel,
                    style: AppText.caption.copyWith(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.66,
                      color: tierColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 30,
                    child: Text(
                      blurb?.text ?? '',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(fontSize: 11, height: 15 / 11),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ClayBar(
                    value: maxed
                        ? 1
                        : badgeProgressFraction(badgeId: badge.badgeId, progress: badge.progress, tier: badge.tier),
                    gradient: maxed
                        ? LinearGradient(
                            colors: [Color.lerp(AppColors.legendary, AppColors.white, 0.4)!, AppColors.legendary],
                          )
                        : xpFillGradient,
                    height: 6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11),
                          children: [
                            TextSpan(
                              text: '${badge.progress}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            TextSpan(text: ' / $next$unit'),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (maxed)
                        Text('Title earned', style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11))
                      else ...[
                        Image.asset(GameAssets.icon('coin'), width: 12, height: 12),
                        const SizedBox(width: 3),
                        Text(
                          tier < coins.length ? '${coins[tier]}${tier == 2 ? ' + title' : ''}' : '',
                          style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (tier >= 1)
            Positioned(
              right: 10,
              top: 10,
              child: Semantics(
                button: true,
                selected: pinned,
                label: pinned ? 'Unpin ${badge.name}' : 'Pin ${badge.name}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onPin,
                  child: pinned
                      ? Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(color: AppColors.tealDeep, shape: BoxShape.circle),
                          child: const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.white),
                        )
                      : const Well(
                          circle: true,
                          width: 26,
                          height: 26,
                          child: Icon(Icons.push_pin_outlined, size: 14, color: AppColors.placeholder),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
