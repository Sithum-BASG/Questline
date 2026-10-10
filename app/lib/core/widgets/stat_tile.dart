import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'stat_icon.dart';

/// Icon, value and label. Home uses these for streak, this week and rank.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.stat,
    required this.value,
    required this.label,
  });

  final String stat;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatIcon(stat: stat, size: 24),
        const SizedBox(height: AppSpacing.s4),
        Text(value, style: AppText.numbers),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
