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
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  // A deeper drop shadow and a faint rim lift the orb off the page.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.14),
                            offset: Offset(0, size * 0.12),
                            blurRadius: size * 0.26,
                          ),
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.07),
                            offset: Offset(0, size * 0.025),
                            blurRadius: size * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Clay(
                    circle: true,
                    width: size,
                    height: size,
                    onTap: onTap,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.35),
                          radius: 0.55,
                          colors: [tint.withValues(alpha: 0.14), tint.withValues(alpha: 0)],
                        ),
                      ),
                      child: _OrbContent(glyph: glyph, tint: tint, value: value, size: size),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
                      ),
                      child: const SizedBox.expand(),
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

class _OrbContent extends StatelessWidget {
  const _OrbContent({required this.glyph, required this.tint, required this.value, required this.size});

  final IconData glyph;
  final Color tint;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
