import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/focus/presence_session.dart';

void main() {
  test('a session marks focusing and a heartbeat refreshes last seen', () {
    final writes = <Map<String, dynamic>>[];
    final presence = PresenceSession(appearOffline: false, onUpdate: writes.add);
    presence.begin(stat: 'intellect', startedAt: DateTime.utc(2026, 10, 19, 2));
    expect(writes.single['state'], 'focusing');
    presence.heartbeat(DateTime.utc(2026, 10, 19, 2, 1));
    expect(writes.last['last_seen'], '2026-10-19T02:01:00.000Z');
    presence.finish(DateTime.utc(2026, 10, 19, 2, 2));
    expect(writes.last['state'], 'idle');
  });

  test('appear offline never writes focusing', () {
    final writes = <Map<String, dynamic>>[];
    final presence = PresenceSession(appearOffline: true, onUpdate: writes.add);
    presence.begin(stat: 'intellect', startedAt: DateTime.utc(2026, 10, 19));
    presence.finish(DateTime.utc(2026, 10, 19, 1));
    expect(writes, isEmpty);
  });
}
