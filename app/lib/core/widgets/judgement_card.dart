import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';
import 'q_card.dart';
import 'q_chip.dart';

/// AI judgement. The stat chip can be changed. Too-big tasks offer split or make-boss.
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
    this.onMakeBoss,
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
  final VoidCallback? onMakeBoss;

  @override
  Widget build(BuildContext context) {
    final makeBoss = onMakeBoss;
    final difficultyLabel = 'Difficulty $difficulty of 5';
    return QCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              QChip(
                label: _titleCase(stat),
                kind: QChipKind.stat,
                color: AppColors.stat(stat),
                onTap: onStatTap,
              ),
              if (provisional) const QChip(label: 'Provisional'),
              if (challenged) const QChip(label: 'Challenged', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('Difficulty', style: AppText.caption),
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            label: difficultyLabel,
            child: Row(
              children: List.generate(5, (index) {
                final filled = index < difficulty.clamp(1, 5);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: Icon(
                    filled ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: filled ? AppColors.tealDeep : AppColors.inkFaint,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time', style: AppText.caption),
                    const SizedBox(height: AppSpacing.s4),
                    Text('~$minutes min', style: AppText.title),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('XP preview', style: AppText.caption),
                    const SizedBox(height: AppSpacing.s4),
                    Text('$xpPreview XP', style: AppText.numbers),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(reason, style: AppText.bodySmall),
          if (tooBig) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              'This looks bigger than one sitting.',
              style: AppText.body.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                QButton(label: 'Split', variant: QButtonVariant.secondary, onPressed: onSplit),
                QButton(
                  label: 'Make it a boss',
                  variant: QButtonVariant.secondary,
                  onPressed: makeBoss,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
