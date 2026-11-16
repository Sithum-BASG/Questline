import 'package:flutter/material.dart';

/// Colour tokens from the UI brief. Brand hexes match the asset pack.
class AppColors {
  const AppColors._();

  static const Color awakeningTeal = Color(0xFF14B8A6);
  static const Color teal = awakeningTeal;
  static const Color tealDeep = Color(0xFF0F766E);
  static const Color ink = Color(0xFF101935);
  /// Page background behind every screen (soft cool grey, the clay ground).
  static const Color paper = Color(0xFFF2F4F8);
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

  // ---------------------------------------------------------------------------
  // Clay UI (phase 17 redesign)
  // ---------------------------------------------------------------------------

  /// Bottom stop of the white clay gradient.
  static const Color clayFace = Color(0xFFF5F7FA);

  /// Sunken well behind bars, inputs and empty slots.
  static const Color well = Color(0xFFECEFF4);

  /// Hairline between rows inside a clay card.
  static const Color hairline = Color(0xFFE8ECF2);

  /// Soft divider / drag handle grey.
  static const Color handle = Color(0xFFCDD3DD);

  /// Placeholder text in inputs.
  static const Color placeholder = Color(0xFFA3AAB9);

  /// Soft teal wash behind teal icons (start buttons, Judge sparkle).
  static const Color tealSoft = Color(0xFFE6F4F1);

  /// Brighter teal wash for selected rows.
  static const Color tealWash = Color(0xFFE9FBF7);

  /// Top stop of the XP fill and teal glows.
  static const Color tealLight = Color(0xFF5EEAD4);

  static const Color emberLight = Color(0xFFFDBA74);
  static const Color emberSoft = Color(0xFFFFF2E8);

  /// Soft green wash behind success / scroll art.
  static const Color successSoft = Color(0xFFEEF6EE);

  /// Guild crest shield gradients (light, deep), crest_1 to crest_8.
  static const List<(Color, Color)> guildCrests = [
    (Color(0xFF5EEAD4), Color(0xFF0F766E)),
    (Color(0xFF8EA2FF), Color(0xFF2B3168)),
    (Color(0xFFA9C2D8), Color(0xFF5B7C99)),
    (Color(0xFFFDBA74), Color(0xFFC2410C)),
    (Color(0xFFB5DDBF), Color(0xFF3F7A50)),
    (Color(0xFFE2B7CB), Color(0xFF8E4F6E)),
    (Color(0xFFFFD966), Color(0xFFA16207)),
    (Color(0xFFC4B5FD), Color(0xFF5B21B6)),
  ];

  /// Error wash, e.g. a "Full" pill.
  static const Color errorSoft = Color(0xFFFDEEE6);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successText = Color(0xFF15803D);
  static const Color errorText = Color(0xFFC2410C);

  static const Color bossHpLight = Color(0xFFF07C9C);
  static const Color bossHpText = Color(0xFFA72A4B);
  static const Color bossHpSoft = Color(0xFFF8E6EB);

  static const Color rareSoft = Color(0xFFEAF1FE);
  static const Color rareText = Color(0xFF1D4ED8);
  static const Color epicSoft = Color(0xFFF1ECFE);
  static const Color epicText = Color(0xFF6D28D9);
  static const Color legendarySoft = Color(0xFFFEF6DC);
  static const Color legendaryText = Color(0xFF8A5A00);
  static const Color mythicSoft = Color(0xFFFBE8ED);
  static const Color commonSoft = Color(0xFFF3F4F6);
  static const Color commonText = Color(0xFF4B5563);

  static const Color intellectLight = Color(0xFFA9C2D8);
  static const Color vitalityLight = Color(0xFFB5DDBF);
  static const Color craftLight = Color(0xFFDDB896);
  static const Color charismaLight = Color(0xFFE2B7CB);

  /// Night "world" scene behind the quest board and reward moments.
  static const Color sceneTop = Color(0xFF4B4FA8);
  static const Color sceneMid = Color(0xFF2A2D74);
  static const Color sceneDeep = Color(0xFF1B1D4F);

  /// Lavender boss arena: centre, middle and rim stops.
  static const Color arenaLight = Color(0xFFF4F3FF);
  static const Color arenaMid = Color(0xFFD9DBF7);
  static const Color arenaDeep = Color(0xFF9EA3DA);

  /// Raid navy: tier tags, party tags and the fair-share line.
  static const Color raidInk = Color(0xFF2B3168);
  static const Color raidSoft = Color(0xFFE7E8FB);
  static const Color raidLight = Color(0xFF8EA2FF);

  /// Party stage strip behind the raid heroes.
  static const Color partyStripMid = Color(0xFFE9EAFB);
  static const Color partyStripRim = Color(0xFFD3D6F3);

  /// Camera panel behind the QR scanner.
  static const Color scanTop = Color(0xFF2A3050);
  static const Color scanDeep = Color(0xFF0E1328);

  /// Raid result fields: teal for a win, rose for an escape.
  static const Color winFieldLight = Color(0xFFF0FDFA);
  static const Color winFieldMid = Color(0xFFB9EDE4);
  static const Color winFieldDeep = Color(0xFF6FC2BF);
  static const Color escapeFieldLight = Color(0xFFFDF1F4);
  static const Color escapeFieldMid = Color(0xFFF1C3D0);
  static const Color escapeFieldDeep = Color(0xFFB97A99);
  static const Color escapeInk = Color(0xFF7A1F3D);
  static const Color stampTealLight = Color(0xFF2DD4BF);

  /// Dim behind sheets and dialogs (ink at 38%).
  static const Color scrim = Color(0x61101935);

  /// Light top-left stop of a stat's clay dot gradient.
  static Color statLight(String stat) {
    switch (stat) {
      case 'intellect':
        return intellectLight;
      case 'vitality':
        return vitalityLight;
      case 'craft':
        return craftLight;
      case 'charisma':
        return charismaLight;
      default:
        return inkFaint;
    }
  }

  /// Soft tile wash for a rarity.
  static Color raritySoft(String rarity) {
    switch (rarity) {
      case 'rare':
        return rareSoft;
      case 'epic':
        return epicSoft;
      case 'legendary':
        return legendarySoft;
      case 'mythic':
        return mythicSoft;
      default:
        return commonSoft;
    }
  }

  /// Readable text colour for a rarity word.
  static Color rarityText(String rarity) {
    switch (rarity) {
      case 'rare':
        return rareText;
      case 'epic':
        return epicText;
      case 'legendary':
        return legendaryText;
      case 'mythic':
        return mythic;
      default:
        return commonText;
    }
  }

  /// Bottom edge of a clay primary button.
  static const Color clayEdge = Color(0xFF0B5A54);

  /// Bottom edge of a selected clay chip.
  static const Color chipEdge = Color(0xFFD9D6CF);

  /// Auth screens page background (soft cool grey).
  static const Color authPage = Color(0xFFF2F4F8);

  /// Inset well fill for auth text fields.
  static const Color insetWell = Color(0xFFECEFF4);

  /// Leading icons inside auth fields.
  static const Color fieldIcon = Color(0xFF7A8299);

  /// Placeholder text inside auth fields.
  static const Color fieldHint = Color(0xFFA3AAB9);

  /// Inset-well inner shadows (dark top-left, light bottom-right).
  static const Color insetShadowDark = Color(0x1A101935);
  static const Color insetShadowLight = Color(0xE6FFFFFF);

  /// Soft clay shadow ink (rgba 16,25,53).
  static const Color clayShadow = Color(0xFF101935);

  /// Auth error pill background and text / field outline.
  static const Color authErrorPill = Color(0xFFFDEEE6);
  static const Color authErrorText = Color(0xFFB4380C);
  static const Color authErrorOutline = Color(0xFFE8590C);

  /// Soft teal primary button gradient (145°).
  static const Color tealButtonStart = Color(0xFF128A7D);
  static const Color tealButtonEnd = Color(0xFF0D6B63);

  /// Focus clock: deep end of the ring, stopped ring, idle dashes, inner face foot.
  static const Color focusRingDeep = Color(0xFF0F9488);
  static const Color focusRingStopped = Color(0xFFB8BFCC);
  static const Color focusRingIdle = Color(0xFFD5DAE3);
  static const Color focusFaceFoot = Color(0xFFF3F6FA);

  /// Strong ember for the session-ended notch and icons.
  static const Color emberDeep = Color(0xFFEA580C);

  /// Password strength meter.
  static const Color strengthFilled = Color(0xFF14B8A6);
  static const Color strengthEmpty = Color(0xFFDDE2EA);

  /// Auth "or" divider line.
  static const Color authDivider = Color(0xFFDCE1E9);

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
