import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_card.dart';
import 'stat_icon.dart';

/// A task row. Late dues use the error colour. Play and tick are optional.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.stat,
    required this.dueLabel,
    this.late = false,
    this.provisional = false,
    this.onPlay,
    this.onTick,
  });

  final String title;
  final String stat;
  final String dueLabel;
  final bool late;
  final bool provisional;
  final VoidCallback? onPlay;
  final VoidCallback? onTick;

  @override
  Widget build(BuildContext context) {
    return QCard(
      child: Row(
        children: [
          StatIcon(stat: stat),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                Text(dueLabel, style: AppText.bodySmall.copyWith(color: late ? AppColors.error : AppColors.inkMuted)),
              ],
            ),
          ),
          if (provisional) const Icon(Icons.hourglass_empty, color: AppColors.inkFaint),
          if (onTick != null)
            IconButton(onPressed: onTick, icon: const Icon(Icons.check), tooltip: 'Tick task'),
          if (onPlay != null)
            IconButton(onPressed: onPlay, icon: const Icon(Icons.play_arrow), tooltip: 'Start focus'),
        ],
      ),
    );
  }
}
