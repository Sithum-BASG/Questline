import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_channels.dart';
import 'notification_tap_bus.dart';

const _permissionAskedKey = 'notif_permission_asked';

/// Wraps `flutter_local_notifications`: Android channels and one-shot permission.
class LocalNotifications {
  LocalNotifications(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;

  bool get isReady => _ready;

  Future<void> init({void Function(NotificationResponse response)? onTap}) async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        publishNotificationTap(response.payload);
        onTap?.call(response);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      publishNotificationTap(launch!.notificationResponse?.payload);
    }
    await _ensureAndroidChannels();
    _ready = true;
  }

  Future<void> _ensureAndroidChannels() async {
    if (kIsWeb) return;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final id in NotificationChannels.all) {
      final importance = id == NotificationChannels.focus ? Importance.high : Importance.defaultImportance;
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          NotificationChannels.titleFor(id),
          description: NotificationChannels.descriptionFor(id),
          importance: importance,
        ),
      );
    }
  }

  /// Returns true if the OS says notifications are allowed.
  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  /// Asks once after the first focus session (Android 13+ / iOS).
  Future<bool> requestPermissionAfterFirstSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionAskedKey) == true) {
      return areNotificationsEnabled();
    }
    await prefs.setBool(_permissionAskedKey, true);

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
    } catch (_) {
      // Platform interface unset in widget tests / unsupported hosts.
    }
    return false;
  }

  FlutterLocalNotificationsPlugin get plugin => _plugin;
}

final localNotificationsProvider = Provider<LocalNotifications>((ref) {
  return LocalNotifications(FlutterLocalNotificationsPlugin());
});
