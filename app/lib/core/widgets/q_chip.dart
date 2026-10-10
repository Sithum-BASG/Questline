import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';

enum QChipKind { stat, filter, rarity }

/// Pill chip: stat tint, filter, or rarity. Selected filter chips use clay.
class QChip extends StatelessWidget {
  const QChip({
    super.key,
    required this.label,
    this.kind = QChipKind.filter,
    this.selected = false,
    this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final QChipKind kind;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.inkMuted;
    final (background, foreground, border) = _look(tint);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.s4),
        ],
        Text(label, style: AppText.caption.copyWith(color: foreground)),
      ],
    );
    final decoration = BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: border,
      boxShadow: selected && kind == QChipKind.filter ? AppShadows.chip : null,
    );
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
            child: Ink(
              decoration: decoration,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Border?) _look(Color tint) {
    switch (kind) {
      case QChipKind.stat:
        return (tint.withValues(alpha: 0.12), tint, null);
      case QChipKind.rarity:
        return (tint.withValues(alpha: 0.12), tint, Border.all(color: tint));
      case QChipKind.filter:
        if (selected) {
          return (AppColors.white, AppColors.tealDeep, null);
        }
        return (AppColors.white, AppColors.inkMuted, Border.all(color: AppColors.line));
    }
  }
}
