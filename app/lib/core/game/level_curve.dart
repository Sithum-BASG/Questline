import 'dart:math' as math;

/// Display-only level curve (mirrors server defaults). Never used to award XP.
class LevelCurve {
  const LevelCurve({
    this.base = 80,
    this.coef = 5.5,
    this.exp = 1.4,
    this.roundTo = 10,
    this.maxLevel = 50,
  });

  final double base;
  final double coef;
  final double exp;
  final int roundTo;
  final int maxLevel;

  static const defaults = LevelCurve();

  int xpForLevel(int level) {
    if (level < 2) return 0;
    final raw = base + coef * math.pow(level - 2, exp);
    return ((raw / roundTo).round()) * roundTo;
  }

  int totalForLevel(int level) {
    var total = 0;
    final cap = level < maxLevel ? level : maxLevel;
    for (var next = 2; next <= cap; next++) {
      total += xpForLevel(next);
    }
    return total;
  }

  /// Progress 0–1 within the current level toward the next.
  double progressInLevel(int xpTotal, int level) {
    if (level >= maxLevel) return 1;
    final floor = totalForLevel(level);
    final span = xpForLevel(level + 1);
    if (span <= 0) return 1;
    return ((xpTotal - floor) / span).clamp(0.0, 1.0);
  }
}
