import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications.dart';
import 'notification_planner.dart';

/// Cancels planned locals and re-schedules from [planNotifications].
class NotificationScheduler {
  NotificationScheduler(this._notifications);

  final LocalNotifications _notifications;

  static const _plannerIdMin = 1000;

  Future<void> replan(PlannerInput input) async {
    await _notifications.init();
    final plugin = _notifications.plugin;
    final pending = await plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _plannerIdMin) {
        await plugin.cancel(id: request.id);
      }
    }

    final planned = planNotifications(input);
    for (final n in planned) {
      final id = n.id < _plannerIdMin ? n.id + _plannerIdMin : n.id;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          n.channelId,
          n.channelId,
          channelDescription: n.kind.name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(n.when, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: n.route,
      );
    }
  }
}
