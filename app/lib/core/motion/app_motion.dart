import 'package:flutter/widgets.dart';

/// Durations from UI brief §8, shortened when reduced motion is on.
class AppMotion {
  const AppMotion._();

  static bool reduce(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  static Duration standard(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 220);

  static Duration sheet(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 300);

  static Duration button(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 80);

  static Duration xpFill(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 600);

  static Duration bossDamage(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 400);

  static Duration raidTicker(BuildContext context) =>
      Duration(milliseconds: reduce(context) ? 150 : 200);
}
