import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'stat_icon.dart';

/// Icon, value and label. Home uses these for streak, this week and rank.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    this.stat,
    this.icon,
    this.color,
    required this.value,
    required this.label,
  }) : assert(stat != null || icon != null);

  /// One of the four game stats — uses [StatIcon] when set.
  final String? stat;
  final IconData? icon;
  final Color? color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (stat != null ? AppColors.stat(stat!) : AppColors.inkMuted);
    return Semantics(
      label: '$label $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat != null)
            StatIcon(stat: stat!, size: 24)
          else
            Icon(icon, size: 24, color: tint),
          const SizedBox(height: AppSpacing.s4),
          Text(value, style: AppText.numbers),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
