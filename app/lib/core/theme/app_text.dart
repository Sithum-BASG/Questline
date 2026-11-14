import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale from the clay redesign: Sora for display and numbers, Roboto
/// for reading text. Numbers use tabular figures.
class AppText {
  const AppText._();

  /// Reading text family (theme default).
  static const String family = roboto;

  static const String sora = 'Sora';
  static const String roboto = 'Roboto';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: sora,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle timer = TextStyle(
    fontFamily: sora,
    fontSize: 56,
    height: 60 / 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.12,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Screen titles and the Home greeting.
  static const TextStyle h1 = TextStyle(
    fontFamily: sora,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.52,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Section titles.
  static const TextStyle h2 = TextStyle(
    fontFamily: sora,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.36,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Boss names on encounter cards.
  static const TextStyle encounter = TextStyle(
    fontFamily: sora,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.34,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Card titles, item names.
  static const TextStyle title = TextStyle(
    fontFamily: sora,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Primary button label.
  static const TextStyle button = TextStyle(
    fontFamily: sora,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.17,
    color: AppColors.white,
    fontFeatures: tabular,
  );

  static const TextStyle body = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Task titles and list item titles.
  static const TextStyle item = TextStyle(
    fontFamily: roboto,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: roboto,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  /// Small coloured label above a title ("Closest boss"). Sentence case.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  /// Spaced all-caps field label ("QUEST", "DUE").
  static const TextStyle label = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.96,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  /// Values in stat orbs, leaderboard XP, counters.
  static const TextStyle numbers = TextStyle(
    fontFamily: sora,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Big orb value (22px Sora).
  static const TextStyle stat = TextStyle(
    fontFamily: sora,
    fontSize: 22,
    height: 26 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  /// Inline link ("View all").
  static const TextStyle link = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.tealDeep,
    fontFeatures: tabular,
  );

  // ---------------------------------------------------------------------------
  // Auth screens (Sora headings/buttons, Roboto body)
  // ---------------------------------------------------------------------------

  static const TextStyle authBrand = TextStyle(
    fontFamily: sora,
    fontSize: 17,
    height: 20 / 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.34,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle authTitle = TextStyle(
    fontFamily: sora,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.84,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle authSubtitle = TextStyle(
    fontFamily: roboto,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  static const TextStyle authError = TextStyle(
    fontFamily: roboto,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.authErrorText,
    fontFeatures: tabular,
  );

  static const TextStyle authFieldLabel = TextStyle(
    fontFamily: roboto,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.44,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  static const TextStyle authFieldValue = TextStyle(
    fontFamily: roboto,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle authFieldHint = TextStyle(
    fontFamily: roboto,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    color: AppColors.fieldHint,
    fontFeatures: tabular,
  );

  static const TextStyle authLink = TextStyle(
    fontFamily: sora,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    color: AppColors.tealDeep,
    fontFeatures: tabular,
  );

  static const TextStyle authPrimaryButton = TextStyle(
    fontFamily: sora,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFeatures: tabular,
  );

  static const TextStyle authGoogleButton = TextStyle(
    fontFamily: sora,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle authOr = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkFaint,
    fontFeatures: tabular,
  );

  static const TextStyle authStrengthHint = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  static const TextStyle authFooter = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    fontFeatures: tabular,
  );

  static const TextStyle authFooterAction = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.tealDeep,
    fontFeatures: tabular,
  );
}
