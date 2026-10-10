import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_card.dart';
import 'stage_card.dart';

/// Party or guild member. Shows a focusing dot, and either damage or a check.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.name,
    required this.title,
    required this.skinId,
    required this.backgroundId,
    required this.body,
    this.focusing = false,
    this.damage,
    this.pulledWeight = false,
  });

  final String name;
  final String title;
  final String skinId;
  final String backgroundId;
  final BodyType body;
  final bool focusing;
  final int? damage;
  final bool pulledWeight;

  @override
  Widget build(BuildContext context) {
    return QCard(
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              StageCard(skinId: skinId, backgroundId: backgroundId, body: body, size: StageCardSize.row),
              if (focusing)
                const Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: SizedBox(width: 12, height: 12),
                  ),
                ),
            ],
          ),
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
          if (pulledWeight) const Icon(Icons.check_circle, color: AppColors.success),
          if (damage != null) Text('$damage', style: AppText.numbers),
        ],
      ),
    );
  }
}
