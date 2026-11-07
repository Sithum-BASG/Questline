import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/notifications/notification_routes.dart';
import 'package:questline/features/inbox/inbox_copy.dart';

void main() {
  test('sanitizeNotificationRoute accepts in-app paths only', () {
    expect(sanitizeNotificationRoute('/bosses/b1'), '/bosses/b1');
    expect(sanitizeNotificationRoute('  /home  '), '/home');
    expect(sanitizeNotificationRoute('https://evil.example'), isNull);
    expect(sanitizeNotificationRoute('bosses'), isNull);
    expect(sanitizeNotificationRoute(''), isNull);
  });

  test('every inbox type deep-links to a known screen', () {
    final routes = {
      inboxRoute('guild_fight', {'raidId': 'r1'}),
      inboxRoute('raid_result', {'raidId': 'r1'}),
      inboxRoute('weekly_results', {'weekId': '2026-W41'}),
      inboxRoute('friend_request', {}),
      inboxRoute('boss_result', {'bossId': 'b1'}),
      inboxRoute('system', {}),
    };
    for (final route in routes) {
      expect(sanitizeNotificationRoute(route), route);
      expect(
        notificationRoutePrefixes.any((prefix) => route == prefix || route.startsWith(prefix)),
        true,
        reason: route,
      );
    }
  });
}
