import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'stat_icon.dart';

/// A quest row: stat dot, title, meta and a quiet round start button.
/// On its own it sits in a clay card; inside a [ClayList] pass [bare].
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
    this.onTap,
    this.bare = false,
  });

  final String title;
  final String stat;
  final String dueLabel;
  final bool late;
  final bool provisional;
  final VoidCallback? onPlay;
  final VoidCallback? onTick;
  final VoidCallback? onTap;

  /// Render without the surrounding card (for rows inside a ClayList).
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            StatDot(stat: stat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.item, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (provisional) ...[
                        const Tooltip(
                          message: 'Provisional judgement',
                          child: Icon(Icons.hourglass_empty_rounded, size: 13, color: AppColors.inkFaint),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          dueLabel,
                          style: AppText.bodySmall.copyWith(
                            color: late ? AppColors.errorText : AppColors.inkMuted,
                            fontWeight: late ? FontWeight.w600 : FontWeight.w400,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTick != null)
              SoftIconButton(
                icon: Icons.check_rounded,
                tooltip: 'Tick task',
                onPressed: onTick,
                background: AppColors.well,
                color: AppColors.inkMuted,
              ),
            if (onPlay != null) SoftIconButton(icon: Icons.play_arrow_rounded, tooltip: 'Start focus', onPressed: onPlay),
          ],
        ),
      ),
    );

    final semantic = '$title, $dueLabel${provisional ? ', provisional' : ''}';
    if (bare) {
      return Semantics(
        label: semantic,
        child: onTap == null
            ? row
            : Material(type: MaterialType.transparency, child: InkWell(onTap: onTap, child: row)),
      );
    }
    return Semantics(
      label: semantic,
      child: Clay(radius: AppRadius.card, onTap: onTap, child: row),
    );
  }
}
