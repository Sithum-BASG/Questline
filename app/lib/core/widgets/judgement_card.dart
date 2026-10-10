import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';
import 'q_card.dart';
import 'q_chip.dart';

/// AI judgement. The stat chip can be changed. Too-big tasks offer split or shrink.
class JudgementCard extends StatelessWidget {
  const JudgementCard({
    super.key,
    required this.stat,
    required this.difficulty,
    required this.minutes,
    required this.xpPreview,
    required this.reason,
    this.provisional = false,
    this.challenged = false,
    this.tooBig = false,
    this.onStatTap,
    this.onSplit,
    this.onShrink,
  });

  final String stat;
  final int difficulty;
  final int minutes;
  final int xpPreview;
  final String reason;
  final bool provisional;
  final bool challenged;
  final bool tooBig;
  final VoidCallback? onStatTap;
  final VoidCallback? onSplit;
  final VoidCallback? onShrink;

  @override
  Widget build(BuildContext context) {
    return QCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QChip(
                label: stat,
                kind: QChipKind.stat,
                color: AppColors.stat(stat),
                onTap: onStatTap,
              ),
              const Spacer(),
              if (provisional) const QChip(label: 'Provisional'),
              if (challenged) const QChip(label: 'Challenged', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: List.generate(5, (index) {
              final filled = index < difficulty;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s4),
                child: Icon(
                  filled ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: filled ? AppColors.tealDeep : AppColors.inkFaint,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('~$minutes min', style: AppText.body),
          Text('$xpPreview XP', style: AppText.numbers),
          const SizedBox(height: AppSpacing.s8),
          Text(reason, style: AppText.bodySmall),
          if (tooBig) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              children: [
                QButton(label: 'Split', variant: QButtonVariant.secondary, onPressed: onSplit),
                QButton(label: 'Shrink', variant: QButtonVariant.text, onPressed: onShrink),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
