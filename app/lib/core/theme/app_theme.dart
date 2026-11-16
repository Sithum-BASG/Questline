import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Light theme only. Clay surfaces on a soft grey page; game visuals stay on
/// the stage card and reward moments.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.tealDeep,
      onPrimary: AppColors.white,
      secondary: AppColors.awakeningTeal,
      onSecondary: AppColors.ink,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerHighest: AppColors.well,
      outline: AppColors.handle,
      outlineVariant: AppColors.hairline,
      error: AppColors.error,
      onError: AppColors.white,
    );
    final fieldRadius = BorderRadius.circular(AppRadius.field);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      colorScheme: scheme,
      textTheme: const TextTheme(
        displayLarge: AppText.display,
        headlineLarge: AppText.h1,
        headlineMedium: AppText.h2,
        titleLarge: AppText.h2,
        titleMedium: AppText.title,
        bodyLarge: AppText.body,
        bodyMedium: AppText.bodySmall,
        labelLarge: AppText.title,
        labelSmall: AppText.caption,
      ),
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.encounter.copyWith(letterSpacing: -0.17),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.well,
        hintStyle: AppText.body.copyWith(color: AppColors.placeholder, fontSize: 15),
        labelStyle: AppText.caption,
        floatingLabelStyle: AppText.caption.copyWith(color: AppColors.tealDeep),
        helperStyle: AppText.caption,
        errorStyle: AppText.caption.copyWith(color: AppColors.errorText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.awakeningTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.authErrorOutline, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.authErrorOutline, width: 2),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.tealDeep,
        selectionHandleColor: AppColors.tealDeep,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.tealDeep : AppColors.handle,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.awakeningTeal,
        inactiveTrackColor: AppColors.well,
        thumbColor: AppColors.tealDeep,
        overlayColor: Color(0x1F0F766E),
        trackHeight: 8,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.tealDeep : AppColors.white,
        ),
        side: const BorderSide(color: AppColors.handle, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(AppColors.tealDeep)),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppText.title.copyWith(fontSize: 15),
        subtitleTextStyle: AppText.caption,
        iconColor: AppColors.inkMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        minVerticalPadding: 12,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tealDeep,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
          textStyle: AppText.title.copyWith(fontSize: 15),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.white,
          minimumSize: const Size(AppSpacing.minTap, 52),
          side: const BorderSide(color: AppColors.hairline),
          textStyle: AppText.title.copyWith(fontSize: 15),
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        elevation: 12,
        shadowColor: const Color(0x38101935),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.stage)),
        titleTextStyle: AppText.h2.copyWith(fontSize: 20, height: 26 / 20),
        contentTextStyle: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        dragHandleColor: AppColors.handle,
        dragHandleSize: Size(40, 5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body.copyWith(color: AppColors.white, fontSize: 14, height: 20 / 14),
        actionTextColor: AppColors.tealLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 104),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.tealDeep,
        linearTrackColor: AppColors.well,
        circularTrackColor: AppColors.well,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.well,
          foregroundColor: AppColors.inkMuted,
          selectedBackgroundColor: AppColors.tealDeep,
          selectedForegroundColor: AppColors.white,
          side: BorderSide.none,
          textStyle: AppText.title.copyWith(fontSize: 14),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.tealDeep,
        labelStyle: AppText.title.copyWith(fontSize: 14),
        secondaryLabelStyle: AppText.title.copyWith(fontSize: 14, color: AppColors.white),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.error, textColor: AppColors.white),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
        textStyle: AppText.caption.copyWith(color: AppColors.white),
      ),
    );
  }
}
