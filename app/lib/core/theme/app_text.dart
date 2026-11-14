import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nunito text styles from the UI brief. Numbers use tabular figures.
/// Auth screens also use [sora] (headings/buttons) and [roboto] (body).
class AppText {
  const AppText._();

  static const String family = 'Nunito';
  static const String sora = 'Sora';
  static const String roboto = 'Roboto';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle timer = TextStyle(
    fontFamily: family,
    fontSize: 56,
    height: 60 / 56,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    fontFeatures: tabular,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: family,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMuted,
  );

  static const TextStyle numbers = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
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
