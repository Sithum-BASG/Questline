import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'portrait_frame.dart';
import 'q_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final focusLabel = focusing ? ', focusing now' : '';
    final weightLabel = pulledWeight ? ', pulled their weight' : '';
    final damageLabel = damage != null ? ', $damage damage' : '';
    return Semantics(
      label: '$name, $title$focusLabel$weightLabel$damageLabel',
      child: QCard(
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
                  Text(name, style: AppText.title, softWrap: true),
                  Text(title, style: AppText.caption, softWrap: true),
                ],
              ),
            ),
            if (pulledWeight)
              const Icon(Icons.check_circle, color: AppColors.success, semanticLabel: 'Pulled their weight'),
            if (damage != null) Text('$damage', style: AppText.numbers),
          ],
        ),
      ),
    );
  }
}
