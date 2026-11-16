import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'clay.dart';

/// One of the four stats, at 16, 20 or 24 px.
class StatIcon extends StatelessWidget {
  const StatIcon({super.key, required this.stat, this.size = 20});

  final String stat;
  final double size;

  static const sizes = [16.0, 20.0, 24.0];

  static String labelFor(String stat) {
    switch (stat) {
      case 'intellect':
        return 'Intellect';
      case 'vitality':
        return 'Vitality';
      case 'craft':
        return 'Craft';
      case 'charisma':
        return 'Charisma';
      default:
        return 'Stat';
    }
  }

  static IconData iconFor(String stat) {
    switch (stat) {
      case 'intellect':
        return Icons.menu_book_rounded;
      case 'vitality':
        return Icons.favorite_rounded;
      case 'craft':
        return Icons.handyman_rounded;
      case 'charisma':
        return Icons.forum_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: labelFor(stat),
      image: true,
      child: Icon(iconFor(stat), size: size, color: AppColors.stat(stat)),
    );
  }
}

/// A stat as a glossy clay dot with a white icon (quest rows, judgement).
class StatDot extends StatelessWidget {
  const StatDot({super.key, required this.stat, this.size = 36});

  final String stat;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClayDot(
      gradient: statGradient(stat),
      icon: StatIcon.iconFor(stat),
      size: size,
      semanticLabel: StatIcon.labelFor(stat),
    );
  }
}
