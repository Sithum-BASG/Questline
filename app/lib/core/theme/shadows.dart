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

  /// Soft neumorphic clay. The white highlight comes first so the dark shade
  /// paints over it (Flutter paints the last shadow on top; CSS the first).
  static const List<BoxShadow> claySoft = [
    BoxShadow(
      color: Color(0xF2FFFFFF),
      offset: Offset(-10, -10),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color(0x1A101935),
      offset: Offset(14, 14),
      blurRadius: 32,
    ),
  ];

  static const List<BoxShadow> claySoftSm = [
    BoxShadow(
      color: Color(0xF2FFFFFF),
      offset: Offset(-5, -5),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x1A101935),
      offset: Offset(6, 6),
      blurRadius: 14,
    ),
  ];

  /// Soft teal primary button on auth screens.
  static const List<BoxShadow> tealButton = [
    BoxShadow(
      color: Color(0xE6FFFFFF),
      offset: Offset(-6, -6),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x4D0F766E),
      offset: Offset(10, 12),
      blurRadius: 26,
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

  // ---------------------------------------------------------------------------
  // Clay UI (phase 17). Outer shadows only; the inner light is painted by
  // InnerShadowPainter in core/widgets/clay.dart.
  // ---------------------------------------------------------------------------

  /// `.c-clay`: raised white card.
  static const List<BoxShadow> clayCard = claySoft;

  /// `.c-clay-sm`: small raised control (chips, icon buttons).
  static const List<BoxShadow> clayControl = claySoftSm;

  /// `.c-teal`: raised teal primary surface.
  static const List<BoxShadow> clayTeal = tealButton;

  /// Clay pressed: shadows pulled in.
  static const List<BoxShadow> clayControlPressed = [
    BoxShadow(color: Color(0x14101935), offset: Offset(2, 2), blurRadius: 6),
  ];

  /// `.c-onscene`: clay sitting on world art (no white glow).
  static const List<BoxShadow> onScene = [
    BoxShadow(color: Color(0x33101935), offset: Offset(2, 4), blurRadius: 8),
  ];

  /// `.c-dot`: small glossy colour dot (stat gems, icons).
  static const List<BoxShadow> dot = [
    BoxShadow(color: Color(0x29101935), offset: Offset(4, 5), blurRadius: 10),
  ];

  /// Drop shadow under characters and bosses breaking out of a frame.
  static const List<BoxShadow> artDrop = [
    BoxShadow(color: Color(0x38101935), offset: Offset(2, 6), blurRadius: 6),
  ];

  /// Upper edge of a bottom sheet.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x29101935), offset: Offset(0, -12), blurRadius: 32),
  ];
}
