import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/local_notifications.dart';
import '../../core/notifications/notification_channels.dart';

/// Shows the "come back" prompt when a focus session is backgrounded.
abstract class SessionAlerts {
  Future<void> showReturnPrompt({String? sessionId});

  Future<void> clearReturnPrompt();

  Future<void> showOngoing(String elapsed, {String? sessionId});

  Future<void> clearOngoing();
}

class LocalSessionAlerts implements SessionAlerts {
  LocalSessionAlerts(this._notifications);

  final LocalNotifications _notifications;

  static const _id = 30;
  static const _ongoingId = 31;

  FlutterLocalNotificationsPlugin get _plugin => _notifications.plugin;

  Future<void> _ensure() async {
    await _notifications.init();
  }

  @override
  Future<void> showReturnPrompt({String? sessionId}) async {
    await _ensure();
    const android = AndroidNotificationDetails(
      NotificationChannels.focus,
      'Focus',
      channelDescription: 'Asks you to return before a focus session breaks',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      id: _id,
      title: 'Return within 30 seconds',
      body: 'Come back to keep your session.',
      notificationDetails: const NotificationDetails(android: android, iOS: DarwinNotificationDetails()),
      payload: sessionId != null ? '/focus/$sessionId' : '/home',
    );
  }

  @override
  Future<void> clearReturnPrompt() {
    return _plugin.cancel(id: _id);
  }

  @override
  Future<void> showOngoing(String elapsed, {String? sessionId}) async {
    await _ensure();
    const android = AndroidNotificationDetails(
      NotificationChannels.focus,
      'Focus',
      channelDescription: 'Shows the session timer while you are away',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: false,
    );
    await _plugin.show(
      id: _ongoingId,
      title: 'Questline',
      body: elapsed,
      notificationDetails: const NotificationDetails(android: android, iOS: DarwinNotificationDetails()),
      payload: sessionId != null ? '/focus/$sessionId' : '/home',
    );
  }

  @override
  Future<void> clearOngoing() {
    return _plugin.cancel(id: _ongoingId);
  }
}

final sessionAlertsProvider = Provider<SessionAlerts>((ref) {
  return LocalSessionAlerts(ref.watch(localNotificationsProvider));
});
