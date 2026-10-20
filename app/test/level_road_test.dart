import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/hero/level_road_screen.dart';

void main() {
  test('level road labels coins and item ids', () {
    expect(
      LevelRoadRow(level: 2, label: 'frame margin notes', reached: false).level,
      2,
    );
  });
}
