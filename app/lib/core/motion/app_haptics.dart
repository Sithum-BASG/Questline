import 'package:flutter/services.dart';

/// Light haptics only on Claim and chest open (UI brief §9).
class AppHaptics {
  const AppHaptics._();

  static Future<void> claim() => HapticFeedback.lightImpact();

  static Future<void> chestOpen() => HapticFeedback.lightImpact();
}
