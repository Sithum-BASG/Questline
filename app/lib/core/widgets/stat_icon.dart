import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One of the four stats, at 16, 20 or 24 px.
class StatIcon extends StatelessWidget {
  const StatIcon({super.key, required this.stat, this.size = 20});

  final String stat;
  final double size;

  static const sizes = [16.0, 20.0, 24.0];

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: size, color: AppColors.stat(stat));
  }

  IconData get _icon {
    switch (stat) {
      case 'intellect':
        return Icons.menu_book_outlined;
      case 'vitality':
        return Icons.favorite_outline;
      case 'craft':
        return Icons.handyman_outlined;
      case 'charisma':
        return Icons.forum_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
