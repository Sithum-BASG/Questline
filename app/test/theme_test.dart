import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_colors.dart';
import 'package:questline/core/theme/app_spacing.dart';
import 'package:questline/core/theme/app_text.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/theme/shadows.dart';

void main() {
  test('theme uses the brief tokens', () {
    final theme = AppTheme.light;
    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.colorScheme.primary, AppColors.tealDeep);
    expect(theme.colorScheme.error, AppColors.error);
    expect(theme.textTheme.bodyLarge?.fontFamily, AppText.family);
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
    expect(AppText.display.fontWeight, isNotNull);
    expect(AppSpacing.screen, 20);
    expect(AppRadius.card, 20);
    expect(AppColors.rarity('legendary'), AppColors.legendary);
    expect(AppColors.stat('vitality'), AppColors.vitality);
  });

  test('auth tokens keep Sora/Roboto and soft clay shadows', () {
    expect(AppText.authTitle.fontFamily, AppText.sora);
    expect(AppText.authSubtitle.fontFamily, AppText.roboto);
    expect(AppColors.authPage, const Color(0xFFF2F4F8));
    expect(AppShadows.claySoft, hasLength(2));
    expect(AppShadows.tealButton, hasLength(2));
  });
}
