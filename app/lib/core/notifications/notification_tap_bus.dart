import 'package:flutter/foundation.dart';

/// Carries notification tap payloads from the plugin into the widget tree.
final ValueNotifier<String?> notificationTapBus = ValueNotifier<String?>(null);

void publishNotificationTap(String? payload) {
  if (payload == null || payload.trim().isEmpty) return;
  notificationTapBus.value = payload.trim();
}
