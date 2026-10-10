import 'package:flutter/material.dart';

/// Colour tokens from the UI brief. Brand hexes match the asset pack.
class AppColors {
  const AppColors._();

  static const Color awakeningTeal = Color(0xFF14B8A6);
  static const Color teal = awakeningTeal;
  static const Color tealDeep = Color(0xFF0F766E);
  static const Color ink = Color(0xFF101935);
  static const Color paper = Color(0xFFF7F6F3);
  static const Color white = Color(0xFFFFFFFF);

  static const Color common = Color(0xFF9CA3AF);
  static const Color rare = Color(0xFF3B82F6);
  static const Color epic = Color(0xFF8B5CF6);
  static const Color legendary = Color(0xFFF5B301);
  static const Color mythic = Color(0xFFB3123A);

  static const Color inkMuted = Color(0xFF5B6178);
  static const Color inkFaint = Color(0xFF9AA0B4);
  static const Color line = Color(0xFFE8E6E1);
  static const Color ember = Color(0xFFF97316);
  static const Color streakEmber = ember;
  static const Color success = Color(0xFF16A34A);
  static const Color bossHp = Color(0xFFE2557A);
  static const Color error = Color(0xFFD9480F);

  static const Color intellect = Color(0xFF5B7C99);
  static const Color vitality = Color(0xFF5E9A6E);
  static const Color craft = Color(0xFFB07A4F);
  static const Color charisma = Color(0xFFB0708F);

  /// Bottom edge of a clay primary button.
  static const Color clayEdge = Color(0xFF0B5A54);

  /// Bottom edge of a selected clay chip.
  static const Color chipEdge = Color(0xFFD9D6CF);

  static Color stat(String stat) {
    switch (stat) {
      case 'intellect':
        return intellect;
      case 'vitality':
        return vitality;
      case 'craft':
        return craft;
      case 'charisma':
        return charisma;
      default:
        return inkMuted;
    }
  }

  static Color rarity(String rarity) {
    switch (rarity) {
      case 'common':
        return common;
      case 'rare':
        return rare;
      case 'epic':
        return epic;
      case 'legendary':
        return legendary;
      case 'mythic':
        return mythic;
      default:
        return common;
    }
  }
}
