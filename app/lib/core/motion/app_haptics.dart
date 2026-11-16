import 'package:flutter/services.dart';

/// Light haptics only on Claim and chest open (UI brief §9).
class AppHaptics {
  const AppHaptics._();

  static Future<void> claim() => _light();

  static Future<void> chestOpen() => _light();

  static Future<void> _light() async {
    try {
      await HapticFeedback.lightImpact();
    } on MissingPluginException {
      // Tests and hosts without a haptic channel.
    } catch (_) {}
  }
}
