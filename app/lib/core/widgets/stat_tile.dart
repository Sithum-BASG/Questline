import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'stat_icon.dart';

/// A clay orb holding an icon and value, with a label under it. Home uses
/// these for streak, XP this week and rank.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    this.stat,
    this.icon,
    this.color,
    required this.value,
    required this.label,
    this.size = 88,
    this.onTap,
  }) : assert(stat != null || icon != null);

  /// One of the four game stats — uses its icon when set.
  final String? stat;
  final IconData? icon;
  final Color? color;
  final String value;
  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (stat != null ? AppColors.stat(stat!) : AppColors.inkMuted);
    final glyph = stat != null ? StatIcon.iconFor(stat!) : icon!;
    return Semantics(
      label: '$label $value',
      button: onTap != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Clay(
              circle: true,
              width: size,
              height: size,
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(glyph, size: size * 0.25, color: tint),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(value, style: AppText.stat, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: AppText.caption, textAlign: TextAlign.center, softWrap: true),
        ],
      ),
    );
  }
}
