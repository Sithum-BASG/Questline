import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

enum ProgressKind { xp, bossHp, streak }

/// Labelled bar. XP is teal, boss HP is rose, streak is ember.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.kind = ProgressKind.xp,
    this.leading,
    this.trailing,
  });

  final double value;
  final ProgressKind kind;
  final String? leading;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final fill = switch (kind) {
      ProgressKind.xp => AppColors.awakeningTeal,
      ProgressKind.bossHp => AppColors.bossHp,
      ProgressKind.streak => AppColors.ember,
    };
    final clamped = value.clamp(0.0, 1.0);
    final duration = kind == ProgressKind.bossHp
        ? AppMotion.bossDamage(context)
        : AppMotion.xpFill(context);

    final labelBits = [
      if (leading != null && leading!.isNotEmpty) leading!,
      if (trailing != null && trailing!.isNotEmpty) trailing!,
      '${(clamped * 100).round()} percent',
    ];

    return Semantics(
      label: labelBits.join(', '),
      value: '${(clamped * 100).round()}%',
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(leading ?? '', style: AppText.caption, softWrap: true)),
                Flexible(
                  child: Text(
                    trailing ?? '',
                    style: AppText.numbers.copyWith(fontSize: 12),
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.line),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: duration,
                  curve: Curves.easeOut,
                  builder: (context, widthFactor, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widthFactor,
                      child: ColoredBox(color: fill),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
