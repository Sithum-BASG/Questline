import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';
import 'portrait_frame.dart';
import 'q_chip.dart';

/// One leaderboard line. "You" gets a teal highlight.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.name,
    required this.title,
    required this.xp,
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
    this.isYou = false,
    this.onTap,
  });

  final int rank;
  final String name;
  final String title;
  final int xp;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final bool isYou;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: isYou ? AppColors.awakeningTeal.withValues(alpha: 0.12) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
        border: isYou ? Border.all(color: AppColors.tealDeep, width: 1.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: AppText.numbers.copyWith(
                color: isYou ? AppColors.tealDeep : AppColors.ink,
              ),
            ),
          ),
          PortraitFrame(
            skinId: skinId,
            backgroundId: backgroundId,
            frameId: frameId,
            body: body,
            size: PortraitFrameSize.leaderboard,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: AppText.title, overflow: TextOverflow.ellipsis)),
                    if (isYou) ...[
                      const SizedBox(width: AppSpacing.s8),
                      const QChip(label: 'You', selected: true),
                    ],
                  ],
                ),
                Text(title, style: AppText.caption),
              ],
            ),
          ),
          Text('$xp XP', style: AppText.numbers),
        ],
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      label: '$name, rank $rank, $xp XP',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: child,
      ),
    );
  }
}
