import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'stage_card.dart';

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
    required this.body,
    this.isYou = false,
  });

  final int rank;
  final String name;
  final String title;
  final int xp;
  final String skinId;
  final String backgroundId;
  final BodyType body;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: isYou ? AppColors.awakeningTeal.withValues(alpha: 0.12) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', style: AppText.numbers)),
          StageCard(skinId: skinId, backgroundId: backgroundId, body: body, size: StageCardSize.row),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.title),
                Text(title, style: AppText.caption),
              ],
            ),
          ),
          Text('$xp XP', style: AppText.numbers),
        ],
      ),
    );
  }
}
