import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';

enum QChipKind { stat, filter, rarity }

/// Pill chip. Filter chips are white clay, teal clay when selected. Stat and
/// rarity chips are soft tints with a readable darker word.
class QChip extends StatelessWidget {
  const QChip({
    super.key,
    required this.label,
    this.kind = QChipKind.filter,
    this.selected = false,
    this.color,
    this.icon,
    this.onTap,
    this.count,
  });

  final String label;
  final QChipKind kind;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Optional count shown after the label.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.inkMuted;
    if (kind == QChipKind.filter) {
      final fg = selected ? AppColors.white : AppColors.ink;
      final chip = Clay(
        kind: selected ? ClayKind.teal : ClayKind.control,
        radius: 22,
        height: 44,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label, style: AppText.title.copyWith(fontSize: 14, height: 18 / 14, color: fg)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white.withValues(alpha: 0.8) : AppColors.inkFaint,
                ),
              ),
            ],
          ],
        ),
      );
      return Semantics(
        button: onTap != null,
        selected: selected,
        label: count == null ? label : '$label, $count',
        excludeSemantics: true,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: chip),
      );
    }

    final fg = kind == QChipKind.rarity ? _rarityText(tint) : _darken(tint);
    final body = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.s4),
          ],
          Text(label, style: AppText.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: onTap == null
          ? body
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const StadiumBorder(),
                  child: Center(widthFactor: 1, child: body),
                ),
              ),
            ),
    );
  }

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  static Color _rarityText(Color c) {
    if (c == AppColors.rare) return AppColors.rareText;
    if (c == AppColors.epic) return AppColors.epicText;
    if (c == AppColors.legendary) return AppColors.legendaryText;
    if (c == AppColors.mythic) return AppColors.mythic;
    if (c == AppColors.common) return AppColors.commonText;
    return _darken(c);
  }
}
