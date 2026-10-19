import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/focus/focus_clock.dart';

void main() {
  final start = DateTime.utc(2026, 10, 19, 2);

  test('elapsed time follows the server start and pauses while away', () {
    final clock = FocusClock(startedAt: start);
    expect(clock.elapsedSeconds(start.add(const Duration(seconds: 65))), 65);
    expect(clock.leave(start.add(const Duration(seconds: 65))), isTrue);
    expect(clock.elapsedSeconds(start.add(const Duration(seconds: 90))), 65);
  });

  test('returning within 30 seconds records an interruption', () {
    final clock = FocusClock(startedAt: start);
    clock.leave(start.add(const Duration(minutes: 1)));
    clock.returned(start.add(const Duration(minutes: 1, seconds: 30)));
    expect(clock.broken, isFalse);
    expect(clock.interruptions, hasLength(1));
    expect(clock.elapsedSeconds(start.add(const Duration(minutes: 2))), 90);
  });

  test('staying away longer than 30 seconds breaks the session', () {
    final clock = FocusClock(startedAt: start);
    clock.leave(start.add(const Duration(minutes: 1)));
    clock.returned(start.add(const Duration(minutes: 1, seconds: 31)));
    expect(clock.broken, isTrue);
    expect(clock.interruptions, isEmpty);
  });
}
