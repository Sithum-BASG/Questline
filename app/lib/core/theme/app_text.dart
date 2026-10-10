import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nunito text styles from the UI brief. Numbers use tabular figures.
class AppText {
  const AppText._();

  static const String family = 'Nunito';

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
}
