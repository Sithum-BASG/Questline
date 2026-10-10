import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Circular badge. Tier 0 is locked and greyscale. Tiers 1–3 use the badge art.
class BadgeMedallion extends StatelessWidget {
  const BadgeMedallion({
    super.key,
    required this.id,
    required this.tier,
    this.progress,
    this.caption,
    this.size = 72,
  });

  final String id;
  final int tier;
  final double? progress;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final locked = tier <= 0;
    final image = Image.asset(
      locked ? GameAssets.badgeFrame(1) : GameAssets.badge(id, tier.clamp(1, 3)),
      width: size,
      height: size,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (progress != null)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: progress!.clamp(0, 1),
                    color: AppColors.awakeningTeal,
                    backgroundColor: AppColors.line,
                  ),
                ),
              if (locked)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: image,
                )
              else
                image,
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(caption!, style: AppText.caption),
        ],
      ],
    );
  }
}
