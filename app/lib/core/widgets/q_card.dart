import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/shadows.dart';

/// White card on Paper. Highlighted adds a teal border. Tappable adds a ripple.
class QCard extends StatelessWidget {
  const QCard({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: AppShadows.card,
        border: highlighted ? Border.all(color: AppColors.tealDeep, width: 1.5) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.card,
            border: highlighted ? Border.all(color: AppColors.tealDeep, width: 1.5) : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
