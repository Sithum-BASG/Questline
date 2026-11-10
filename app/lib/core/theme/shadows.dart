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

  /// Soft neumorphic clay for auth surfaces (arch, Google button, nameplate).
  static const List<BoxShadow> claySoft = [
    BoxShadow(
      color: Color(0x1A101935),
      offset: Offset(14, 14),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color(0xF2FFFFFF),
      offset: Offset(-10, -10),
      blurRadius: 24,
    ),
  ];

  static const List<BoxShadow> claySoftSm = [
    BoxShadow(
      color: Color(0x1A101935),
      offset: Offset(6, 6),
      blurRadius: 14,
    ),
    BoxShadow(
      color: Color(0xF2FFFFFF),
      offset: Offset(-5, -5),
      blurRadius: 12,
    ),
  ];

  /// Soft teal primary button on auth screens.
  static const List<BoxShadow> tealButton = [
    BoxShadow(
      color: Color(0x4D0F766E),
      offset: Offset(10, 12),
      blurRadius: 26,
    ),
    BoxShadow(
      color: Color(0xE6FFFFFF),
      offset: Offset(-6, -6),
      blurRadius: 16,
    ),
  ];

  /// Soft drop under auth hero skins.
  static const List<BoxShadow> authHero = [
    BoxShadow(
      color: Color(0x38101935),
      offset: Offset(0, 8),
      blurRadius: 12,
    ),
  ];
}
