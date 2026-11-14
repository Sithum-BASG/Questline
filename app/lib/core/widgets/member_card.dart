import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'portrait_frame.dart';

/// Party or guild member. Shows a focusing dot, and either damage or a check.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.name,
    required this.title,
    required this.skinId,
    required this.backgroundId,
    required this.body,
    this.frameId = 'apprentice',
    this.focusing = false,
    this.damage,
    this.pulledWeight = false,
    this.bare = false,
  });

  final String name;
  final String title;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final bool focusing;
  final int? damage;
  final bool pulledWeight;

  /// Render without the surrounding card (rows inside a ClayList).
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final focusLabel = focusing ? ', focusing now' : '';
    final weightLabel = pulledWeight ? ', pulled their weight' : '';
    final damageLabel = damage != null ? ', $damage damage' : '';
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PortraitFrame(
                skinId: skinId,
                backgroundId: backgroundId,
                frameId: frameId,
                body: body,
                size: PortraitFrameSize.compact,
              ),
              if (focusing)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AppText.title.copyWith(fontSize: 15), softWrap: true),
                Text(
                  focusing ? 'Focusing now · $title' : title,
                  style: AppText.caption.copyWith(color: focusing ? AppColors.successText : AppColors.inkMuted),
                  softWrap: true,
                ),
              ],
            ),
          ),
          if (pulledWeight)
            const ClayDot(
              size: 28,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.successLight, AppColors.success],
              ),
              icon: Icons.check_rounded,
              semanticLabel: 'Pulled their weight',
            ),
          if (damage != null) ...[
            const SizedBox(width: AppSpacing.s8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$damage', style: AppText.numbers),
                  TextSpan(text: ' dmg', style: AppText.caption),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return Semantics(
      label: '$name, $title$focusLabel$weightLabel$damageLabel',
      child: bare ? row : Clay(radius: AppRadius.card, child: row),
    );
  }
}
