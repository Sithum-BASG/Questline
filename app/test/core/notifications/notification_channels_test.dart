import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/notifications/notification_channels.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('Android channels cover every planned category', () {
    expect(
      NotificationChannels.all.toSet(),
      {
        NotificationChannels.focus,
        NotificationChannels.bosses,
        NotificationChannels.streak,
        NotificationChannels.raids,
        NotificationChannels.weekly,
        NotificationChannels.comeback,
      },
    );
    for (final id in NotificationChannels.all) {
      expect(NotificationChannels.titleFor(id), isNotEmpty);
      expect(NotificationChannels.descriptionFor(id), isNotEmpty);
    }
  });

  test('timezone database loads for local scheduling', () {
    tz_data.initializeTimeZones();
    final colombo = tz.getLocation('Asia/Colombo');
    final now = tz.TZDateTime.now(colombo);
    expect(now.location.name, 'Asia/Colombo');
  });
}
