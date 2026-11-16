import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'clay.dart';

/// Raised clay card on the page. Highlighted adds a teal ring. Tappable adds
/// a ripple clipped to the card.
class QCard extends StatelessWidget {
  const QCard({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.radius = AppRadius.feature,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: radius,
      padding: padding,
      onTap: onTap,
      border: highlighted ? Border.all(color: AppColors.tealDeep, width: 2) : null,
      child: child,
    );
  }
}
