import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remaining HP ratio clamps between 0 and 1', () {
    double remaining(int damage, int maxHp) {
      if (maxHp <= 0) return 0;
      return (1 - damage / maxHp).clamp(0.0, 1.0);
    }

    expect(remaining(0, 100), 1.0);
    expect(remaining(50, 100), 0.5);
    expect(remaining(100, 100), 0.0);
    expect(remaining(120, 100), 0.0);
  });
}
