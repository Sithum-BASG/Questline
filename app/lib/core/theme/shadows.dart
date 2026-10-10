import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens. Clay depth is a solid bottom edge, not a blur.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F101935),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> clay = [
    BoxShadow(
      color: AppColors.clayEdge,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> clayPressed = [
    BoxShadow(
      color: AppColors.clayEdge,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> chip = [
    BoxShadow(
      color: AppColors.chipEdge,
      offset: Offset(0, 2),
    ),
  ];
}
