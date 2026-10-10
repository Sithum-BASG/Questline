import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Light theme only. Game visuals stay on the stage card and reward moments.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.tealDeep,
      onPrimary: AppColors.white,
      secondary: AppColors.awakeningTeal,
      onSecondary: AppColors.ink,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: scheme,
      textTheme: const TextTheme(
        displayLarge: AppText.display,
        headlineLarge: AppText.h1,
        headlineMedium: AppText.h2,
        titleMedium: AppText.title,
        bodyLarge: AppText.body,
        bodyMedium: AppText.bodySmall,
        labelSmall: AppText.caption,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
