import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/shadows.dart';

/// Soft clay fill used on the arch, nameplate and Google button.
const LinearGradient authClayGradient = LinearGradient(
  begin: Alignment(-0.6, -0.8),
  end: Alignment(0.7, 0.9),
  colors: [AppColors.white, Color(0xFFF5F7FA)],
);

/// Approximate 145° gradient for soft clay / teal buttons.
const LinearGradient authTealButtonGradient = LinearGradient(
  begin: Alignment(-0.6, -0.8),
  end: Alignment(0.7, 0.9),
  colors: [AppColors.tealButtonStart, AppColors.tealButtonEnd],
);

BoxDecoration authClayDecoration({
  required BorderRadius borderRadius,
  List<BoxShadow> shadows = AppShadows.claySoft,
}) {
  return BoxDecoration(
    gradient: authClayGradient,
    borderRadius: borderRadius,
    boxShadow: shadows,
  );
}
