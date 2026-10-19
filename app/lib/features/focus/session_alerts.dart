import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the "come back" prompt when a focus session is backgrounded.
abstract class SessionAlerts {
  Future<void> showReturnPrompt();

  Future<void> clearReturnPrompt();
}

class LocalSessionAlerts implements SessionAlerts {
  LocalSessionAlerts({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;

  static const _id = 30;

  Future<void> _ensure() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(settings: const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> showReturnPrompt() async {
    await _ensure();
    const android = AndroidNotificationDetails(
      'focus_return',
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
    );
  }

  @override
  Future<void> clearReturnPrompt() {
    return _plugin.cancel(id: _id);
  }
}

final sessionAlertsProvider = Provider<SessionAlerts>((ref) => LocalSessionAlerts());
