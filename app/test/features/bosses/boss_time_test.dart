import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/bosses/boss_time.dart';

void main() {
  test('bossTimeLeft formats days hours and overdue', () {
    final now = DateTime.utc(2026, 10, 10, 12);
    expect(bossTimeLeft(now.subtract(const Duration(hours: 1)), now), 'Overdue');
    expect(bossTimeLeft(now.add(const Duration(days: 2)), now), '2d left');
    expect(bossTimeLeft(now.add(const Duration(hours: 5)), now), '5h left');
  });
}
