import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';

enum ProgressKind { xp, bossHp, streak }

/// Labelled clay bar in a sunken track. XP is teal, boss HP is rose,
/// streak is ember. Labels sit under the bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.kind = ProgressKind.xp,
    this.leading,
    this.trailing,
    this.trailingColor,
    this.height = 10,
  });

  final double value;
  final ProgressKind kind;
  final String? leading;
  final String? trailing;
  final Color? trailingColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = switch (kind) {
      ProgressKind.xp => xpFillGradient,
      ProgressKind.bossHp => hpFillGradient,
      ProgressKind.streak => emberFillGradient,
    };
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final duration = kind == ProgressKind.bossHp ? AppMotion.bossDamage(context) : AppMotion.xpFill(context);

    final labelBits = [
      if (leading != null && leading!.isNotEmpty) leading!,
      if (trailing != null && trailing!.isNotEmpty) trailing!,
      '${(clamped * 100).round()} percent',
    ];

    final hasLabels = leading != null || trailing != null;
    return Semantics(
      label: labelBits.join(', '),
      value: '${(clamped * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: ClayBar(value: clamped, gradient: fill, height: height, duration: duration),
          ),
          if (hasLabels)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(leading ?? '', style: AppText.caption, softWrap: true)),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(
                    child: Text(
                      trailing ?? '',
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: trailingColor),
                      textAlign: TextAlign.end,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
