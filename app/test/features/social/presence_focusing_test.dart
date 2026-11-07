import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/presence.dart';
import 'package:questline/features/social/providers/presence_providers.dart';

void main() {
  test('isFocusingNow requires focusing state within 2 minutes', () {
    final now = DateTime.utc(2026, 10, 10, 12);
    final fresh = Presence(
      userId: 'u1',
      state: 'focusing',
      lastSeen: now.subtract(const Duration(seconds: 30)),
    );
    final stale = Presence(
      userId: 'u1',
      state: 'focusing',
      lastSeen: now.subtract(const Duration(seconds: 121)),
    );
    final idle = Presence(
      userId: 'u1',
      state: 'idle',
      lastSeen: now,
    );
    expect(isFocusingNow(fresh, now), true);
    expect(isFocusingNow(stale, now), false);
    expect(isFocusingNow(idle, now), false);
  });
}
