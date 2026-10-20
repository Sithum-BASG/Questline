import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/game/level_curve.dart';

void main() {
  test('display curve matches server defaults for level 2', () {
    expect(LevelCurve.defaults.xpForLevel(2), 80);
    expect(LevelCurve.defaults.totalForLevel(2), 80);
    expect(LevelCurve.defaults.progressInLevel(40, 1), closeTo(0.5, 0.01));
  });
}
